-- BigBack · 0006b · plan_by_code (applied separately)

create or replace function public.plan_by_code(p_code text)
returns public.plans
language sql
stable
security definer
set search_path = ''
as $$
  select * from public.plans where invite_code = p_code and status <> 'cancelled';
$$;

-- Let's eat: build a group stack of 8 candidates that suit everyone ("nobody miserable").
