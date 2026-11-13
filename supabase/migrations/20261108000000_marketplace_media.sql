begin;

alter table public.market_listings add column image_path text;
grant insert (image_path) on public.market_listings to authenticated;

alter table public.market_listings add constraint market_listing_image_owner
  check (image_path is null or split_part(image_path, '/', 1) = seller_id::text);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('market-media', 'market-media', false, 10485760,
        array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "Members can view visible listing images"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'market-media'
    and public.has_approved_membership()
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or exists (
        select 1 from public.market_listings listing
        where listing.image_path = name
      )
    )
  );

create policy "Sellers can upload listing images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'market-media'
    and public.has_approved_membership()
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Sellers can delete listing images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'market-media'
    and public.has_approved_membership()
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

commit;
