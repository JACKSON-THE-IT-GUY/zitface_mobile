begin;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'avatars',
  'avatars',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Anyone can view profile avatars" on storage.objects;
drop policy if exists "Members can view visible profile avatars"
  on storage.objects;

create policy "Members can view visible profile avatars"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'avatars'
    and exists (
      select 1
      from public.profiles profile
      where profile.id::text = (storage.foldername(name))[1]
        and (
          profile.id = (select auth.uid())
          or not profile.is_private
          or (select public.is_friend(profile.id))
        )
    )
  );

commit;