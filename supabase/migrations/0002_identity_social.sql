-- BigBack · 0002 · schools, profiles, follows, blocks, crews, sign-up gate

-- ---------------------------------------------------------------------------
-- Schools (launch: University of Waterloo). A school gates sign-up by email domain
-- and scopes campus leaderboards / campus scores.
-- ---------------------------------------------------------------------------
create table public.schools (
  id            uuid primary key default gen_random_uuid(),
  slug          text not null unique check (slug ~ '^[a-z0-9-]{2,40}$'),
  name          text not null,
  short_name    text not null,
  email_domains text[] not null default '{}',
  city          text not null,
  timezone      text not null default 'America/Toronto',
  center        extensions.geography(point, 4326),
  is_live       boolean not null default false,  -- false = waitlist only
  created_at    timestamptz not null default now()
);
comment on table public.schools is 'Campuses. Sign-up is limited to email_domains of live schools.';

-- ---------------------------------------------------------------------------
-- Profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id                 uuid primary key references auth.users (id) on delete cascade,
  handle             extensions.citext not null unique
                       check (handle ~ '^[a-zA-Z0-9_.]{3,24}$'),
  display_name       text not null check (char_length(display_name) between 1 and 50),
  avatar_path        text,
  bio                text check (char_length(bio) <= 160),
  school_id          uuid references public.schools (id) on delete set null,
  is_private         boolean not null default false,
  notification_prefs jsonb not null default '{}'::jsonb,
  onboarded_at       timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
comment on table public.profiles is 'Public profile for each user. is_private = only accepted followers see meals/rankings.';
create index profiles_school_idx on public.profiles (school_id);
create index profiles_handle_trgm_idx on public.profiles using gin ((handle::text) extensions.gin_trgm_ops);
create index profiles_name_trgm_idx on public.profiles using gin (display_name extensions.gin_trgm_ops);
create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Follows (directed). Private profiles turn new follows into requests.
-- ---------------------------------------------------------------------------
create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  followee_id uuid not null references public.profiles (id) on delete cascade,
  status      public.follow_status not null default 'accepted',
  created_at  timestamptz not null default now(),
  accepted_at timestamptz,
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);
create index follows_followee_idx on public.follows (followee_id, status);

-- ---------------------------------------------------------------------------
-- Blocks (either direction hides everything between the two users)
-- ---------------------------------------------------------------------------
create table public.blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index blocks_blocked_idx on public.blocks (blocked_id);

-- ---------------------------------------------------------------------------
-- Crews: saved friend groups (roommates, co-op team, club)
-- ---------------------------------------------------------------------------
create table public.crews (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(name) between 1 and 40),
  owner_id   uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index crews_owner_idx on public.crews (owner_id);
create trigger crews_updated_at before update on public.crews
  for each row execute function public.set_updated_at();

create table public.crew_members (
  crew_id   uuid not null references public.crews (id) on delete cascade,
  user_id   uuid not null references public.profiles (id) on delete cascade,
  role      text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (crew_id, user_id)
);
create index crew_members_user_idx on public.crew_members (user_id);

-- ---------------------------------------------------------------------------
-- New auth user -> profile (handle derived from email, school from domain)
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_local  text := split_part(coalesce(new.email, ''), '@', 1);
  v_domain text := lower(split_part(coalesce(new.email, ''), '@', 2));
  v_base   text;
  v_handle text;
  v_school uuid;
begin
  v_base := left(regexp_replace(lower(v_local), '[^a-z0-9_.]', '', 'g'), 18);
  if char_length(v_base) < 3 then
    v_base := 'eater';
  end if;
  v_handle := v_base;
  -- de-duplicate: append 4 random digits until free
  while exists (select 1 from public.profiles p where p.handle = v_handle::extensions.citext) loop
    v_handle := v_base || lpad((floor(random() * 10000))::int::text, 4, '0');
  end loop;

  select s.id into v_school
  from public.schools s
  where v_domain = any (s.email_domains)
     or exists (select 1 from unnest(s.email_domains) d where v_domain like '%.' || d)
  limit 1;

  insert into public.profiles (id, handle, display_name, school_id)
  values (
    new.id,
    v_handle,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), initcap(replace(v_local, '.', ' ')), 'New eater'),
    v_school
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Auth hook: before-user-created. Only emails from a live school may sign up.
-- Enable in Dashboard → Authentication → Hooks → "Before User Created" →
-- Postgres function public.hook_before_user_created.
-- ---------------------------------------------------------------------------
create or replace function public.hook_before_user_created(event jsonb)
returns jsonb
language plpgsql
stable
set search_path = ''
as $$
declare
  v_domain text := lower(split_part(coalesce(event -> 'user' ->> 'email', ''), '@', 2));
begin
  if exists (
    select 1 from public.schools s
    where s.is_live
      and (v_domain = any (s.email_domains)
           or exists (select 1 from unnest(s.email_domains) d where v_domain like '%.' || d))
  ) then
    return '{}'::jsonb;
  end if;
  return jsonb_build_object('error', jsonb_build_object(
    'http_code', 403,
    'message', 'BigBack is campus-only right now. Sign up with your school email (e.g. @uwaterloo.ca).'
  ));
end;
$$;

grant usage on schema public to supabase_auth_admin;
grant execute on function public.hook_before_user_created(jsonb) to supabase_auth_admin;
grant select on public.schools to supabase_auth_admin;
revoke execute on function public.hook_before_user_created(jsonb) from authenticated, anon, public;
