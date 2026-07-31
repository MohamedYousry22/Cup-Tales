create or replace function public.enforce_cup_tales_business_hours()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  cairo_time time := (clock_timestamp() at time zone 'Africa/Cairo')::time;
begin
  if not (
    cairo_time >= time '07:30:00'
    or cairo_time < time '00:31:00'
  ) then
    raise exception 'CUP_TALES_CLOSED'
      using detail =
        'Orders are accepted daily from 07:30 through 00:30 Africa/Cairo time.';
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_cup_tales_business_hours
  on public.orders;
create trigger enforce_cup_tales_business_hours
  before insert on public.orders
  for each row
  execute function public.enforce_cup_tales_business_hours();
