-- BigBack · 0006d · notification rows written by triggers (the push Edge Function delivers them)

create or replace function public._notify(
  p_user uuid, p_kind text, p_actor uuid default null, p_meal uuid default null,
  p_plan uuid default null, p_place uuid default null, p_payload jsonb default '{}'::jsonb)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.notifications (user_id, kind, actor_id, meal_id, plan_id, place_id, payload)
  select p_user, p_kind, p_actor, p_meal, p_plan, p_place, coalesce(p_payload, '{}'::jsonb)
  where p_user is not null
    and p_user is distinct from p_actor
    and not public.is_blocked_between(p_user, p_actor);
$$;

create or replace function public._notify_follows()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    perform public._notify(new.followee_id, case when new.status = 'requested' then 'follow_request' else 'follow' end, new.follower_id);
  elsif tg_op = 'UPDATE' and new.status = 'accepted' and old.status = 'requested' then
    perform public._notify(new.follower_id, 'follow_accepted', new.followee_id);
  end if;
  return new;
end;
$$;
create trigger follows_notify after insert or update on public.follows
  for each row execute function public._notify_follows();

create or replace function public._notify_reaction()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public._notify((select user_id from public.meals where id = new.meal_id), 'reaction', new.user_id, new.meal_id,
                         null, null, jsonb_build_object('kind', new.kind));
  return new;
end;
$$;
create trigger reactions_notify after insert on public.reactions
  for each row execute function public._notify_reaction();

create or replace function public._notify_comment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public._notify((select user_id from public.meals where id = new.meal_id), 'comment', new.user_id, new.meal_id,
                         null, null, jsonb_build_object('comment_id', new.id, 'preview', left(new.body, 80)));
  if new.parent_id is not null then
    perform public._notify((select user_id from public.comments where id = new.parent_id), 'comment_reply', new.user_id,
                           new.meal_id, null, null, jsonb_build_object('comment_id', new.id, 'preview', left(new.body, 80)));
  end if;
  return new;
end;
$$;
create trigger comments_notify after insert on public.comments
  for each row execute function public._notify_comment();

create or replace function public._notify_party_member()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'pending' then
    perform public._notify(new.user_id, 'meal_tag', new.invited_by, null, null,
                           (select place_id from public.parties where id = new.party_id),
                           jsonb_build_object('party_id', new.party_id));
  end if;
  return new;
end;
$$;
create trigger party_members_notify after insert on public.party_members
  for each row execute function public._notify_party_member();

create or replace function public._notify_plan_guest()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_host uuid := (select host_id from public.plans where id = new.plan_id);
begin
  if tg_op = 'INSERT' and new.user_id is not null and new.rsvp = 'invited' then
    perform public._notify(new.user_id, 'plan_invite', new.invited_by, null, new.plan_id,
                           (select place_id from public.plans where id = new.plan_id));
  elsif tg_op = 'UPDATE' and new.rsvp is distinct from old.rsvp then
    perform public._notify(v_host, 'plan_rsvp', new.user_id, null, new.plan_id, null,
                           jsonb_build_object('rsvp', new.rsvp, 'guest_name', new.guest_name));
  elsif tg_op = 'INSERT' and new.rsvp <> 'invited' and new.user_id is distinct from v_host then
    perform public._notify(v_host, 'plan_rsvp', new.user_id, null, new.plan_id, null,
                           jsonb_build_object('rsvp', new.rsvp, 'guest_name', new.guest_name));
  end if;
  return new;
end;
$$;
create trigger plan_guests_notify after insert or update on public.plan_guests
  for each row execute function public._notify_plan_guest();

-- When a meal is posted: tell followers who saved that place ("Maya just went to Kinkaku: 8.7"),
-- and when the whole party has rated, send everyone the Table Verdict.
create or replace function public._notify_meal_posted()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_place_name text := (select name from public.places where id = new.place_id);
begin
  if new.status = 'posted' and old.status is distinct from 'posted' and new.visibility = 'followers' then
    insert into public.notifications (user_id, kind, actor_id, meal_id, place_id, payload)
    select s.user_id, 'friend_went', new.user_id, new.id, new.place_id,
           jsonb_build_object('place_name', v_place_name, 'score', new.score_at_post)
    from public.saves s
    join public.follows f on f.follower_id = s.user_id and f.followee_id = new.user_id and f.status = 'accepted'
    where s.place_id = new.place_id and s.user_id <> new.user_id
      and not public.is_blocked_between(s.user_id, new.user_id);

    if new.party_id is not null and not exists (
      select 1 from public.meals m
      where m.party_id = new.party_id and m.status <> 'posted' and m.id <> new.id
    ) and (select count(*) from public.meals m where m.party_id = new.party_id) >= 2 then
      insert into public.notifications (user_id, kind, meal_id, place_id, payload)
      select m.user_id, 'table_verdict', m.id, new.place_id,
             jsonb_build_object('party_id', new.party_id, 'place_name', v_place_name)
      from public.meals m where m.party_id = new.party_id;
    end if;
  end if;
  return new;
end;
$$;
create trigger meals_notify_posted after update of status on public.meals
  for each row execute function public._notify_meal_posted();

create or replace function public._notify_decide_match()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'matched' and old.status = 'open' then
    insert into public.notifications (user_id, kind, place_id, payload)
    select dp.user_id, 'decide_match', new.matched_place_id,
           jsonb_build_object('session_id', new.id, 'place_name', (select name from public.places where id = new.matched_place_id))
    from public.decide_participants dp
    where dp.session_id = new.id and dp.user_id is not null;
  end if;
  return new;
end;
$$;
create trigger decide_sessions_notify after update of status on public.decide_sessions
  for each row execute function public._notify_decide_match();
