create or replace function public.enforce_cup_tales_business_hours()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  cairo_time time := (clock_timestamp() at time zone 'Africa/Cairo')::time;
begin
  -- Apple App Review must be able to verify the complete checkout flow at any
  -- time. Normal customer accounts remain subject to business hours.
  if new.user_id = uuid 'a3ffad5e-025a-465f-811b-b15a9f84809a' then
    return new;
  end if;

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
