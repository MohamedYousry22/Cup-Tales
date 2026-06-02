create table if not exists public.category_options (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories(id) on delete cascade,
  name_ar text not null,
  name_en text not null,
  price numeric not null check (price >= 0),
  created_at timestamptz not null default now()
);

create index if not exists category_options_category_id_idx
  on public.category_options(category_id);

alter table public.cart
  add column if not exists selected_option text;
