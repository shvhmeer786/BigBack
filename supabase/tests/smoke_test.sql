-- BigBack · end-to-end smoke test (run with execute_sql against the project).
-- Everything happens inside one DO block that ALWAYS ends by raising an exception, so the whole
-- transaction rolls back and no test data is left behind. Success looks like:
--   ERROR: SMOKE_TEST_PASSED: <summary>
-- Any other error (or a failed ASSERT) is a real failure.

do $$
declare
  a uuid := gen_random_uuid();  -- Alice (public)
  b uuid := gen_random_uuid();  -- Bob (goes private)
  c uuid := gen_random_uuid();  -- Cara
  p1 uuid; p2 uuid; p3 uuid; p4 uuid;
  m1 uuid; m2 uuid; m3 uuid; mb uuid; m5 uuid;
  v_party uuid; v_bob_meal uuid; v_session uuid; v_cand uuid; v_match uuid; v_far uuid;
  v_plan public.plans;
  r record;
  n int;
  v_score numeric;
  ok text[] := '{}';
begin
  -- ---------- setup as postgres ----------
  insert into auth.users (instance_id, id, aud, role, email, raw_user_meta_data, created_at, updated_at) values
    ('00000000-0000-0000-0000-000000000000', a, 'authenticated', 'authenticated', 'alice.smoke@uwaterloo.ca', '{"display_name":"Alice"}', now(), now()),
    ('00000000-0000-0000-0000-000000000000', b, 'authenticated', 'authenticated', 'bob.smoke@uwaterloo.ca',   '{"display_name":"Bob"}',   now(), now()),
    ('00000000-0000-0000-0000-000000000000', c, 'authenticated', 'authenticated', 'cara.smoke@uwaterloo.ca',  '{"display_name":"Cara"}',  now(), now());
  select count(*) into n from public.profiles where id in (a, b, c);
  assert n = 3, 'profiles were not created by handle_new_user';
  assert (select school_id from public.profiles where id = a) is not null, 'school not assigned from email domain';
  ok := array_append(ok, 'profiles+school');

  insert into public.places (name, location, source, cuisines, tags, price_level, primary_category)
  values ('Smoke Shawarma', extensions.st_setsrid(extensions.st_makepoint(-80.5440, 43.4730), 4326)::extensions.geography, 'admin', '{shawarma}', '{late_night}', 1, 'restaurant')
  returning id into p1;
  insert into public.places (name, location, source, cuisines, tags, price_level, primary_category)
  values ('Smoke Noodles', extensions.st_setsrid(extensions.st_makepoint(-80.5420, 43.4740), 4326)::extensions.geography, 'admin', '{noodles,chinese}', '{late_night}', 1, 'restaurant')
  returning id into p2;
  insert into public.places (name, location, source, cuisines, tags, price_level, primary_category)
  values ('Smoke Pizza', extensions.st_setsrid(extensions.st_makepoint(-80.5460, 43.4710), 4326)::extensions.geography, 'admin', '{pizza}', '{}', 1, 'restaurant')
  returning id into p3;
  insert into public.places (name, location, source, cuisines, tags, price_level, primary_category)
  values ('Smoke Cafe', extensions.st_setsrid(extensions.st_makepoint(-80.5450, 43.4725), 4326)::extensions.geography, 'admin', '{coffee}', '{}', 2, 'cafe')
  returning id into p4;
  insert into public.place_hours (place_id, dow, opens, closes)
  select p1, d, time '11:00', time '03:00' from generate_series(0, 6) d;

  -- ---------- Alice ----------
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  -- ---------- Onboarding: handle check, name/handle/terms, guarded fields ----------
  assert public.is_handle_available('alice_eats'), 'free handle reported as taken';
  assert not public.is_handle_available('bob.smoke'), 'taken handle reported as free';
  assert not public.is_handle_available('admin'), 'reserved handle allowed';
  assert not public.is_handle_available('no spaces'), 'invalid handle allowed';
  update public.profiles set onboarded_at = now(), is_demo = true where id = a;
  assert (select onboarded_at is null and not is_demo from public.profiles where id = a), 'client set guarded profile fields';
  perform public.complete_onboarding('Alice A', 'alice_eats', '2026-10');
  assert (select handle = 'alice_eats' and onboarded_at is not null and terms_version = '2026-10'
          from public.profiles where id = a), 'complete_onboarding did not save';
  begin
    perform public.complete_onboarding('Alice A', 'bob.smoke', '2026-10');
    assert false, 'took another user''s handle';
  exception when raise_exception then
    null;
  end;
  ok := array_append(ok, 'onboarding');

  insert into public.meals (user_id, place_id) values (a, p1) returning id into m1;
  insert into public.meal_media (meal_id, user_id, back_path, front_path, moment, is_live)
  values (m1, a, a || '/' || m1 || '/x_back.jpg', a || '/' || m1 || '/x_front.jpg', 'food', true);
  select * into r from public.submit_rating(m1, 'loved', 'late_night', 0, true, '[]'::jsonb);
  assert r.score = 9.0, format('first loved place should score 9.0, got %s', r.score);
  ok := array_append(ok, 'first-rating=9.0');

  insert into public.meals (user_id, place_id, status) values (a, p2, 'unrated') returning id into m2;
  select * into r from public.submit_rating(m2, 'loved', 'late_night', 0, true,
    jsonb_build_array(jsonb_build_object('winner', p2, 'loser', p1)));
  assert r.score = 9.5, format('new #1 of 2 should be 9.5, got %s', r.score);
  assert (select score from public.rankings where user_id = a and place_id = p1) = 8.5, 'old #1 should drop to 8.5';
  assert (select count(*) from public.comparisons where user_id = a) = 1, 'comparison not recorded';
  ok := array_append(ok, 'binary-insert+rescore');

  insert into public.meals (user_id, place_id, status) values (a, p3, 'unrated') returning id into m3;
  select * into r from public.submit_rating(m3, 'good', 'cheap_eats', 0, true, '[]'::jsonb);
  assert r.score = 7.0, format('first good place should be 7.0, got %s', r.score);
  ok := array_append(ok, 'tier-bands');

  update public.meals set tier = 'nah', score_at_post = 1.0 where id = m3;
  assert (select tier from public.meals where id = m3) = 'good', 'guard trigger let a client overwrite tier';
  ok := array_append(ok, 'meal-guard');

  begin
    insert into public.rankings (user_id, place_id, tier, vibe, position) values (a, p4, 'loved', 'cafe', 0);
    assert false, 'client inserted into rankings directly';
  exception when insufficient_privilege or check_violation then
    null;
  end;
  ok := array_append(ok, 'rankings-rls');

  perform public.move_ranking(p1, 'loved', 0);
  assert (select score from public.rankings where user_id = a and place_id = p1) = 9.5, 'move_ranking failed';
  ok := array_append(ok, 'move_ranking');

  insert into public.follows (follower_id, followee_id) values (a, b);
  assert (select status from public.follows where follower_id = a and followee_id = b) = 'accepted', 'public follow should auto-accept';
  insert into public.saves (user_id, place_id) values (a, p4);

  -- ---------- Bob goes private and posts ----------
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  update public.profiles set is_private = true where id = b;
  insert into public.meals (user_id, place_id, status) values (b, p4, 'unrated') returning id into mb;
  perform public.submit_rating(mb, 'mid', 'cafe', 0, true, '[]'::jsonb);

  -- ---------- Alice sees Bob (accepted follower) + friend_went notification ----------
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  select count(*) into n from public.get_feed(null, 20);
  assert n = 4, format('alice feed should have 3 own + 1 bob = 4, got %s', n);
  assert exists (select 1 from public.notifications where user_id = a and kind = 'friend_went' and meal_id = mb),
    'friend_went notification missing';
  ok := array_append(ok, 'feed+friend_went');

  -- ---------- Cara: request to follow private Bob -> cannot see ----------
  perform set_config('request.jwt.claims', json_build_object('sub', c, 'role', 'authenticated')::text, true);
  insert into public.follows (follower_id, followee_id) values (c, b);
  assert (select status from public.follows where follower_id = c and followee_id = b) = 'requested', 'private follow should be a request';
  select count(*) into n from public.meals where user_id = b;
  assert n = 0, 'cara can see private bob meals before acceptance';

  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  update public.follows set status = 'accepted' where follower_id = c and followee_id = b;

  perform set_config('request.jwt.claims', json_build_object('sub', c, 'role', 'authenticated')::text, true);
  select count(*) into n from public.meals where user_id = b;
  assert n = 1, 'cara cannot see bob meals after acceptance';
  ok := array_append(ok, 'private-profiles');

  -- ---------- Party: Alice tags Bob + Cara at a live meal ----------
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  insert into public.meals (user_id, place_id) values (a, p1) returning id into m5;
  v_party := public.tag_friends(m5, array[b, c]);
  assert v_party is not null, 'tag_friends returned no party';

  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  assert exists (select 1 from public.notifications where user_id = b and kind = 'meal_tag'), 'meal_tag notification missing';
  v_bob_meal := public.respond_party_invite(v_party, true);
  assert v_bob_meal is not null, 'accepting a tag should create a meal';
  assert exists (select 1 from public.meals where id = m5), 'party member cannot see host live meal';
  ok := array_append(ok, 'party+tagging');

  -- ---------- Let's eat: Alice + Bob swipe ----------
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  v_session := public.create_decide_session(array[b], 43.4723, -80.5449, null, '{}'::jsonb, 8);
  select count(*) into n from public.decide_candidates where session_id = v_session;
  assert n >= 1, 'no decide candidates generated';
  select place_id into v_cand from public.decide_candidates where session_id = v_session order by position limit 1;
  v_match := public.decide_vote(v_session, v_cand, true);
  assert v_match is null, 'match should need both votes';

  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  v_match := public.decide_vote(v_session, v_cand, true);
  assert v_match = v_cand, 'unanimous like should match';
  assert exists (select 1 from public.notifications where user_id = b and kind = 'decide_match'), 'decide_match notification missing';
  ok := array_append(ok, 'lets-eat');

  -- ---------- Plans ----------
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  v_plan := public.create_plan(v_cand, now() + interval '1 day', array[b]);
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  perform public.rsvp(v_plan.id, 'going');
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  assert exists (select 1 from public.notifications where user_id = a and kind = 'plan_rsvp'), 'host not told about rsvp';
  ok := array_append(ok, 'plans+rsvp');

  -- ---------- Reads ----------
  select count(*) into n from public.tonight_picks(43.4723, -80.5449);
  assert n >= 1, 'tonight_picks returned nothing';
  select * into r from public.get_place_scores(p1);
  assert r.my_score = 9.5, format('get_place_scores my_score expected 9.5 got %s', r.my_score);
  assert r.open_now is not null, 'open_now should be known for a place with hours';
  select count(*) into n from public.search_places('smoke noodle', 43.4723, -80.5449, 10);
  assert n >= 1, 'search_places found nothing';
  assert public.user_streak(a) >= 1, 'streak should be >= 1';
  ok := array_append(ok, 'reads');

  -- ---------- resolve_place (MapKit result -> our place) ----------
  assert public.resolve_place('apple-smoke-1', 'Smoke Shawarma', 43.4730, -80.5440) = p1,
    'resolve_place should match the nearby place with the same name';
  assert (select apple_place_id from public.places where id = p1) = 'apple-smoke-1', 'apple id not linked';
  assert public.resolve_place('apple-smoke-1', 'whatever', 0, 0) = p1, 'known apple id should short-circuit';
  v_cand := public.resolve_place('apple-smoke-2', 'Brand New Dumplings', 43.4800, -80.5300);
  assert (select source from public.places where id = v_cand) = 'user', 'unknown place should be user-sourced';
  ok := array_append(ok, 'resolve_place');

  -- ---------- Rank anywhere: UW students eat in Vancouver and New York too ----------
  v_far := public.resolve_place('apple-smoke-van', 'Smoke Van Sushi', 49.2827, -123.1207, 'restaurant', null, 'ca', 'America/Vancouver');
  assert (select timezone from public.places where id = v_far) = 'America/Vancouver', 'place time zone not stored';
  assert (select country from public.places where id = v_far) = 'CA', 'country should be normalised to CA';
  v_cand := public.resolve_place('apple-smoke-nyc', 'Smoke NYC Slice', 40.7128, -74.0060, 'restaurant', null, 'US', 'Mars/Base');
  assert (select country from public.places where id = v_cand) = 'US', 'US place stored with the wrong country';
  assert (select timezone from public.places where id = v_cand) is null, 'an invalid time zone should be ignored';
  insert into public.meals (user_id, place_id, status) values (a, v_far, 'unrated') returning id into m3;
  select * into r from public.submit_rating(m3, 'good', 'cheap_eats', 0, true, '[]'::jsonb);
  assert r.score is not null, 'could not rate a place outside Waterloo';
  ok := array_append(ok, 'rank-anywhere');

  -- ---------- Map results: signals for Apple IDs, and a Let's eat deck from map picks ----------
  select count(*) into n from public.place_signals(array['apple-smoke-1', 'apple-never-seen']);
  assert n = 2, 'place_signals should return one row per Apple ID';
  assert (select my_score from public.place_signals(array['apple-smoke-1'])) = 9.5, 'place_signals my_score wrong';
  assert (select place_id from public.place_signals(array['apple-never-seen'])) is null, 'unknown Apple ID should have no place';
  v_session := public.create_decide_session(array[b], 43.4723, -80.5449, null,
    jsonb_build_object('place_ids', jsonb_build_array(v_far)), 8);
  assert exists (select 1 from public.decide_candidates where session_id = v_session and place_id = v_far),
    'map pick missing from the Let''s eat deck';
  ok := array_append(ok, 'map-results');

  -- ---------- Blocks ----------
  perform set_config('request.jwt.claims', json_build_object('sub', c, 'role', 'authenticated')::text, true);
  insert into public.blocks (blocker_id, blocked_id) values (c, a);
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  assert not exists (select 1 from public.profiles where id = c), 'blocked user still visible';
  ok := array_append(ok, 'blocks');

  -- ---------- Privacy: nobody can ask about other people's follows or blocks ----------
  perform set_config('request.jwt.claims', json_build_object('sub', c, 'role', 'authenticated')::text, true);
  assert public.is_following(a, b) is null, 'is_following answered about two other users';
  assert public.is_blocked_between(a, b) is null, 'is_blocked_between answered about two other users';
  assert public.is_blocked_between(c, a), 'your own block should be visible to you';
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  ok := array_append(ok, 'privacy-helpers');

  -- ---------- Jobs (as postgres) ----------
  execute 'reset role';
  perform public._refresh_place_stats();
  assert exists (select 1 from public.place_stats where place_id = p1), 'place_stats not refreshed';
  perform public._close_stale_meals();
  ok := array_append(ok, 'jobs');

  -- ---------- Opening hours use the place's own time zone ----------
  insert into public.place_hours (place_id, dow, opens, closes)
  select v_far, d, time '09:00', time '17:00' from generate_series(0, 6) d;
  -- 23:30 UTC is 16:30 in Vancouver (open) but 19:30 in Toronto (closed).
  assert public.is_open_at(v_far, timestamptz '2026-10-15 23:30:00+00') = true, 'open_now ignored the place time zone';
  assert public.is_open_at(v_far, timestamptz '2026-10-16 02:00:00+00') = false, 'should be closed at 19:00 Vancouver time';
  ok := array_append(ok, 'local-hours');

  -- ---------- Sign-up is UW-only (Before User Created hook) ----------
  assert public.hook_before_user_created('{"user":{"email":"new.student@uwaterloo.ca"}}') = '{}'::jsonb, 'uwaterloo.ca should be allowed';
  assert public.hook_before_user_created('{"user":{"email":"New.Student@UWaterloo.CA"}}') = '{}'::jsonb, 'domain check should ignore case';
  assert (public.hook_before_user_created('{"user":{"email":"x@gmail.com"}}') -> 'error') is not null, 'gmail should be rejected';
  assert (public.hook_before_user_created('{"user":{"email":"x@uwaterloo.ca.evil.com"}}') -> 'error') is not null, 'lookalike domain accepted';
  assert (public.hook_before_user_created('{"user":{"email":"x@notuwaterloo.ca"}}') -> 'error') is not null, 'lookalike domain accepted';
  ok := array_append(ok, 'signup-uw-only');

  raise exception 'SMOKE_TEST_PASSED: %', array_to_string(ok, ', ');
end;
$$;
