-- TWG27unlocked: separate anonymous intention poll and optional academic JOIN profile.
-- Counters only; no individual submissions or timestamps are retained.

create table if not exists public.student_intention_counts (
  intention text primary key check (intention in ('I will apply', 'I''m interested', 'Not decided yet')),
  response_count bigint not null default 0 check (response_count >= 0)
);
alter table public.student_intention_counts enable row level security;
drop policy if exists "Admins can read intention counts" on public.student_intention_counts;
create policy "Admins can read intention counts" on public.student_intention_counts
for select to authenticated using (public.is_admin());
revoke all on public.student_intention_counts from anon, authenticated;
grant select on public.student_intention_counts to authenticated;

create table if not exists public.student_profile_counts (
  university text not null,
  specialization text not null,
  study_year text not null,
  response_count bigint not null default 0 check (response_count >= 0),
  primary key (university, specialization, study_year)
);
alter table public.student_profile_counts enable row level security;
drop policy if exists "Admins can read profile counts" on public.student_profile_counts;
create policy "Admins can read profile counts" on public.student_profile_counts
for select to authenticated using (public.is_admin());
revoke all on public.student_profile_counts from anon, authenticated;
grant select on public.student_profile_counts to authenticated;

create or replace function public.record_student_intention(p_intention text)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if p_intention not in ('I will apply', 'I''m interested', 'Not decided yet') then
    raise exception 'Invalid intention';
  end if;
  insert into public.student_intention_counts(intention,response_count)
  values(p_intention,1)
  on conflict (intention) do update
  set response_count = public.student_intention_counts.response_count + 1;
end;
$$;
revoke all on function public.record_student_intention(text) from public;
grant execute on function public.record_student_intention(text) to anon, authenticated;

create or replace function public.submit_student_profile(
  p_university text, p_specialization text, p_year text
)
returns void language plpgsql security definer set search_path = ''
as $$
declare v_university text := nullif(btrim(p_university),'');
begin
  if v_university is null or length(v_university)>100 then raise exception 'Invalid university'; end if;
  if p_specialization not in (
    'Prelucrare Petrol și Petrochimie','Inginerie Electrică','Electrotehnică',
    'Mecanică','Energetică','Energetică Industrială','Electromecanică',
    'Automatizări','Construcții Civile','Inginerie Chimică'
  ) then raise exception 'Invalid specialization'; end if;
  if p_year not in ('Year I','Year II','Year III','Year IV','Year V','Year VI','Master I','Master II','PhD')
    then raise exception 'Invalid study year'; end if;
  insert into public.student_profile_counts(university,specialization,study_year,response_count)
  values(v_university,p_specialization,p_year,1)
  on conflict (university,specialization,study_year) do update
  set response_count = public.student_profile_counts.response_count + 1;
end;
$$;
revoke all on function public.submit_student_profile(text,text,text) from public;
grant execute on function public.submit_student_profile(text,text,text) to anon, authenticated;
