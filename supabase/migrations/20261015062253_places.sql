-- BigBack · 0003 · places, hours, import staging, user edits, stats, saves (Want to Try)

-- ---------------------------------------------------------------------------
-- Places: our own canonical record. External IDs link it to Apple Maps (on-device
-- MapKit), Google, Foursquare, Overture, OSM, Yelp. We store only what licences allow:
-- Apple/Google content is never copied here (IDs only); display fields come from
-- open data (FSQ OS Places / Overture), admins, or users.
-- ---------------------------------------------------------------------------
create table public.places (
  id                    uuid primary key default gen_random_uuid(),
  name                  text not null check (char_length(name) between 1 and 120),
  name_key              text generated always as (public.search_key(name)) stored,
  location              extensions.geography(point, 4326) not null,
  address               text,
  locality              text,             -- city, e.g. Waterloo
  region                text,             -- province / state, e.g. ON
  postcode              text,
  country               char(2) not null default 'CA',
  neighborhood          text,             -- e.g. University Plaza, Uptown
  primary_category      text,             -- restaurant | cafe | bakery | bar | dessert | food_truck | ...
  cuisines              text[] not null default '{}',
  tags                  text[] not null default '{}',  -- vegetarian_options, late_night, student_deal, ...
  price_level           smallint check (price_level between 1 and 4),
  phone                 text,
  website               text,
  menu_url              text,
  reservation_provider  public.reservation_provider not null default 'unknown',
  reservation_url       text,
  apple_place_id        text unique,      -- MKMapItem.Identifier (persisting is allowed by Apple)
  google_place_id       text unique,      -- Places API place_id (storable indefinitely)
  fsq_place_id          text unique,
  overture_id           text unique,
  osm_id                text unique,      -- e.g. node/123456
  yelp_business_id      text unique,
  source                public.place_source not null,
  is_permanently_closed boolean not null default false,
  created_by            uuid references public.profiles (id) on delete set null,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);
comment on table public.places is 'Canonical places. External-provider content is not stored here, only their IDs.';
create index places_location_gist on public.places using gist (location);
create index places_name_trgm_idx on public.places using gin (name_key extensions.gin_trgm_ops);
create index places_cuisines_idx on public.places using gin (cuisines);
create index places_tags_idx on public.places using gin (tags);
create index places_locality_idx on public.places (locality);
create trigger places_updated_at before update on public.places
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Opening hours. closes <= opens means the slot runs past midnight.
-- ---------------------------------------------------------------------------
create table public.place_hours (
  place_id   uuid not null references public.places (id) on delete cascade,
  dow        smallint not null check (dow between 0 and 6),   -- 0 = Sunday
  opens      time not null,
  closes     time not null,
  source     text not null default 'admin',
  updated_at timestamptz not null default now(),
  primary key (place_id, dow, opens)
);

-- ---------------------------------------------------------------------------
-- Import staging for open datasets (FSQ OS Places / Overture / OSM). Never exposed
-- to clients; the resolve-place Edge Function matches against it.
-- ---------------------------------------------------------------------------
create table public.place_import (
  source       public.place_source not null,
  source_id    text not null,
  name         text not null,
  name_key     text generated always as (public.search_key(name)) stored,
  location     extensions.geography(point, 4326) not null,
  address      text,
  locality     text,
  region       text,
  postcode     text,
  country      char(2),
  categories   text[] not null default '{}',
  phone        text,
  website      text,
  confidence   numeric,
  raw          jsonb,
  imported_at  timestamptz not null default now(),
  matched_place_id uuid references public.places (id) on delete set null,
  primary key (source, source_id)
);
create index place_import_location_gist on public.place_import using gist (location);
create index place_import_name_trgm_idx on public.place_import using gin (name_key extensions.gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- User-suggested corrections (reservation link, hours, closed, price, cuisine).
-- Applied by an admin / moderation tool.
-- ---------------------------------------------------------------------------
create table public.place_edits (
  id          uuid primary key default gen_random_uuid(),
  place_id    uuid not null references public.places (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  field       text not null check (field in ('reservation_url', 'hours', 'closed', 'price_level', 'cuisines', 'name', 'address', 'phone', 'website', 'menu_url', 'other')),
  value       jsonb not null,
  note        text check (char_length(note) <= 500),
  status      public.edit_status not null default 'pending',
  created_at  timestamptz not null default now(),
  reviewed_at timestamptz
);
create index place_edits_place_idx on public.place_edits (place_id);
create index place_edits_user_idx on public.place_edits (user_id);
create index place_edits_pending_idx on public.place_edits (created_at) where status = 'pending';

-- ---------------------------------------------------------------------------
-- Campus-scoped aggregates, refreshed by pg_cron (see 0016).
-- bayes_score = (C·m + Σscore) / (C + n), C = 5, m = campus mean.
-- ---------------------------------------------------------------------------
create table public.place_stats (
  school_id      uuid not null references public.schools (id) on delete cascade,
  place_id       uuid not null references public.places (id) on delete cascade,
  n_ratings      int not null default 0,
  n_loved        int not null default 0,
  mean_score     numeric(4, 2),
  bayes_score    numeric(3, 1),
  n_saves        int not null default 0,
  n_meals_7d     int not null default 0,
  trending_score numeric not null default 0,
  updated_at     timestamptz not null default now(),
  primary key (school_id, place_id)
);
create index place_stats_place_idx on public.place_stats (place_id);
create index place_stats_trending_idx on public.place_stats (school_id, trending_score desc);

-- ---------------------------------------------------------------------------
-- Saves = Want to Try
-- ---------------------------------------------------------------------------
create table public.saves (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  place_id   uuid not null references public.places (id) on delete cascade,
  note       text check (char_length(note) <= 140),
  source_meal_id uuid,  -- the feed post it was saved from (FK added in 0004)
  created_at timestamptz not null default now(),
  primary key (user_id, place_id)
);
create index saves_place_idx on public.saves (place_id);
