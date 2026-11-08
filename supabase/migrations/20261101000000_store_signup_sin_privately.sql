begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table private.member_identity (
  user_id uuid primary key references auth.users (id) on delete cascade,
  sin_number text not null check (length(trim(sin_number)) between 1 and 64),
  created_at timestamptz not null default now()
);

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

  insert into private.member_identity (user_id, sin_number)
  values (
    new.id,
    nullif(trim(new.raw_user_meta_data ->> 'sin_number'), '')
  );

  return new;
end;
$$;

commit;