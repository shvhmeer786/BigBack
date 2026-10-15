-- BigBack · 0009 · App Review / demo access (applied as `app_review_access`)
-- Apple reviewers can't receive OTP codes at a school inbox, so specific demo emails are allowlisted
-- (signed in with a password; credentials go in App Review notes). Demo accounts are flagged and kept
-- out of campus stats and leaderboards.

create table public.signup_allowlist (
  email      extensions.citext primary key,
  school_id  uuid references public.schools (id) on delete set null,
  is_demo    boolean not null default true,
  note       text,
  created_at timestamptz not null default now()
);
alter table public.signup_allowlist enable row level security;
create policy "auth hook reads the allowlist" on public.signup_allowlist
  for select to supabase_auth_admin using (true);
grant select on public.signup_allowlist to supabase_auth_admin;

alter table public.profiles add column is_demo boolean not null default false;

create or replace function public.hook_before_user_created(event jsonb)
returns jsonb
language plpgsql
stable
set search_path = ''
as $$
declare
  v_email  text := lower(coalesce(event -> 'user' ->> 'email', ''));
  v_domain text := split_part(v_email, '@', 2);
begin
  if exists (select 1 from public.signup_allowlist a where a.email = v_email::extensions.citext) then
    return '{}'::jsonb;
  end if;
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
  v_demo   boolean := false;
begin
  v_base := left(regexp_replace(lower(v_local), '[^a-z0-9_.]', '', 'g'), 18);
  if char_length(v_base) < 3 then
    v_base := 'eater';
  end if;
  v_handle := v_base;
  while exists (select 1 from public.profiles p where p.handle = v_handle::extensions.citext) loop
    v_handle := v_base || lpad((floor(random() * 10000))::int::text, 4, '0');
  end loop;

  select a.school_id, a.is_demo into v_school, v_demo
  from public.signup_allowlist a where a.email = lower(coalesce(new.email, ''))::extensions.citext;

  if v_school is null then
    select s.id into v_school
    from public.schools s
    where v_domain = any (s.email_domains)
       or exists (select 1 from unnest(s.email_domains) d where v_domain like '%.' || d)
    limit 1;
  end if;

  insert into public.profiles (id, handle, display_name, school_id, is_demo)
  values (
    new.id,
    v_handle,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), initcap(replace(v_local, '.', ' ')), 'New eater'),
    v_school,
    coalesce(v_demo, false)
  );
  return new;
end;
$$;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

create or replace function public._guard_profiles()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if public._is_client() then
    new.school_id  := old.school_id;
    new.created_at := old.created_at;
    new.is_demo    := old.is_demo;
  end if;
  return new;
end;
$$;

-- _refresh_place_stats and leaderboard re-created with `and not pr.is_demo` filters
-- (identical to 0006e / 0006a otherwise).

create or replace function public._refresh_place_stats()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  with campus_mean as (
    select pr.school_id, avg(r.score) as m
    from public.rankings r join public.profiles pr on pr.id = r.user_id
    where pr.school_id is not null and not pr.is_demo group by pr.school_id
  ),
  agg as (
    select pr.school_id, r.place_id, count(*) as n, sum(r.score) as total,
           count(*) filter (where r.tier = 'loved') as n_loved, avg(r.score) as mean
    from public.rankings r join public.profiles pr on pr.id = r.user_id
    where pr.school_id is not null and not pr.is_demo
    group by pr.school_id, r.place_id
  ),
  saves_agg as (
    select pr.school_id, s.place_id, count(*) as n_saves
    from public.saves s join public.profiles pr on pr.id = s.user_id
    where pr.school_id is not null and not pr.is_demo group by pr.school_id, s.place_id
  ),
  recent as (
    select pr.school_id, m.place_id, count(*) as n7
    from public.meals m join public.profiles pr on pr.id = m.user_id
    where m.status = 'posted' and m.posted_at > now() - interval '7 days'
      and pr.school_id is not null and not pr.is_demo
    group by pr.school_id, m.place_id
  ),
  keys as (
    select school_id, place_id from agg
    union select school_id, place_id from saves_agg
    union select school_id, place_id from recent
  )
  insert into public.place_stats as ps (school_id, place_id, n_ratings, n_loved, mean_score, bayes_score,
                                        n_saves, n_meals_7d, trending_score, updated_at)
  select k.school_id, k.place_id,
         coalesce(a.n, 0), coalesce(a.n_loved, 0), round(a.mean, 2),
         case when a.n is null then null
              else round((5 * coalesce(cm.m, 7.0) + a.total) / (5 + a.n), 1) end,
         coalesce(s.n_saves, 0), coalesce(r.n7, 0),
         round(coalesce(r.n7, 0) * 1.0 + coalesce(s.n_saves, 0) * 0.3 + coalesce(a.n_loved, 0) * 0.2, 2),
         now()
  from keys k
  left join agg a on a.school_id = k.school_id and a.place_id = k.place_id
  left join saves_agg s on s.school_id = k.school_id and s.place_id = k.place_id
  left join recent r on r.school_id = k.school_id and r.place_id = k.place_id
  left join campus_mean cm on cm.school_id = k.school_id
  on conflict (school_id, place_id) do update set
    n_ratings = excluded.n_ratings, n_loved = excluded.n_loved, mean_score = excluded.mean_score,
    bayes_score = excluded.bayes_score, n_saves = excluded.n_saves, n_meals_7d = excluded.n_meals_7d,
    trending_score = excluded.trending_score, updated_at = now();
end;
$$;

-- Pearson correlation of scores on shared places, for every pair with >= 5 in common.
revoke execute on function public._refresh_place_stats() from public, anon, authenticated;

create or replace function public.leaderboard(p_season_id uuid, p_limit int default 50)
returns table (user_id uuid, handle text, display_name text, places int, rank int)
language sql
stable
security definer
set search_path = ''
as $$
  with s as (select * from public.seasons where id = p_season_id),
  counts as (
    select m.user_id, count(distinct m.place_id)::int as places
    from public.meals m, s
    join public.profiles pr on pr.school_id = s.school_id
    where m.user_id = pr.id and m.status = 'posted'
      and m.posted_at >= s.starts_on and m.posted_at < s.ends_on + 1
      and not pr.is_private and not pr.is_demo
    group by m.user_id
  )
  select c.user_id, p.handle::text, p.display_name, c.places,
         (rank() over (order by c.places desc))::int
  from counts c join public.profiles p on p.id = c.user_id
  where not public.is_blocked_between(auth.uid(), c.user_id)
  order by c.places desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200);
$$;

-- Taste match % between the viewer and another user (null until 5 shared places).
