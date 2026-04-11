-- Happy Golf — Supabase Schema

-- Users (extends Supabase auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  name text not null,
  handicap_index numeric(4,1),
  industry text,
  home_courses text[] default '{}',
  pace_preference text check (pace_preference in ('fast', 'standard', 'chill')) default 'standard',
  member_since timestamptz default now(),
  rounds_played int default 0,
  created_at timestamptz default now()
);

-- Tee times
create table public.tee_times (
  id uuid primary key default gen_random_uuid(),
  host_id uuid references public.profiles(id) on delete cascade not null,
  course_name text not null,
  location text,
  tee_date date not null,
  tee_time time not null,
  open_spots int not null default 2 check (open_spots between 1 and 3),
  carry_mode text check (carry_mode in ('walking', 'riding')) default 'walking',
  notes text,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- Join requests
create table public.join_requests (
  id uuid primary key default gen_random_uuid(),
  tee_time_id uuid references public.tee_times(id) on delete cascade not null,
  requester_id uuid references public.profiles(id) on delete cascade not null,
  status text check (status in ('pending', 'approved', 'declined')) default 'pending',
  created_at timestamptz default now(),
  unique(tee_time_id, requester_id)
);

-- Activity events
create table public.activity_events (
  id uuid primary key default gen_random_uuid(),
  type text check (type in ('new_tee_time', 'request_approved', 'request_declined', 'player_joined')) not null,
  actor_id uuid references public.profiles(id) on delete cascade not null,
  tee_time_id uuid references public.tee_times(id) on delete cascade,
  created_at timestamptz default now()
);

-- RLS policies
alter table public.profiles enable row level security;
alter table public.tee_times enable row level security;
alter table public.join_requests enable row level security;
alter table public.activity_events enable row level security;

-- Profiles: anyone can read, only owner can write
create policy "Public profiles are viewable by all" on public.profiles for select using (true);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

-- Tee times: anyone can read active ones, host can write
create policy "Active tee times are viewable by all" on public.tee_times for select using (is_active = true);
create policy "Hosts can insert tee times" on public.tee_times for insert with check (auth.uid() = host_id);
create policy "Hosts can update own tee times" on public.tee_times for update using (auth.uid() = host_id);

-- Join requests: requester and host can see
create policy "Requesters can view own requests" on public.join_requests for select using (auth.uid() = requester_id);
create policy "Hosts can view requests for their tee times" on public.join_requests for select using (
  auth.uid() in (select host_id from public.tee_times where id = tee_time_id)
);
create policy "Users can create join requests" on public.join_requests for insert with check (auth.uid() = requester_id);
create policy "Hosts can update request status" on public.join_requests for update using (
  auth.uid() in (select host_id from public.tee_times where id = tee_time_id)
);

-- Activity: all authenticated users can read
create policy "Authenticated users can view activity" on public.activity_events for select using (auth.role() = 'authenticated');

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', 'New Member'));
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
