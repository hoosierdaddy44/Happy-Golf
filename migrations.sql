-- Happy Golf — Supabase Schema Migration
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor → New Query)

-- ────────────────────────────────────────────────────────────────────────────
-- 1. Profiles
-- ────────────────────────────────────────────────────────────────────────────

create table if not exists profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  name            text        not null,
  handicap_index  numeric(4,1) default 0,
  industry        text        default '',
  home_courses    text[]      default '{}',
  pace_preference text        not null default 'standard'
                              check (pace_preference in ('fast','standard','chill')),
  member_since    timestamptz not null default now(),
  rounds_played   int         not null default 0,
  rating          numeric(3,2),
  rating_count    int         not null default 0,
  avatar_url      text,
  updated_at      timestamptz not null default now()
);

alter table profiles enable row level security;

create policy "Public profiles readable"
  on profiles for select using (true);

create policy "Users update own profile"
  on profiles for update using (auth.uid() = id);

create policy "Users insert own profile"
  on profiles for insert with check (auth.uid() = id);

-- ────────────────────────────────────────────────────────────────────────────
-- 2. Tee Times
-- ────────────────────────────────────────────────────────────────────────────

create table if not exists tee_times (
  id          uuid primary key default gen_random_uuid(),
  host_id     uuid not null references profiles(id) on delete cascade,
  course_name text not null,
  location    text,
  tee_date    date not null,
  tee_time    time not null,
  open_spots  int  not null default 3 check (open_spots >= 0),
  carry_mode  text not null default 'walking'
              check (carry_mode in ('walking','riding')),
  notes       text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

alter table tee_times enable row level security;

create policy "Tee times readable by all"
  on tee_times for select using (true);

create policy "Host can insert"
  on tee_times for insert with check (auth.uid() = host_id);

create policy "Host can update"
  on tee_times for update using (auth.uid() = host_id);

create policy "Host can delete"
  on tee_times for delete using (auth.uid() = host_id);

-- ────────────────────────────────────────────────────────────────────────────
-- 3. Join Requests
-- ────────────────────────────────────────────────────────────────────────────

create table if not exists join_requests (
  id           uuid primary key default gen_random_uuid(),
  tee_time_id  uuid not null references tee_times(id) on delete cascade,
  requester_id uuid not null references profiles(id) on delete cascade,
  status       text not null default 'pending'
               check (status in ('pending','approved','declined')),
  note         text,
  created_at   timestamptz not null default now(),
  unique (tee_time_id, requester_id)
);

alter table join_requests enable row level security;

create policy "Requester sees own requests"
  on join_requests for select
  using (auth.uid() = requester_id
      or auth.uid() in (select host_id from tee_times where id = tee_time_id));

create policy "Requester can insert"
  on join_requests for insert with check (auth.uid() = requester_id);

create policy "Host can update status"
  on join_requests for update
  using (auth.uid() in (select host_id from tee_times where id = tee_time_id));

-- ────────────────────────────────────────────────────────────────────────────
-- 4. Round Ratings
-- ────────────────────────────────────────────────────────────────────────────

create table if not exists round_ratings (
  id          uuid primary key default gen_random_uuid(),
  tee_time_id uuid not null references tee_times(id) on delete cascade,
  rater_id    uuid not null references profiles(id) on delete cascade,
  ratee_id    uuid not null references profiles(id) on delete cascade,
  score       int  not null check (score between 1 and 5),
  created_at  timestamptz not null default now(),
  unique (tee_time_id, rater_id, ratee_id)
);

alter table round_ratings enable row level security;

create policy "Players can insert ratings"
  on round_ratings for insert with check (auth.uid() = rater_id);

create policy "Ratings visible to participants"
  on round_ratings for select
  using (auth.uid() = rater_id or auth.uid() = ratee_id);

-- Trigger: update profiles.rating + rating_count on insert
create or replace function update_player_rating()
returns trigger language plpgsql security definer as $$
begin
  update profiles
  set
    rating = (
      select round(avg(score)::numeric, 2)
      from round_ratings
      where ratee_id = new.ratee_id
    ),
    rating_count = (
      select count(*) from round_ratings where ratee_id = new.ratee_id
    )
  where id = new.ratee_id;
  return new;
end;
$$;

create trigger on_rating_insert
  after insert on round_ratings
  for each row execute function update_player_rating();

-- ────────────────────────────────────────────────────────────────────────────
-- 5. Accolades
-- ────────────────────────────────────────────────────────────────────────────

create table if not exists accolades (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references profiles(id) on delete cascade,
  type        text not null
              check (type in ('eagle','birdie_machine','broke_80','broke_70','hole_in_one','personal_best')),
  tee_time_id uuid references tee_times(id) on delete set null,
  created_at  timestamptz not null default now()
);

alter table accolades enable row level security;

create policy "Accolades readable by all"
  on accolades for select using (true);

create policy "Users insert own accolades"
  on accolades for insert with check (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────────────────────────
-- 6. Accolade Verifications
-- ────────────────────────────────────────────────────────────────────────────

create table if not exists accolade_verifications (
  id          uuid primary key default gen_random_uuid(),
  accolade_id uuid not null references accolades(id) on delete cascade,
  verifier_id uuid not null references profiles(id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (accolade_id, verifier_id)
);

alter table accolade_verifications enable row level security;

create policy "Verifications readable by all"
  on accolade_verifications for select using (true);

create policy "Users can verify"
  on accolade_verifications for insert
  with check (auth.uid() = verifier_id
    and auth.uid() != (select user_id from accolades where id = accolade_id));

-- ────────────────────────────────────────────────────────────────────────────
-- 7. Activity Events
-- ────────────────────────────────────────────────────────────────────────────

create table if not exists activity_events (
  id          uuid primary key default gen_random_uuid(),
  type        text not null
              check (type in ('new_tee_time','request_sent','approved','declined')),
  actor_id    uuid not null references profiles(id) on delete cascade,
  tee_time_id uuid references tee_times(id) on delete cascade,
  created_at  timestamptz not null default now()
);

alter table activity_events enable row level security;

create policy "Activity readable by all"
  on activity_events for select using (true);

create policy "Actors insert own events"
  on activity_events for insert with check (auth.uid() = actor_id);

-- ────────────────────────────────────────────────────────────────────────────
-- 8. Friendships
-- ────────────────────────────────────────────────────────────────────────────

create table if not exists friendships (
  id           uuid primary key default gen_random_uuid(),
  requester_id uuid not null references profiles(id) on delete cascade,
  addressee_id uuid not null references profiles(id) on delete cascade,
  status       text not null default 'pending'
               check (status in ('pending','accepted','declined')),
  created_at   timestamptz not null default now(),
  unique (requester_id, addressee_id)
);

alter table friendships enable row level security;

create policy "Users see own friendships"
  on friendships for select
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "Users send friend requests"
  on friendships for insert with check (auth.uid() = requester_id);

create policy "Addressee can update status"
  on friendships for update
  using (auth.uid() = addressee_id or auth.uid() = requester_id);

create policy "Either party can delete"
  on friendships for delete
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

-- ────────────────────────────────────────────────────────────────────────────
-- 9. Avatar Storage Bucket
-- ────────────────────────────────────────────────────────────────────────────

-- Run this separately in the Supabase Storage UI or via the API:
-- Create a public bucket named "avatars" with 2MB file size limit.
-- Then apply these storage policies:

-- insert policy: auth.uid()::text = (storage.foldername(name))[1]
-- select policy: true (public)
-- delete policy: auth.uid()::text = (storage.foldername(name))[1]
