begin;

create or replace function public.open_direct_conversation(p_peer_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
  conversation_id uuid;
begin
  if current_user_id is null then
    raise exception 'Sign in before starting a conversation.';
  end if;
  if p_peer_id is null or p_peer_id = current_user_id then
    raise exception 'Choose another member to message.';
  end if;
  if not public.has_approved_membership() then
    raise exception 'An approved membership is required to message.';
  end if;
  if not exists (
    select 1
    from private.member_identity
    where user_id = p_peer_id
      and status = 'approved'
  ) then
    raise exception 'The selected member is not available for messaging.';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      least(current_user_id::text, p_peer_id::text)
        || ':' || greatest(current_user_id::text, p_peer_id::text),
      0
    )
  );

  select conversation.id into conversation_id
  from public.conversations conversation
  where conversation.conversation_type = 'direct'
    and (select count(*)
      from public.conversation_members member
      where member.conversation_id = conversation.id) = 2
    and exists (
      select 1 from public.conversation_members member
      where member.conversation_id = conversation.id
        and member.user_id = current_user_id
    )
    and exists (
      select 1 from public.conversation_members member
      where member.conversation_id = conversation.id
        and member.user_id = p_peer_id
    )
  limit 1;

  if conversation_id is not null then
    return conversation_id;
  end if;

  insert into public.conversations (created_by, conversation_type)
  values (current_user_id, 'direct')
  returning id into conversation_id;

  insert into public.conversation_members (conversation_id, user_id)
  values (conversation_id, p_peer_id);

  return conversation_id;
end;
$$;

revoke all on function public.open_direct_conversation(uuid)
  from public, anon, authenticated;
grant execute on function public.open_direct_conversation(uuid)
  to authenticated;

do $$
begin
  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end;
$$;

commit;