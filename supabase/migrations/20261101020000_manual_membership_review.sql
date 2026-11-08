begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists private.member_identity (
  user_id uuid primary key references auth.users (id) on delete cascade,
  member_type text not null default 'student',
  member_number text,
  status text not null default 'pending',
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table private.member_identity
  add column if not exists member_type text not null default 'student',
  add column if not exists member_number text,
  add column if not exists status text not null default 'pending',
  add column if not exists submitted_at timestamptz not null default now(),
  add column if not exists reviewed_at timestamptz;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'private'
      and table_name = 'member_identity'
      and column_name = 'sin_number'
  ) then
    execute $migration$
      update private.member_identity
      set member_number = coalesce(
        nullif(trim(member_number), ''),
        nullif(trim(sin_number), '')
      )
      where member_number is null
    $migration$;
    execute 'alter table private.member_identity drop column sin_number';
  end if;
end;
$$;

insert into private.member_identity as existing (
  user_id,
  member_type,
  member_number,
  status
)
select
  id,
  'student',
  nullif(trim(raw_user_meta_data ->> 'sin_number'), ''),
  'pending'
from auth.users
where nullif(trim(raw_user_meta_data ->> 'sin_number'), '') is not null
on conflict (user_id) do update
set member_number = coalesce(
  existing.member_number,
  excluded.member_number
);

update auth.users
set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) - 'sin_number'
where raw_user_meta_data ? 'sin_number';

alter table private.member_identity
  alter column member_number set not null;

alter table private.member_identity
  add constraint member_identity_type_check
    check (member_type in ('student', 'staff')),
  add constraint member_identity_status_check
    check (status in ('pending', 'approved', 'rejected')),
  add constraint member_identity_number_check
    check (length(trim(member_number)) between 1 and 64);

create index member_identity_status_submitted_idx
  on private.member_identity (status, submitted_at);

alter table private.member_identity enable row level security;
revoke all on table private.member_identity from public, anon, authenticated;

create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, handle)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      'New member'
    ),
    'u_' || substring(replace(new.id::text, '-', '') from 1 for 28)
  );
  return new;
end;
$$;

drop function if exists public.has_my_sin();
drop function if exists public.save_my_sin(text);

create or replace function public.get_my_membership_status()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select status
  from private.member_identity
  where user_id = auth.uid();
$$;

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

revoke all on function public.get_my_membership_status()
  from public, anon, authenticated;
revoke all on function public.submit_my_membership_application(text, text)
  from public, anon, authenticated;
grant execute on function public.get_my_membership_status() to authenticated;
grant execute on function public.submit_my_membership_application(text, text)
  to authenticated;

commit;