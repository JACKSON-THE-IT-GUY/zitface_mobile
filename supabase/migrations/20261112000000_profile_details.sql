begin;

alter table public.profiles
  add column if not exists program text not null default '',
  add column if not exists year_of_study text not null default '',
  add column if not exists interests text not null default '',
  add column if not exists website text not null default '';

grant update (program, year_of_study, interests, website)
  on public.profiles to authenticated;

commit;