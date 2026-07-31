drop policy if exists "Users can update their own addresses"
  on public.user_addresses;
create policy "Users can update their own addresses"
  on public.user_addresses
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant update on table public.user_addresses to authenticated;
