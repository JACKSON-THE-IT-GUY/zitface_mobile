begin;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'story-media',
  'story-media',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "Members can view media for visible stories"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'story-media'
    and exists (
      select 1
      from public.stories story
      where story.storage_path = name
        and story.expires_at > now()
    )
  );

create policy "Authors can upload their story media"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'story-media'
    and exists (
      select 1
      from public.stories story
      where story.storage_path = name
        and story.author_id = (select auth.uid())
    )
  );

create policy "Authors can delete their story media"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'story-media'
    and exists (
      select 1
      from public.stories story
      where story.storage_path = name
        and story.author_id = (select auth.uid())
    )
  );

commit;