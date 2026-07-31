create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  requesting_user_id uuid := auth.uid();
begin
  if requesting_user_id is null then
    raise exception 'Authentication is required'
      using errcode = '42501';
  end if;

  delete from public.user_addresses
  where user_id = requesting_user_id;

  delete from public.cart
  where user_id = requesting_user_id;

  delete from public.orders
  where user_id = requesting_user_id;

  delete from public.profiles
  where id = requesting_user_id;

  delete from auth.users
  where id = requesting_user_id;
end;
$$;

revoke all on function public.delete_my_account() from public;
revoke all on function public.delete_my_account() from anon;
grant execute on function public.delete_my_account() to authenticated;

comment on function public.delete_my_account() is
  'Permanently deletes the authenticated user and their Cup Tales data.';
