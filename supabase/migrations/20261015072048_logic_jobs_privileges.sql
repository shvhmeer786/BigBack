-- BigBack · 0006e · scheduled-job bodies + function privileges

create or replace function public._close_stale_meals()
returns int
language sql
security definer
set search_path = ''
as $$
  with u as (
    update public.meals set status = 'unrated', ended_at = coalesce(ended_at, started_at + interval '3 hours')
    where status = 'live' and started_at < now() - interval '3 hours'
    returning 1
  ) select count(*)::int from u;
$$;

-- Campus aggregates per place: Bayesian score, loved count, saves, 7-day activity, trending.
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
    where pr.school_id is not null group by pr.school_id
  ),
  agg as (
    select pr.school_id, r.place_id, count(*) as n, sum(r.score) as total,
           count(*) filter (where r.tier = 'loved') as n_loved, avg(r.score) as mean
    from public.rankings r join public.profiles pr on pr.id = r.user_id
    where pr.school_id is not null
    group by pr.school_id, r.place_id
  ),
  saves_agg as (
    select pr.school_id, s.place_id, count(*) as n_saves
    from public.saves s join public.profiles pr on pr.id = s.user_id
    where pr.school_id is not null group by pr.school_id, s.place_id
  ),
  recent as (
    select pr.school_id, m.place_id, count(*) as n7
    from public.meals m join public.profiles pr on pr.id = m.user_id
    where m.status = 'posted' and m.posted_at > now() - interval '7 days' and pr.school_id is not null
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
-- Upsert-only: pairs keep their last value if they later drop below 5 shared places (rare).
create or replace function public._refresh_user_similarity()
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.user_similarity as us (user_a, user_b, n_shared, corr, updated_at)
  select a.user_id, b.user_id, count(*)::int,
         round(coalesce(corr(a.score, b.score), 0)::numeric, 3), now()
  from public.rankings a
  join public.rankings b on b.place_id = a.place_id and b.user_id <> a.user_id
  group by a.user_id, b.user_id
  having count(*) >= 5
  on conflict (user_a, user_b) do update set
    n_shared = excluded.n_shared, corr = excluded.corr, updated_at = now();
$$;

-- ===========================================================================
-- 7. PRIVILEGES: internal helpers are not callable from the API
-- ===========================================================================
revoke execute on function public._recompute_tier_scores(uuid, public.tier) from public, anon, authenticated;
revoke execute on function public._remove_ranking(uuid, uuid) from public, anon, authenticated;
revoke execute on function public._insert_ranking(uuid, uuid, public.tier, public.vibe, int, boolean, uuid, int) from public, anon, authenticated;
revoke execute on function public._notify(uuid, text, uuid, uuid, uuid, uuid, jsonb) from public, anon, authenticated;
revoke execute on function public._close_stale_meals() from public, anon, authenticated;
revoke execute on function public._refresh_place_stats() from public, anon, authenticated;
revoke execute on function public._refresh_user_similarity() from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- Client RPCs require a signed-in user.
revoke execute on function public.submit_rating(uuid, public.tier, public.vibe, int, boolean, jsonb) from public, anon;
revoke execute on function public.rerate_visit(uuid, text) from public, anon;
revoke execute on function public.move_ranking(uuid, public.tier, int, public.vibe) from public, anon;
revoke execute on function public.record_comparison(uuid, uuid, public.comparison_source, boolean) from public, anon;
revoke execute on function public.tag_friends(uuid, uuid[]) from public, anon;
revoke execute on function public.respond_party_invite(uuid, boolean) from public, anon;
revoke execute on function public.join_party(text) from public, anon;
revoke execute on function public.create_plan(uuid, timestamptz, uuid[], uuid, text, uuid) from public, anon;
revoke execute on function public.rsvp(uuid, public.rsvp) from public, anon;
revoke execute on function public.plan_by_code(text) from public, anon;
revoke execute on function public.create_decide_session(uuid[], double precision, double precision, uuid, jsonb, int) from public, anon;
revoke execute on function public.decide_vote(uuid, uuid, boolean) from public, anon;
revoke execute on function public.decide_finalize(uuid) from public, anon;
revoke execute on function public.fight_vote(uuid, uuid) from public, anon;
revoke execute on function public.predicted_score(uuid, uuid) from public, anon;
revoke execute on function public.get_place_scores(uuid) from public, anon;
revoke execute on function public.tonight_picks(double precision, double precision, text, public.vibe, smallint, int, real, int) from public, anon;
revoke execute on function public.user_streak(uuid) from public, anon;
revoke execute on function public.leaderboard(uuid, int) from public, anon;
revoke execute on function public.taste_match(uuid) from public, anon;
revoke execute on function public.get_feed(timestamptz, int) from public, anon;
revoke execute on function public.get_place_meals(uuid, timestamptz, int) from public, anon;
revoke execute on function public.search_places(text, double precision, double precision, int) from public, anon;
revoke execute on function public.nearby_places(double precision, double precision, int, int) from public, anon;
grant execute on function public.submit_rating(uuid, public.tier, public.vibe, int, boolean, jsonb),
  public.rerate_visit(uuid, text), public.move_ranking(uuid, public.tier, int, public.vibe),
  public.record_comparison(uuid, uuid, public.comparison_source, boolean),
  public.tag_friends(uuid, uuid[]), public.respond_party_invite(uuid, boolean), public.join_party(text),
  public.create_plan(uuid, timestamptz, uuid[], uuid, text, uuid), public.rsvp(uuid, public.rsvp),
  public.plan_by_code(text),
  public.create_decide_session(uuid[], double precision, double precision, uuid, jsonb, int),
  public.decide_vote(uuid, uuid, boolean), public.decide_finalize(uuid), public.fight_vote(uuid, uuid),
  public.predicted_score(uuid, uuid), public.get_place_scores(uuid),
  public.tonight_picks(double precision, double precision, text, public.vibe, smallint, int, real, int),
  public.user_streak(uuid), public.leaderboard(uuid, int), public.taste_match(uuid),
  public.get_feed(timestamptz, int), public.get_place_meals(uuid, timestamptz, int),
  public.search_places(text, double precision, double precision, int),
  public.nearby_places(double precision, double precision, int, int)
to authenticated;
