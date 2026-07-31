alter table public.orders
  add column if not exists fulfillment_type text not null default 'pickup',
  add column if not exists delivery_address text,
  add column if not exists customer_note text,
  add column if not exists payment_method text not null default 'cash';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_fulfillment_type_check'
      and conrelid = 'public.orders'::regclass
  ) then
    alter table public.orders
      add constraint orders_fulfillment_type_check
      check (fulfillment_type in ('pickup', 'drive_thru', 'delivery'));
  end if;
end
$$;

create table if not exists public.user_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  address text not null check (char_length(btrim(address)) > 0),
  created_at timestamptz not null default now(),
  unique (user_id, address)
);

alter table public.user_addresses enable row level security;

drop policy if exists "Users can view their own addresses"
  on public.user_addresses;
create policy "Users can view their own addresses"
  on public.user_addresses
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can add their own addresses"
  on public.user_addresses;
create policy "Users can add their own addresses"
  on public.user_addresses
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own addresses"
  on public.user_addresses;
create policy "Users can delete their own addresses"
  on public.user_addresses
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

grant select, insert, delete on table public.user_addresses to authenticated;
