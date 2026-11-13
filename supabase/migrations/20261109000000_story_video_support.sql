begin;

alter table public.stories
  add column if not exists duration_seconds integer;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.stories'::regclass
      and conname = 'stories_media_duration_check'
  ) then
    alter table public.stories
      add constraint stories_media_duration_check
      check (
        (media_type = 'image' and duration_seconds is null)
        or (media_type = 'video' and duration_seconds between 1 and 60)
      );
  end if;
end;
$$;

update storage.buckets
set file_size_limit = 52428800,
    allowed_mime_types = array[
      'image/jpeg',
      'image/png',
      'image/webp',
      'video/mp4',
      'video/quicktime'
    ]
where id = 'story-media';

commit;