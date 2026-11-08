begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists private.member_identity (
  user_id uuid primary key references auth.users (id) on delete cascade,
  sin_number text not null check (length(trim(sin_number)) between 1 and 64),
  created_at timestamptz not null default now()
);

alter table private.member_identity enable row level security;
revoke all on table private.member_identity from public, anon, authenticated;

insert into private.member_identity (user_id, sin_number)
select id, trim(raw_user_meta_data ->> 'sin_number')
from auth.users
where nullif(trim(raw_user_meta_data ->> 'sin_number'), '') is not null
on conflict (user_id) do update
set sin_number = excluded.sin_number;

update auth.users
set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) - 'sin_number'
where raw_user_meta_data ? 'sin_number';

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

create or replace function public.has_my_sin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from private.member_identity
      where user_id = auth.uid()
    );
$$;

create or replace function public.save_my_sin(p_sin_number text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_sin text := nullif(trim(p_sin_number), '');
begin
  if current_user_id is null then
    raise exception 'Sign in before saving your SIN.';
  end if;
  if normalized_sin is null or length(normalized_sin) > 64 then
    raise exception 'Enter a valid SIN number.';
  end if;

  insert into private.member_identity (user_id, sin_number)
  values (current_user_id, normalized_sin)
  on conflict (user_id) do update
  set sin_number = excluded.sin_number;
end;
$$;

revoke all on function public.has_my_sin() from public, anon, authenticated;
revoke all on function public.save_my_sin(text) from public, anon, authenticated;
grant execute on function public.has_my_sin() to authenticated;
grant execute on function public.save_my_sin(text) to authenticated;

commit;