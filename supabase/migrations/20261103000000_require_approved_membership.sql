begin;

create or replace function public.has_approved_membership()
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
        and status = 'approved'
    );
$$;

revoke all on function public.has_approved_membership()
  from public, anon, authenticated;
grant execute on function public.has_approved_membership() to authenticated;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'profiles',
    'friend_requests',
    'follows',
    'posts',
    'post_media',
    'comments',
    'reactions',
    'stories',
    'story_views',
    'conversations',
    'conversation_members',
    'messages',
    'notifications',
    'academic_cohorts',
    'campus_groups',
    'group_members'
  ]
  loop
    execute format(
      'create policy %I on public.%I as restrictive for all to authenticated using (public.has_approved_membership()) with check (public.has_approved_membership())',
      'Approved membership required',
      table_name
    );
  end loop;
end;
$$;

commit;