-- BigBack · 0001 · extensions, enum types, utility functions
-- Design doc: docs/architecture/02-database-design.md

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists postgis  with schema extensions;  -- geography, ST_DWithin
create extension if not exists pg_trgm  with schema extensions;  -- fuzzy place / dish search
create extension if not exists citext   with schema extensions;  -- case-insensitive handles
create extension if not exists unaccent with schema extensions;  -- "Café" == "cafe" in search keys
create extension if not exists pg_net   with schema extensions;  -- DB -> Edge Function webhooks (push)
create extension if not exists pg_cron  with schema pg_catalog;  -- scheduled jobs

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type public.tier as enum ('loved', 'good', 'mid', 'nah');
create type public.vibe as enum ('cheap_eats', 'sit_down', 'date_night', 'late_night', 'cafe', 'dessert', 'drinks');
create type public.meal_status as enum ('live', 'unrated', 'posted', 'archived');
create type public.meal_visibility as enum ('followers', 'only_me');
create type public.moment as enum ('walk_in', 'order', 'food', 'crew', 'damage_report', 'other');
create type public.media_kind as enum ('dual', 'single', 'clip');
create type public.follow_status as enum ('accepted', 'requested');
create type public.member_status as enum ('pending', 'accepted', 'declined');
create type public.rsvp as enum ('invited', 'going', 'maybe', 'cant');
create type public.plan_status as enum ('planned', 'cancelled', 'done');
create type public.decide_status as enum ('open', 'matched', 'closed');
create type public.reservation_provider as enum ('opentable', 'resy', 'tock', 'website', 'phone', 'walk_in', 'unknown');
create type public.reservation_status as enum ('none', 'link_opened', 'confirmed', 'cancelled');
create type public.comparison_source as enum ('rate', 'settle', 'defend', 'fight', 'reorder');
create type public.place_source as enum ('fsq', 'overture', 'osm', 'user', 'admin');
create type public.edit_status as enum ('pending', 'approved', 'rejected');
create type public.report_status as enum ('open', 'actioned', 'dismissed');

-- ---------------------------------------------------------------------------
-- Utilities
-- ---------------------------------------------------------------------------

-- Keeps updated_at fresh on any table that has it.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- Safe uuid cast (returns null instead of raising) — used by storage policies on object paths.
create or replace function public.try_uuid(p text)
returns uuid
language plpgsql
immutable
set search_path = ''
as $$
begin
  return p::uuid;
exception when others then
  return null;
end;
$$;

-- Normalised search key: lower-case, accents stripped, whitespace collapsed.
create or replace function public.search_key(p text)
returns text
language sql
immutable
set search_path = ''
as $$
  select lower(regexp_replace(trim(extensions.unaccent('extensions.unaccent'::regdictionary, coalesce(p, ''))), '\s+', ' ', 'g'));
$$;

-- Score band for each reaction tier. A place's score can only move inside its band:
--   loved 8.0–10.0 · good 6.0–7.9 · mid 4.0–5.9 · nah 0.0–3.9
create or replace function public.tier_band(p public.tier, out low numeric, out high numeric)
language sql
immutable
set search_path = ''
as $$
  select
    case p when 'loved' then 8.0 when 'good' then 6.0 when 'mid' then 4.0 else 0.0 end::numeric,
    case p when 'loved' then 10.0 when 'good' then 7.9 when 'mid' then 5.9 else 3.9 end::numeric;
$$;

-- Score for position `pos` (0 = best) in a tier list of `n` places.
-- n = 1 lands mid-band (loved → 9.0), the best of many approaches the top of the band.
create or replace function public.tier_score(p public.tier, pos int, n int)
returns numeric
language sql
immutable
set search_path = ''
as $$
  select round(b.high - (b.high - b.low) * ((pos + 0.5) / greatest(n, 1)::numeric), 1)
  from public.tier_band(p) b;
$$;
