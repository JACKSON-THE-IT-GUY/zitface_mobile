begin;

create table public.market_listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles (id) on delete cascade,
  title text not null check (length(trim(title)) between 1 and 120),
  price numeric(12, 2) not null check (price >= 0),
  category text not null check (
    category in ('Textbooks', 'Electronics', 'Hostel Gear', 'Apparel', 'Services')
  ),
  description text not null default '',
  status text not null default 'active' check (status in ('active', 'sold')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index market_listings_active_created_idx
  on public.market_listings (created_at desc)
  where status = 'active';

create trigger market_listings_set_updated_at
  before update on public.market_listings
  for each row execute function public.set_updated_at();

alter table public.market_listings enable row level security;
revoke all on table public.market_listings from anon, authenticated;
grant select on public.market_listings to authenticated;
grant insert (seller_id, title, price, category, description)
  on public.market_listings to authenticated;
grant update (title, price, category, description, status)
  on public.market_listings to authenticated;
grant delete on public.market_listings to authenticated;

create policy "Members can read active marketplace listings"
  on public.market_listings for select to authenticated
  using (status = 'active' or seller_id = (select auth.uid()));
create policy "Users can create their own marketplace listings"
  on public.market_listings for insert to authenticated
  with check (
    seller_id = (select auth.uid())
    and status = 'active'
  );
create policy "Users can update their own marketplace listings"
  on public.market_listings for update to authenticated
  using (seller_id = (select auth.uid()))
  with check (seller_id = (select auth.uid()));
create policy "Users can delete their own marketplace listings"
  on public.market_listings for delete to authenticated
  using (seller_id = (select auth.uid()));
create policy "Approved membership required"
  on public.market_listings as restrictive for all to authenticated
  using (public.has_approved_membership())
  with check (public.has_approved_membership());

commit;