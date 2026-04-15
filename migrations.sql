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
-- 9. Membership Requests
-- Captures every signup automatically via trigger — works for both
-- Sign in with Apple (including relay emails) and email magic link.
-- Admin approves members by setting status = 'approved' in the dashboard.
-- ────────────────────────────────────────────────────────────────────────────

create table if not exists membership_requests (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null unique references auth.users(id) on delete cascade,
  email          text,                        -- may be Apple relay address
  name           text,                        -- filled in after profile setup
  username       text,                        -- unique — filled in after profile setup
  auth_provider  text,                        -- 'apple' | 'email' | etc.
  status         text not null default 'pending'
                 check (status in ('pending','approved','declined')),
  applied_at     timestamptz not null default now(),
  reviewed_at    timestamptz
);

alter table membership_requests enable row level security;

-- Users can read their own row (to check approval status)
create policy "Users read own membership request"
  on membership_requests for select using (auth.uid() = user_id);

-- Users can update their own row (to fill in name after profile setup)
create policy "Users update own membership request"
  on membership_requests for update using (auth.uid() = user_id);

-- Trigger: auto-create a membership_requests row on every new auth.users signup
create or replace function handle_new_user_membership()
returns trigger language plpgsql security definer as $$
begin
  insert into public.membership_requests (user_id, email, auth_provider)
  values (
    new.id,
    new.email,
    new.raw_app_meta_data->>'provider'
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_membership on auth.users;
create trigger on_auth_user_created_membership
  after insert on auth.users
  for each row execute function handle_new_user_membership();

-- ────────────────────────────────────────────────────────────────────────────
-- 10. Avatar Storage Bucket
-- ────────────────────────────────────────────────────────────────────────────

-- Run this separately in the Supabase Storage UI or via the API:
-- Create a public bucket named "avatars" with 2MB file size limit.
-- Then apply these storage policies:

-- insert policy: auth.uid()::text = (storage.foldername(name))[1]
-- select policy: true (public)
-- delete policy: auth.uid()::text = (storage.foldername(name))[1]

-- ────────────────────────────────────────────────────────────────────────────
-- 11. Groups
-- ────────────────────────────────────────────────────────────────────────────

create table if not exists groups (
  id          uuid primary key default gen_random_uuid(),
  name        text        not null,
  description text        not null default '',
  emoji       text        not null default '⛳',
  created_by  uuid        not null references profiles(id) on delete cascade,
  is_private  boolean     not null default false,
  created_at  timestamptz not null default now()
);

alter table groups enable row level security;

create policy "Groups readable by all"
  on groups for select using (true);

create policy "Members can insert groups"
  on groups for insert with check (auth.uid() = created_by);

create policy "Admin can update group"
  on groups for update
  using (auth.uid() in (
    select user_id from group_members
    where group_id = id and role = 'admin'
  ));

-- ────────────────────────────────────────────────────────────────────────────
-- 12. Group Members
-- ────────────────────────────────────────────────────────────────────────────

create table if not exists group_members (
  id         uuid primary key default gen_random_uuid(),
  group_id   uuid not null references groups(id) on delete cascade,
  user_id    uuid not null references profiles(id) on delete cascade,
  role       text not null default 'member'
             check (role in ('admin','member')),
  joined_at  timestamptz not null default now(),
  unique (group_id, user_id)
);

alter table group_members enable row level security;

create policy "Group members readable by all"
  on group_members for select using (true);

create policy "Members can join public groups"
  on group_members for insert
  with check (
    auth.uid() = user_id
    and (
      select not is_private from groups where id = group_id
    )
  );

create policy "Admins can add members"
  on group_members for insert
  with check (
    auth.uid() in (
      select user_id from group_members
      where group_id = group_id and role = 'admin'
    )
  );

create policy "Members can leave"
  on group_members for delete
  using (auth.uid() = user_id);

-- Add group_id to tee_times
alter table tee_times add column if not exists group_id uuid references groups(id) on delete set null;

-- ────────────────────────────────────────────────────────────────────────────
-- 13. Round Format on Tee Times
-- ────────────────────────────────────────────────────────────────────────────

alter table tee_times add column if not exists format text not null default 'stroke_play'
  check (format in ('stroke_play','match_play','skins','scramble','best_ball'));

-- ────────────────────────────────────────────────────────────────────────────
-- 14. Score Verifications
-- ────────────────────────────────────────────────────────────────────────────

create table if not exists score_verifications (
  id           uuid primary key default gen_random_uuid(),
  tee_time_id  uuid not null references tee_times(id) on delete cascade,
  player_id    uuid not null references profiles(id) on delete cascade,
  verifier_id  uuid not null references profiles(id) on delete cascade,
  created_at   timestamptz not null default now(),
  unique (tee_time_id, player_id, verifier_id)
);

alter table score_verifications enable row level security;

create policy "Score verifications readable by all"
  on score_verifications for select using (true);

create policy "Players can verify others scores"
  on score_verifications for insert
  with check (auth.uid() = verifier_id and auth.uid() != player_id);
