alter table public.orders
  add column if not exists customer_phone text;

create or replace function public.attach_and_require_order_phone()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  profile_phone text;
begin
  select btrim(phone)
    into profile_phone
  from public.profiles
  where id = new.user_id;

  if profile_phone is null
     or profile_phone !~ '^01[0125][0-9]{8}$' then
    raise exception 'CUP_TALES_PHONE_REQUIRED'
      using detail =
        'A valid 11-digit Egyptian mobile number is required before ordering.';
  end if;

  new.customer_phone := profile_phone;
  return new;
end;
$$;

drop trigger if exists attach_and_require_order_phone
  on public.orders;
create trigger attach_and_require_order_phone
  before insert on public.orders
  for each row
  execute function public.attach_and_require_order_phone();

comment on column public.orders.customer_phone is
  'Snapshot of the customer phone number at order creation time.';
