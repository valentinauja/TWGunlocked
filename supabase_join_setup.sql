-- TWG27unlocked JOIN: aggregate-only student interest counters
-- Run this migration in Supabase SQL Editor.
-- No individual response rows, names, contact details, or response timestamps are stored.

create table if not exists public.student_interest_counts (
  university text not null,
  study_field text not null,
  study_year text not null,
  intention text not null,
  response_count bigint not null default 0 check (response_count >= 0),
  primary key (university, study_field, study_year, intention)
);

alter table public.student_interest_counts enable row level security;

drop policy if exists "Admins can read student interest counts" on public.student_interest_counts;
create policy "Admins can read student interest counts"
on public.student_interest_counts
for select
to authenticated
using (public.is_admin());

revoke all on public.student_interest_counts from anon, authenticated;
grant select on public.student_interest_counts to authenticated;

create or replace view public.student_interest_totals
with (security_invoker = true)
as
select university, study_field, study_year, intention, response_count
from public.student_interest_counts;

grant select on public.student_interest_totals to authenticated;

create or replace function public.submit_student_interest(
  p_university text,
  p_field text,
  p_year text,
  p_intention text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_university text := nullif(btrim(p_university), '');
begin
  if v_university is null or length(v_university) > 100 then
    raise exception 'Invalid university selection';
  end if;

  if p_field not in (
    'Engineering & Technology', 'Economics & Business',
    'Science & Mathematics', 'IT & Computer Science',
    'Law & Public Administration',
    'Social Sciences & Communication',
    'Humanities & Languages', 'Other / Not listed'
  ) then
    raise exception 'Invalid field of study';
  end if;

  if p_year not in (
    'Year I', 'Year II', 'Year III', 'Year IV', 'Year V',
    'Year VI', 'Master I', 'Master II', 'PhD'
  ) then
    raise exception 'Invalid study year';
  end if;

  if p_intention not in ('I will apply', 'I am interested', 'I am undecided') then
    raise exception 'Invalid intention';
  end if;

  insert into public.student_interest_counts
    (university, study_field, study_year, intention, response_count)
  values
    (v_university, p_field, p_year, p_intention, 1)
  on conflict (university, study_field, study_year, intention)
  do update set response_count = public.student_interest_counts.response_count + 1;
end;
$$;

revoke all on function public.submit_student_interest(text, text, text, text) from public;
grant execute on function public.submit_student_interest(text, text, text, text) to anon, authenticated;
