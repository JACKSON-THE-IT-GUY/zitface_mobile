begin;

alter table public.stories
  add column if not exists audio_path text,
  add column if not exists audio_content_type text,
  add column if not exists audio_rights_confirmed boolean not null default false;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.stories'::regclass
      and conname = 'stories_audio_rights_check'
  ) then
    alter table public.stories
      add constraint stories_audio_rights_check
      check (
        (
          audio_path is null
          and audio_content_type is null
          and not audio_rights_confirmed
        )
        or (
          audio_path is not null
          and audio_content_type in (
            'audio/mpeg',
            'audio/mp4',
            'audio/aac',
            'audio/wav',
            'audio/ogg'
          )
          and audio_rights_confirmed
        )
      );
  end if;
end;
$$;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'story-audio',
  'story-audio',
  false,
  10485760,
  array[
    'audio/mpeg',
    'audio/mp4',
    'audio/aac',
    'audio/wav',
    'audio/ogg'
  ]
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "Members can view audio for visible stories"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'story-audio'
    and exists (
      select 1
      from public.stories story
      where story.audio_path = name
        and story.expires_at > now()
    )
  );

create policy "Authors can upload their story audio"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'story-audio'
    and exists (
      select 1
      from public.stories story
      where story.audio_path = name
        and story.author_id = (select auth.uid())
        and story.audio_rights_confirmed
    )
  );

create policy "Authors can delete their story audio"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'story-audio'
    and exists (
      select 1
      from public.stories story
      where story.audio_path = name
        and story.author_id = (select auth.uid())
    )
  );

commit;