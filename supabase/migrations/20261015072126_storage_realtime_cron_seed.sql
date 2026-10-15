-- BigBack · 0007 · storage buckets + policies, realtime publication, cron schedules, seed data

-- ===========================================================================
-- STORAGE
-- Paths: meal-media/{user_id}/{meal_id}/{media_id}_{back|front|thumb|clip}.{jpg|heic|mp4}
--        reactions/{user_id}/{meal_id}/{reaction}.jpg      (selfie reactions)
--        avatars/{user_id}/{file}.jpg                       (public)
--        audio/{user_id}/{meal_id}/{quick_take_id}.m4a      (quick-take voice notes, private)
-- ===========================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('meal-media', 'meal-media', false, 15728640, array['image/jpeg', 'image/heic', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']),
  ('reactions',  'reactions',  false, 5242880,  array['image/jpeg', 'image/heic', 'image/webp']),
  ('avatars',    'avatars',    true,  5242880,  array['image/jpeg', 'image/png', 'image/webp', 'image/heic']),
  ('audio',      'audio',      false, 5242880,  array['audio/mp4', 'audio/m4a', 'audio/x-m4a', 'audio/aac'])
on conflict (id) do nothing;

-- meal-media: readable by whoever can see the meal; written only into your own folder + meal
create policy "meal media readable with the meal" on storage.objects
  for select to authenticated
  using (bucket_id = 'meal-media' and public.can_view_meal(public.try_uuid((storage.foldername(name))[2])));
create policy "meal media uploads into own meal" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'meal-media'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (select 1 from public.meals m
                where m.id = public.try_uuid((storage.foldername(name))[2]) and m.user_id = (select auth.uid()))
  );
create policy "meal media owner updates" on storage.objects
  for update to authenticated
  using (bucket_id = 'meal-media' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'meal-media' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "meal media owner deletes" on storage.objects
  for delete to authenticated
  using (bucket_id = 'meal-media' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- reactions: selfie reactions on meals you can see
create policy "reaction selfies readable with the meal" on storage.objects
  for select to authenticated
  using (bucket_id = 'reactions' and public.can_view_meal(public.try_uuid((storage.foldername(name))[2])));
create policy "reaction selfies upload" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'reactions'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and public.can_view_meal(public.try_uuid((storage.foldername(name))[2]))
  );
create policy "reaction selfies owner deletes" on storage.objects
  for delete to authenticated
  using (bucket_id = 'reactions' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- avatars: public read via CDN; owner writes
create policy "avatars owner uploads" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars owner updates" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars owner deletes" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- audio: private to the author
create policy "audio owner reads" on storage.objects
  for select to authenticated
  using (bucket_id = 'audio' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "audio owner uploads" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'audio' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "audio owner deletes" on storage.objects
  for delete to authenticated
  using (bucket_id = 'audio' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- ===========================================================================
-- REALTIME (Postgres Changes respect RLS)
--   notifications      -> in-app badge + activity list
--   party_members      -> who joined the table
--   meal_media         -> shared album while eating together
--   plan_guests        -> live RSVP list
--   decide_*           -> group swipe progress + "It's a match!"
-- ===========================================================================
alter publication supabase_realtime add table
  public.notifications,
  public.party_members,
  public.meal_media,
  public.plan_guests,
  public.decide_sessions,
  public.decide_participants,
  public.decide_votes;

-- ===========================================================================
-- CRON (UTC)
-- ===========================================================================
select cron.schedule('close-stale-meals',      '*/10 * * * *', $$select public._close_stale_meals();$$);
select cron.schedule('refresh-place-stats',    '*/15 * * * *', $$select public._refresh_place_stats();$$);
select cron.schedule('refresh-user-similarity', '15 8 * * *',  $$select public._refresh_user_similarity();$$);
select cron.schedule('expire-decide-sessions', '*/15 * * * *',
  $$update public.decide_sessions set status = 'closed' where status = 'open' and expires_at < now();$$);
select cron.schedule('mark-plans-done',        '30 * * * *',
  $$update public.plans set status = 'done' where status = 'planned' and starts_at < now() - interval '6 hours';$$);

-- ===========================================================================
-- SEED
-- ===========================================================================
insert into public.schools (slug, name, short_name, email_domains, city, timezone, center, is_live)
values ('uwaterloo', 'University of Waterloo', 'UW', array['uwaterloo.ca'], 'Waterloo', 'America/Toronto',
        extensions.st_setsrid(extensions.st_makepoint(-80.5449, 43.4723), 4326)::extensions.geography, true)
on conflict (slug) do nothing;

-- Terms as seasons (approximate term boundaries; adjust to the academic calendar).
insert into public.seasons (school_id, name, starts_on, ends_on)
select s.id, x.name, x.starts_on, x.ends_on
from public.schools s,
     (values ('Fall 2026', date '2026-09-01', date '2026-12-31'),
             ('Winter 2027', date '2027-01-01', date '2027-04-30'),
             ('Spring 2027', date '2027-05-01', date '2027-08-31')) as x(name, starts_on, ends_on)
where s.slug = 'uwaterloo'
on conflict (school_id, name) do nothing;

insert into public.badges (key, name, description, icon) values
  ('first_bite',        'First Bite',            'Rated your first spot.',                                'fork.knife'),
  ('clean_plate',       'Clean Plate Club',      'Posted a Damage Report.',                               'checkmark.seal'),
  ('plaza_completionist','Plaza Completionist',  'Ate at every spot in University Plaza.',                'map'),
  ('late_night_legend', 'Late Night Legend',     'Ranked 10 Late Night spots.',                           'moon.stars'),
  ('shawarma_sommelier','Shawarma Sommelier',    'Ranked 5 shawarma spots.',                              'flame'),
  ('table_setter',      'Table Setter',          'Hosted 5 plans that actually happened.',               'person.3'),
  ('streak_4',          'Four-Week Feast',       'New spot every week for 4 weeks.',                      'calendar'),
  ('tastemaker',        'Tastemaker',            '10 people saved a spot from your posts.',               'bookmark'),
  ('fight_judge',       'Food Fight Judge',      'Voted in a Food Fight.',                                'trophy')
on conflict (key) do nothing;

insert into public.app_config (key, value) values
  ('ai',            '{"ask_enabled": true, "daily_limit": 10, "model": "claude-haiku-4-5"}'::jsonb),
  ('ranking',       '{"max_comparisons": 3, "settle_cards_per_day": 1}'::jsonb),
  ('meal',          '{"auto_close_hours": 3}'::jsonb),
  ('min_app_version', '"1.0.0"'::jsonb)
on conflict (key) do nothing;
