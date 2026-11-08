create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default 'New member',
  handle text not null unique,
  bio text not null default '',
  avatar_url text,
  school text not null default '',
  is_private boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_handle_format check (handle ~ '^[a-z0-9_]{3,30}$')
);

create table public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles (id) on delete cascade,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint friend_requests_distinct_users check (sender_id <> recipient_id),
  constraint friend_requests_status check (
    status in ('pending', 'accepted', 'declined')
  )
);

create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  following_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint follows_distinct_users check (follower_id <> following_id)
);

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  body text not null default '',
  visibility text not null default 'friends',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint posts_visibility check (
    visibility in ('public', 'friends', 'private')
  )
);

create table public.post_media (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  storage_path text not null unique,
  media_type text not null,
  content_type text not null,
  width integer,
  height integer,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  constraint post_media_type check (media_type in ('image', 'video')),
  constraint post_media_dimensions check (
    (width is null or width > 0) and (height is null or height > 0)
  ),
  constraint post_media_position check (position >= 0)
);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint comments_body_not_empty check (length(trim(body)) > 0)
);

create table public.reactions (
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  reaction_type text not null default 'like',
  created_at timestamptz not null default now(),
  primary key (post_id, user_id),
  constraint reactions_type check (
    reaction_type in ('like', 'love', 'haha', 'wow', 'sad', 'angry')
  )
);

create table public.stories (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  storage_path text not null unique,
  media_type text not null,
  caption text not null default '',
  visibility text not null default 'friends',
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '24 hours',
  constraint stories_media_type check (media_type in ('image', 'video')),
  constraint stories_visibility check (visibility in ('public', 'friends')),
  constraint stories_expiry check (expires_at > created_at)
);

create table public.story_views (
  story_id uuid not null references public.stories (id) on delete cascade,
  viewer_id uuid not null references public.profiles (id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (story_id, viewer_id)
);

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles (id) on delete cascade,
  conversation_type text not null default 'direct',
  title text,
  created_at timestamptz not null default now(),
  constraint conversations_type check (
    conversation_type in ('direct', 'group')
  )
);

create table public.conversation_members (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create function public.add_conversation_creator()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.conversation_members (conversation_id, user_id)
  values (new.id, new.created_by);
  return new;
end;
$$;

create trigger conversations_add_creator
  after insert on public.conversations
  for each row execute function public.add_conversation_creator();

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  constraint messages_body_not_empty check (length(trim(body)) > 0)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  actor_id uuid references public.profiles (id) on delete set null,
  notification_type text not null,
  entity_type text,
  entity_id uuid,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.academic_cohorts (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles (id) on delete cascade,
  school text not null,
  program text not null,
  academic_year integer not null,
  class_rep_name text not null,
  created_at timestamptz not null default now(),
  constraint academic_cohorts_school_not_empty check (length(trim(school)) > 0),
  constraint academic_cohorts_program_not_empty check (length(trim(program)) > 0),
  constraint academic_cohorts_year check (academic_year between 1 and 10),
  constraint academic_cohorts_rep_not_empty check (
    length(trim(class_rep_name)) > 0
  )
);

create table public.campus_groups (
  id uuid primary key default gen_random_uuid(),
  cohort_id uuid not null references public.academic_cohorts (id) on delete cascade,
  name text not null,
  group_type text not null,
  created_at timestamptz not null default now(),
  constraint campus_groups_name_not_empty check (length(trim(name)) > 0),
  constraint campus_groups_type check (
    group_type in (
      'Program group (data group)',
      'Class group',
      'Study group',
      'Lecture group',
      'Tutorial group'
    )
  ),
  constraint campus_groups_one_type_per_cohort unique (cohort_id, group_type)
);

create table public.group_members (
  group_id uuid not null references public.campus_groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create function public.create_academic_cohort(
  p_school text,
  p_program text,
  p_academic_year integer,
  p_class_rep_name text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  cohort_id uuid;
  year_label text;
begin
  if auth.uid() is null then
    raise exception 'Sign in to create an academic cohort.';
  end if;

  insert into public.academic_cohorts (
    created_by,
    school,
    program,
    academic_year,
    class_rep_name
  )
  values (
    auth.uid(),
    trim(p_school),
    trim(p_program),
    p_academic_year,
    trim(p_class_rep_name)
  )
  returning id into cohort_id;

  year_label := 'Year ' || p_academic_year::text;
  insert into public.campus_groups (cohort_id, name, group_type)
  values
    (
      cohort_id,
      trim(p_program) || ' ' || year_label || ' Program Group',
      'Program group (data group)'
    ),
    (cohort_id, trim(p_program) || ' ' || year_label || ' Class Group', 'Class group'),
    (cohort_id, trim(p_program) || ' ' || year_label || ' Study Group', 'Study group'),
    (
      cohort_id,
      trim(p_program) || ' ' || year_label || ' Lecture Group',
      'Lecture group'
    ),
    (
      cohort_id,
      trim(p_program) || ' ' || year_label || ' Tutorial Group',
      'Tutorial group'
    );

  return cohort_id;
end;
$$;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = excluded.public;

create policy "Anyone can view profile avatars"
  on storage.objects for select to public
  using (bucket_id = 'avatars');
create policy "Users can upload their own profile avatar"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "Users can update their own profile avatar"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "Users can delete their own profile avatar"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create index friend_requests_recipient_status_idx
  on public.friend_requests (recipient_id, status, created_at desc);
create unique index friend_requests_one_pending_per_pair_idx
  on public.friend_requests (
    least(sender_id, recipient_id),
    greatest(sender_id, recipient_id)
  )
  where status = 'pending';
create index follows_following_created_idx
  on public.follows (following_id, created_at desc);
create index posts_author_created_idx
  on public.posts (author_id, created_at desc);
create index posts_created_idx
  on public.posts (created_at desc);
create index post_media_post_position_idx
  on public.post_media (post_id, position);
create index comments_post_created_idx
  on public.comments (post_id, created_at);
create index reactions_user_created_idx
  on public.reactions (user_id, created_at desc);
create index stories_author_expiry_idx
  on public.stories (author_id, expires_at desc);
create index story_views_viewer_idx
  on public.story_views (viewer_id, viewed_at desc);
create index conversation_members_user_idx
  on public.conversation_members (user_id, joined_at desc);
create index messages_conversation_created_idx
  on public.messages (conversation_id, created_at desc);
create index notifications_recipient_created_idx
  on public.notifications (recipient_id, created_at desc);
create index academic_cohorts_created_idx
  on public.academic_cohorts (created_at desc);
create index campus_groups_cohort_idx
  on public.campus_groups (cohort_id, created_at);
create index group_members_user_idx
  on public.group_members (user_id, joined_at desc);

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger friend_requests_set_updated_at
  before update on public.friend_requests
  for each row execute function public.set_updated_at();
create trigger posts_set_updated_at
  before update on public.posts
  for each row execute function public.set_updated_at();
create trigger comments_set_updated_at
  before update on public.comments
  for each row execute function public.set_updated_at();

create function public.create_profile_for_new_user()
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

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.create_profile_for_new_user();

create function public.is_friend(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from public.friend_requests request
      where request.status = 'accepted'
        and (
          (request.sender_id = auth.uid() and request.recipient_id = target_user_id)
          or
          (request.recipient_id = auth.uid() and request.sender_id = target_user_id)
        )
    );
$$;

create function public.has_pending_friend_request(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from public.friend_requests request
      where request.status = 'pending'
        and (
          (request.sender_id = auth.uid() and request.recipient_id = target_user_id)
          or
          (request.recipient_id = auth.uid() and request.sender_id = target_user_id)
        )
    );
$$;

create function public.is_conversation_member(target_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from public.conversation_members member
      where member.conversation_id = target_conversation_id
        and member.user_id = auth.uid()
    );
$$;

alter table public.profiles enable row level security;
alter table public.friend_requests enable row level security;
alter table public.follows enable row level security;
alter table public.posts enable row level security;
alter table public.post_media enable row level security;
alter table public.comments enable row level security;
alter table public.reactions enable row level security;
alter table public.stories enable row level security;
alter table public.story_views enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.academic_cohorts enable row level security;
alter table public.campus_groups enable row level security;
alter table public.group_members enable row level security;

revoke all on table
  public.profiles,
  public.friend_requests,
  public.follows,
  public.posts,
  public.post_media,
  public.comments,
  public.reactions,
  public.stories,
  public.story_views,
  public.conversations,
  public.conversation_members,
  public.messages,
  public.notifications,
  public.academic_cohorts,
  public.campus_groups,
  public.group_members
from anon, authenticated;
revoke all on function public.is_friend(uuid) from public, anon;
revoke all on function public.has_pending_friend_request(uuid) from public, anon;
revoke all on function public.is_conversation_member(uuid) from public, anon;
revoke all on function public.create_academic_cohort(text, text, integer, text)
  from public, anon;
grant usage on schema public to authenticated;

grant select, update (
  display_name,
  handle,
  bio,
  avatar_url,
  school,
  is_private
) on public.profiles to authenticated;
grant select, insert (sender_id, recipient_id), update (status), delete
  on public.friend_requests to authenticated;
grant select, insert (follower_id, following_id), delete
  on public.follows to authenticated;
grant select, insert (author_id, body, visibility), update (body, visibility),
  delete on public.posts to authenticated;
grant select, insert (
  post_id,
  storage_path,
  media_type,
  content_type,
  width,
  height,
  position
), update (
  storage_path,
  media_type,
  content_type,
  width,
  height,
  position
), delete on public.post_media to authenticated;
grant select, insert (post_id, author_id, body), update (body), delete
  on public.comments to authenticated;
grant select, insert (post_id, user_id, reaction_type), delete
  on public.reactions to authenticated;
grant select, insert (author_id, storage_path, media_type, caption, visibility),
  delete on public.stories to authenticated;
grant select, insert (story_id, viewer_id) on public.story_views to authenticated;
grant select, insert (created_by, conversation_type, title)
  on public.conversations to authenticated;
grant select, insert (conversation_id, user_id), delete
  on public.conversation_members to authenticated;
grant select, insert (conversation_id, sender_id, body), delete
  on public.messages to authenticated;
grant select, update (read_at) on public.notifications to authenticated;
grant select on public.academic_cohorts, public.campus_groups to authenticated;
grant select, insert (group_id, user_id), delete
  on public.group_members to authenticated;
grant execute on function public.is_friend(uuid) to authenticated;
grant execute on function public.has_pending_friend_request(uuid) to authenticated;
grant execute on function public.is_conversation_member(uuid) to authenticated;
grant execute on function public.create_academic_cohort(text, text, integer, text)
  to authenticated;

create policy "Users can read visible profiles"
  on public.profiles for select to authenticated
  using (
    id = (select auth.uid())
    or not is_private
    or (select public.is_friend(id))
  );
create policy "Users can update their own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "Users can read their friend requests"
  on public.friend_requests for select to authenticated
  using (
    sender_id = (select auth.uid())
    or recipient_id = (select auth.uid())
  );
create policy "Users can send friend requests"
  on public.friend_requests for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and sender_id <> recipient_id
    and status = 'pending'
    and not (select public.is_friend(recipient_id))
    and not (select public.has_pending_friend_request(recipient_id))
  );
create policy "Recipients can respond to pending requests"
  on public.friend_requests for update to authenticated
  using (
    recipient_id = (select auth.uid())
    and status = 'pending'
  )
  with check (
    recipient_id = (select auth.uid())
    and status in ('accepted', 'declined')
  );
create policy "Senders can cancel pending requests"
  on public.friend_requests for delete to authenticated
  using (
    sender_id = (select auth.uid())
    and status = 'pending'
  );

create policy "Users can read their follows"
  on public.follows for select to authenticated
  using (
    follower_id = (select auth.uid())
    or following_id = (select auth.uid())
  );
create policy "Users can follow other profiles"
  on public.follows for insert to authenticated
  with check (
    follower_id = (select auth.uid())
    and follower_id <> following_id
  );
create policy "Users can unfollow profiles"
  on public.follows for delete to authenticated
  using (follower_id = (select auth.uid()));

create policy "Users can read visible posts"
  on public.posts for select to authenticated
  using (
    author_id = (select auth.uid())
    or (
      visibility = 'public'
      and exists (
        select 1
        from public.profiles profile
        where profile.id = posts.author_id
          and not profile.is_private
      )
    )
    or (
      visibility in ('public', 'friends')
      and (select public.is_friend(author_id))
    )
  );
create policy "Users can create their own posts"
  on public.posts for insert to authenticated
  with check (author_id = (select auth.uid()));
create policy "Users can update their own posts"
  on public.posts for update to authenticated
  using (author_id = (select auth.uid()))
  with check (author_id = (select auth.uid()));
create policy "Users can delete their own posts"
  on public.posts for delete to authenticated
  using (author_id = (select auth.uid()));

create policy "Users can read media for visible posts"
  on public.post_media for select to authenticated
  using (
    exists (
      select 1 from public.posts post
      where post.id = post_media.post_id
    )
  );
create policy "Authors can attach media to their posts"
  on public.post_media for insert to authenticated
  with check (
    exists (
      select 1 from public.posts post
      where post.id = post_media.post_id
        and post.author_id = (select auth.uid())
    )
  );
create policy "Authors can update media on their posts"
  on public.post_media for update to authenticated
  using (
    exists (
      select 1 from public.posts post
      where post.id = post_media.post_id
        and post.author_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.posts post
      where post.id = post_media.post_id
        and post.author_id = (select auth.uid())
    )
  );
create policy "Authors can delete media on their posts"
  on public.post_media for delete to authenticated
  using (
    exists (
      select 1 from public.posts post
      where post.id = post_media.post_id
        and post.author_id = (select auth.uid())
    )
  );

create policy "Users can read comments on visible posts"
  on public.comments for select to authenticated
  using (
    exists (
      select 1 from public.posts post
      where post.id = comments.post_id
    )
  );
create policy "Users can comment on visible posts"
  on public.comments for insert to authenticated
  with check (
    author_id = (select auth.uid())
    and exists (
      select 1 from public.posts post
      where post.id = comments.post_id
    )
  );
create policy "Users can update their own comments"
  on public.comments for update to authenticated
  using (author_id = (select auth.uid()))
  with check (author_id = (select auth.uid()));
create policy "Users can delete their own comments"
  on public.comments for delete to authenticated
  using (author_id = (select auth.uid()));

create policy "Users can read reactions on visible posts"
  on public.reactions for select to authenticated
  using (
    exists (
      select 1 from public.posts post
      where post.id = reactions.post_id
    )
  );
create policy "Users can react to visible posts"
  on public.reactions for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.posts post
      where post.id = reactions.post_id
    )
  );
create policy "Users can remove their own reactions"
  on public.reactions for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "Users can read visible unexpired stories"
  on public.stories for select to authenticated
  using (
    expires_at > now()
    and (
      author_id = (select auth.uid())
      or (
        visibility = 'public'
        and exists (
          select 1
          from public.profiles profile
          where profile.id = stories.author_id
            and not profile.is_private
        )
      )
      or (
        visibility in ('public', 'friends')
        and (select public.is_friend(author_id))
      )
    )
  );
create policy "Users can create their own stories"
  on public.stories for insert to authenticated
  with check (author_id = (select auth.uid()));
create policy "Users can delete their own stories"
  on public.stories for delete to authenticated
  using (author_id = (select auth.uid()));

create policy "Users can read story views they are allowed to see"
  on public.story_views for select to authenticated
  using (
    viewer_id = (select auth.uid())
    or exists (
      select 1
      from public.stories story
      where story.id = story_views.story_id
        and story.author_id = (select auth.uid())
    )
  );
create policy "Users can record their own story views"
  on public.story_views for insert to authenticated
  with check (
    viewer_id = (select auth.uid())
    and exists (
      select 1
      from public.stories story
      where story.id = story_views.story_id
    )
  );

create policy "Users can read their conversations"
  on public.conversations for select to authenticated
  using (
    created_by = (select auth.uid())
    or (select public.is_conversation_member(id))
  );
create policy "Users can create conversations"
  on public.conversations for insert to authenticated
  with check (created_by = (select auth.uid()));

create policy "Members can read conversation membership"
  on public.conversation_members for select to authenticated
  using (
    user_id = (select auth.uid())
    or (select public.is_conversation_member(conversation_id))
  );
create policy "Members or creators can add conversation members"
  on public.conversation_members for insert to authenticated
  with check (
    exists (
      select 1
      from public.conversations conversation
      where conversation.id = conversation_members.conversation_id
        and (
          conversation.created_by = (select auth.uid())
          or (select public.is_conversation_member(conversation.id))
        )
    )
  );
create policy "Users can leave conversations or creators can remove members"
  on public.conversation_members for delete to authenticated
  using (
    user_id = (select auth.uid())
    or exists (
      select 1
      from public.conversations conversation
      where conversation.id = conversation_members.conversation_id
        and conversation.created_by = (select auth.uid())
    )
  );

create policy "Conversation members can read messages"
  on public.messages for select to authenticated
  using ((select public.is_conversation_member(conversation_id)));
create policy "Members can send messages as themselves"
  on public.messages for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and (select public.is_conversation_member(conversation_id))
  );
create policy "Senders can delete their own messages"
  on public.messages for delete to authenticated
  using (
    sender_id = (select auth.uid())
    and (select public.is_conversation_member(conversation_id))
  );

create policy "Users can read their notifications"
  on public.notifications for select to authenticated
  using (recipient_id = (select auth.uid()));
create policy "Users can mark their notifications read"
  on public.notifications for update to authenticated
  using (recipient_id = (select auth.uid()))
  with check (recipient_id = (select auth.uid()));

create policy "Authenticated users can read academic cohorts"
  on public.academic_cohorts for select to authenticated
  using (true);
create policy "Authenticated users can read campus groups"
  on public.campus_groups for select to authenticated
  using (true);
create policy "Users can read their group memberships"
  on public.group_members for select to authenticated
  using (user_id = (select auth.uid()));
create policy "Users can join groups as themselves"
  on public.group_members for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "Users can leave their groups"
  on public.group_members for delete to authenticated
  using (user_id = (select auth.uid()));
