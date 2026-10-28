-- Capsule photos + profile pictures. Run in the Supabase SQL editor after 004_place_photos_and_pets.sql.
-- Safe to run twice.

insert into storage.buckets (id, name, public) values ('capsules', 'capsules', false), ('avatars', 'avatars', false)
on conflict (id) do nothing;

-- 1. Capsule photos live at capsules/<couple_id>/<capsule_id>/<file>.
--    Like the notes, they can only be added while sealed and only be viewed once unlock_at has passed.
drop policy if exists "ustime capsule photo add" on storage.objects;
drop policy if exists "ustime capsule photo read" on storage.objects;
create policy "ustime capsule photo add" on storage.objects for insert to authenticated with check (
  bucket_id = 'capsules' and (storage.foldername(name))[1] = public.my_couple()::text
  and exists (select 1 from public.capsules c where c.id::text = (storage.foldername(name))[2]
              and c.couple_id = public.my_couple() and c.unlock_at > now()));
create policy "ustime capsule photo read" on storage.objects for select to authenticated using (
  bucket_id = 'capsules'
  and exists (select 1 from public.capsules c where c.id::text = (storage.foldername(name))[2]
              and c.couple_id = public.my_couple() and c.unlock_at <= now()));

-- 2. Profile pictures live at avatars/<user_id>/<file>. You manage your own; you and your partner can see them.
drop policy if exists "ustime avatar read" on storage.objects;
drop policy if exists "ustime avatar add" on storage.objects;
drop policy if exists "ustime avatar delete" on storage.objects;
create policy "ustime avatar read" on storage.objects for select to authenticated using (
  bucket_id = 'avatars' and ((storage.foldername(name))[1] = auth.uid()::text
    or (storage.foldername(name))[1] in (select user_id::text from public.couple_members where couple_id = public.my_couple())));
create policy "ustime avatar add" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "ustime avatar delete" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
