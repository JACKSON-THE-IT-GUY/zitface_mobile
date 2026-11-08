begin;

update private.member_identity
set status = 'rejected',
    reviewed_at = coalesce(reviewed_at, now())
where member_type = 'student'
  and member_number !~ '^(19|2[0-7])[0-9]{6}$'
  and status <> 'rejected';

alter table private.member_identity
  add constraint member_identity_student_sin_format_check
  check (
    member_type <> 'student'
    or status = 'rejected'
    or member_number ~ '^(19|2[0-7])[0-9]{6}$'
  );

create or replace function public.submit_my_membership_application(
  p_member_type text,
  p_member_number text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_number text := nullif(trim(p_member_number), '');
  application_status text;
begin
  if current_user_id is null then
    raise exception 'Sign in before submitting a membership application.';
  end if;
  if p_member_type is null or p_member_type not in ('student', 'staff') then
    raise exception 'Choose Student or Lecturer / Staff.';
  end if;
  if normalized_number is null or length(normalized_number) > 64 then
    raise exception 'Enter a valid university ID number.';
  end if;
  if p_member_type = 'student'
    and normalized_number !~ '^(19|2[0-7])[0-9]{6}$' then
    raise exception
      'Student SIN must be 8 digits, with a year prefix from 19 to 27.';
  end if;

  insert into private.member_identity as existing (
    user_id,
    member_type,
    member_number,
    status,
    submitted_at,
    reviewed_at
  )
  values (
    current_user_id,
    p_member_type,
    normalized_number,
    'pending',
    now(),
    null
  )
  on conflict (user_id) do update
  set member_type = excluded.member_type,
      member_number = excluded.member_number,
      status = 'pending',
      submitted_at = now(),
      reviewed_at = null
  where existing.status = 'rejected'
  returning status into application_status;

  if application_status is null then
    select status into application_status
    from private.member_identity
    where user_id = current_user_id;

    if application_status = 'pending' then
      raise exception 'Your membership application is already pending review.';
    elsif application_status = 'approved' then
      raise exception 'Your membership application is already approved.';
    else
      raise exception 'Could not submit the membership application.';
    end if;
  end if;

  return application_status;
end;
$$;

commit;