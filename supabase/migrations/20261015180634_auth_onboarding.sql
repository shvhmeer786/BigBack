-- BigBack · Sign-up and onboarding support.
-- Sign-up and log-in are the same email-code flow (Supabase Auth: signInWithOTP → verifyOTP). New users then
-- pick a name and handle and accept the terms (App Review guideline 1.2: users of a UGC app must agree to terms
-- that forbid objectionable content). These columns are set only through the RPCs below.

alter table public.profiles
  add column if not exists terms_accepted_at timestamptz,
  add column if not exists terms_version     text;

-- Clients can't edit system-owned profile fields directly.
create or replace function public._guard_profiles()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if public._is_client() then
    new.school_id         := old.school_id;
    new.created_at        := old.created_at;
    new.is_demo           := old.is_demo;
    new.onboarded_at      := old.onboarded_at;
    new.terms_accepted_at := old.terms_accepted_at;
    new.terms_version     := old.terms_version;
  end if;
  return new;
end;
$$;

-- Live check while the user types a handle. Handles are public, so this reveals nothing new.
create or replace function public.is_handle_available(p_handle text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(p_handle, '') ~ '^[a-zA-Z0-9_.]{3,24}$'
     and lower(p_handle) not in (
       'bigback', 'admin', 'administrator', 'support', 'help', 'official', 'team', 'staff', 'mod',
       'moderator', 'security', 'uwaterloo', 'waterloo', 'root', 'system', 'null', 'undefined',
       'me', 'you', 'settings', 'about', 'privacy', 'terms', 'login', 'signup')
     and not exists (
       select 1 from public.profiles p
       where p.handle = p_handle::extensions.citext and p.id is distinct from (select auth.uid()));
$$;

-- Last onboarding step: name, handle and terms in one call.
create or replace function public.complete_onboarding(p_display_name text, p_handle text, p_terms_version text)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_row public.profiles;
begin
  if v_uid is null then raise exception 'not authenticated'; end if;
  if nullif(trim(p_terms_version), '') is null then raise exception 'terms must be accepted'; end if;
  if char_length(trim(coalesce(p_display_name, ''))) not between 1 and 50 then
    raise exception 'name must be 1 to 50 characters';
  end if;
  if not public.is_handle_available(p_handle) then raise exception 'handle unavailable'; end if;

  update public.profiles
  set display_name      = trim(p_display_name),
      handle            = p_handle,
      terms_accepted_at = now(),
      terms_version     = trim(p_terms_version),
      onboarded_at      = coalesce(onboarded_at, now()),
      updated_at        = now()
  where id = v_uid
  returning * into v_row;
  return v_row;
end;
$$;

-- When the terms change, existing users accept the new version on next launch.
create or replace function public.accept_terms(p_terms_version text)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.profiles
  set terms_accepted_at = now(), terms_version = trim(p_terms_version), updated_at = now()
  where id = (select auth.uid()) and nullif(trim(p_terms_version), '') is not null;
$$;

revoke execute on function public.is_handle_available(text) from public, anon;
revoke execute on function public.complete_onboarding(text, text, text) from public, anon;
revoke execute on function public.accept_terms(text) from public, anon;
grant execute on function public.is_handle_available(text) to authenticated;
grant execute on function public.complete_onboarding(text, text, text) to authenticated;
grant execute on function public.accept_terms(text) to authenticated;
