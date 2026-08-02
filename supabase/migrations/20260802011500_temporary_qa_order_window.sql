create or replace function public.enforce_cup_tales_business_hours()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  cairo_time time := (clock_timestamp() at time zone 'Africa/Cairo')::time;
begin
  -- Temporary, account-scoped QA window for the connected iPhone test account.
  -- The exception expires automatically and cannot affect other customers.
  if new.user_id = uuid '776ec61a-2d5a-437a-94a4-24afe61967ca'
     and clock_timestamp() < timestamptz '2026-08-02 03:00:00+03' then
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
