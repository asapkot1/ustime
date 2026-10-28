-- Pairing fixes. Run in the Supabase SQL editor after 001_schema.sql.
--
-- 1. On Supabase, pgcrypto lives in the "extensions" schema, so gen_random_bytes()
--    was not found by create_invite() (its search_path was only "public").
-- 2. create_invite() no longer hands out codes for a couple that is already full.
-- 3. join_couple(): if you created a code yourself (which puts you in a couple of one)
--    you can still join your partner's code instead. Your empty couple is removed.

create or replace function create_invite() returns text
language plpgsql security definer set search_path = public, extensions as $$
declare cid uuid; c text;
begin
  select couple_id into cid from couple_members where user_id = auth.uid();
  if cid is null then
    insert into couples default values returning id into cid;
    insert into couple_members values (cid, auth.uid());
    insert into pets (couple_id) values (cid);
  elsif (select count(*) from couple_members where couple_id = cid) >= 2 then
    raise exception 'You are already paired';
  end if;
  c := upper(substr(encode(gen_random_bytes(4),'hex'),1,6));
  insert into invites (code, couple_id, created_by) values (c, cid, auth.uid());
  return c;
end $$;

create or replace function join_couple(invite_code text) returns uuid
language plpgsql security definer set search_path = public, extensions as $$
declare inv invites; mine uuid; n int;
begin
  select * into inv from invites where code = upper(trim(invite_code)) and used_by is null and expires_at > now() for update;
  if not found then raise exception 'Invalid or expired code'; end if;

  select couple_id into mine from couple_members where user_id = auth.uid();
  if mine = inv.couple_id then raise exception 'That is your own code. Send it to your partner'; end if;
  if mine is not null then
    if (select count(*) from couple_members where couple_id = mine) >= 2 then
      raise exception 'Already in a couple';
    end if;
    delete from couples where id = mine; -- solo couple: cascades to its member row, invites and pet
  end if;

  select count(*) into n from couple_members where couple_id = inv.couple_id;
  if n >= 2 then raise exception 'Couple is full'; end if;
  insert into couple_members values (inv.couple_id, auth.uid());
  update invites set used_by = auth.uid() where code = inv.code;
  return inv.couple_id;
end $$;
