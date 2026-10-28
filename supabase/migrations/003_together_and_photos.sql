-- Together-since date + memory photos. Run in the Supabase SQL editor after 002_pairing_fixes.sql.
-- Safe to run twice.

-- 1. Let either partner set the date they got together (couples.started_on).
drop policy if exists "my couple update" on couples;
create policy "my couple update" on couples for update
  using (id = my_couple()) with check (id = my_couple());

-- 2. Private "memories" photo bucket. Files live under <couple_id>/..., and only that couple can see them.
insert into storage.buckets (id, name, public) values ('memories', 'memories', false)
on conflict (id) do nothing;

drop policy if exists "ustime memories read" on storage.objects;
drop policy if exists "ustime memories add" on storage.objects;
drop policy if exists "ustime memories delete" on storage.objects;
create policy "ustime memories read" on storage.objects for select to authenticated
  using (bucket_id = 'memories' and (storage.foldername(name))[1] = public.my_couple()::text);
create policy "ustime memories add" on storage.objects for insert to authenticated
  with check (bucket_id = 'memories' and (storage.foldername(name))[1] = public.my_couple()::text);
create policy "ustime memories delete" on storage.objects for delete to authenticated
  using (bucket_id = 'memories' and (storage.foldername(name))[1] = public.my_couple()::text);
