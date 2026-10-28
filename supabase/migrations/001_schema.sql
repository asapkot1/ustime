-- UsTime schema. Run in the Supabase SQL editor, or with `supabase db push`.
create extension if not exists postgis;
create extension if not exists pgcrypto;

-- ---------- Tables ----------
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null,
  avatar_url text,
  relationship_status text,
  budget_pref smallint check (budget_pref between 0 and 3),
  activity_prefs text[] default '{}',
  home_location geography(point,4326),
  created_at timestamptz default now()
);

create table couples (
  id uuid primary key default gen_random_uuid(),
  started_on date,
  created_at timestamptz default now()
);

create table couple_members (
  couple_id uuid references couples on delete cascade,
  user_id uuid unique references auth.users on delete cascade, -- one couple per user
  primary key (couple_id, user_id)
);

create table invites (
  code text primary key,
  couple_id uuid not null references couples on delete cascade,
  created_by uuid not null references auth.users,
  expires_at timestamptz not null default now() + interval '48 hours',
  used_by uuid references auth.users
);

create table places (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  price_tier smallint not null check (price_tier between 0 and 3), -- 0 free, 1 <$25, 2 $25-50, 3 $50+
  price_note text,
  duration_min int,
  address text,
  location geography(point,4326) not null,
  description text,
  active boolean default true
);
create index places_geo on places using gist (location);

create table wishlist (
  couple_id uuid references couples on delete cascade,
  place_id uuid references places on delete cascade,
  user_id uuid references auth.users on delete cascade,
  created_at timestamptz default now(),
  primary key (couple_id, place_id, user_id)
);

create table check_ins (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references couples on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  mood text not null check (mood in ('amazing','happy','neutral','stressed','sad')),
  note text,
  shared boolean not null default true,
  created_at timestamptz default now()
);

create table game_sessions (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references couples on delete cascade,
  game text not null,
  points int not null default 0,
  created_at timestamptz default now()
);

create table pets (
  couple_id uuid primary key references couples on delete cascade,
  name text not null default 'Mochi',
  kind text not null default 'bunny',
  xp int not null default 0,
  happiness int not null default 80 check (happiness between 0 and 100),
  accessories text[] default '{}'
);

create table memories (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references couples on delete cascade,
  author_id uuid not null references auth.users,
  title text not null,
  photo_path text,           -- path in the 'memories' storage bucket
  occurred_on date default current_date,
  place_id uuid references places,
  created_at timestamptz default now()
);

create table capsules (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references couples on delete cascade,
  created_by uuid not null references auth.users,
  title text not null,
  unlock_at timestamptz not null,
  created_at timestamptz default now()
);

create table capsule_items (
  id uuid primary key default gen_random_uuid(),
  capsule_id uuid not null references capsules on delete cascade,
  author_id uuid not null references auth.users,
  body text,
  photo_path text,
  created_at timestamptz default now()
);

-- ---------- Helper ----------
create function my_couple() returns uuid
language sql stable security definer set search_path = public as $$
  select couple_id from couple_members where user_id = auth.uid() limit 1
$$;

-- ---------- Row level security ----------
alter table profiles enable row level security;
alter table couples enable row level security;
alter table couple_members enable row level security;
alter table invites enable row level security;
alter table places enable row level security;
alter table wishlist enable row level security;
alter table check_ins enable row level security;
alter table game_sessions enable row level security;
alter table pets enable row level security;
alter table memories enable row level security;
alter table capsules enable row level security;
alter table capsule_items enable row level security;

create policy "own profile" on profiles for all using (id = auth.uid()) with check (id = auth.uid());
create policy "partner profile" on profiles for select using (
  id in (select user_id from couple_members where couple_id = my_couple()));
create policy "my couple" on couples for select using (id = my_couple());
create policy "my membership" on couple_members for select using (couple_id = my_couple());
create policy "places readable" on places for select using (auth.uid() is not null and active);

create policy "wishlist read" on wishlist for select using (couple_id = my_couple());
create policy "wishlist add" on wishlist for insert with check (couple_id = my_couple() and user_id = auth.uid());
create policy "wishlist remove" on wishlist for delete using (user_id = auth.uid());

-- Private check-ins are only visible to their author.
create policy "checkin read" on check_ins for select using (
  couple_id = my_couple() and (user_id = auth.uid() or shared));
create policy "checkin add" on check_ins for insert with check (
  couple_id = my_couple() and user_id = auth.uid());

create policy "games" on game_sessions for all using (couple_id = my_couple()) with check (couple_id = my_couple());
create policy "pet" on pets for all using (couple_id = my_couple()) with check (couple_id = my_couple());
create policy "memories read" on memories for select using (couple_id = my_couple());
create policy "memories add" on memories for insert with check (couple_id = my_couple() and author_id = auth.uid());
create policy "memories delete" on memories for delete using (author_id = auth.uid());

create policy "capsules read" on capsules for select using (couple_id = my_couple());
create policy "capsules add" on capsules for insert with check (couple_id = my_couple() and created_by = auth.uid());

-- Capsule contents stay locked on the SERVER until unlock_at.
create policy "capsule items readable after unlock" on capsule_items for select using (
  exists (select 1 from capsules c where c.id = capsule_id and c.couple_id = my_couple() and c.unlock_at <= now()));
create policy "capsule items add before unlock" on capsule_items for insert with check (
  author_id = auth.uid() and exists (select 1 from capsules c where c.id = capsule_id and c.couple_id = my_couple() and c.unlock_at > now()));

-- ---------- Functions (call with supabase.rpc) ----------
create function create_invite() returns text
language plpgsql security definer set search_path = public as $$
declare cid uuid; c text;
begin
  select couple_id into cid from couple_members where user_id = auth.uid();
  if cid is null then
    insert into couples default values returning id into cid;
    insert into couple_members values (cid, auth.uid());
    insert into pets (couple_id) values (cid);
  end if;
  c := upper(substr(encode(gen_random_bytes(4),'hex'),1,6));
  insert into invites (code, couple_id, created_by) values (c, cid, auth.uid());
  return c;
end $$;

create function join_couple(invite_code text) returns uuid
language plpgsql security definer set search_path = public as $$
declare inv invites; n int;
begin
  if exists (select 1 from couple_members where user_id = auth.uid()) then
    raise exception 'Already in a couple';
  end if;
  select * into inv from invites where code = upper(invite_code) and used_by is null and expires_at > now() for update;
  if not found then raise exception 'Invalid or expired code'; end if;
  select count(*) into n from couple_members where couple_id = inv.couple_id;
  if n >= 2 then raise exception 'Couple is full'; end if;
  insert into couple_members values (inv.couple_id, auth.uid());
  update invites set used_by = auth.uid() where code = inv.code;
  return inv.couple_id;
end $$;

create function places_nearby(lat float8, lng float8, radius_km float8, max_tier int default 3, cat text default null)
returns table (id uuid, name text, category text, price_tier smallint, price_note text,
               duration_min int, address text, description text, lat float8, lng float8, distance_km float8)
language sql stable as $$
  select p.id, p.name, p.category, p.price_tier, p.price_note, p.duration_min, p.address, p.description,
         st_y(p.location::geometry), st_x(p.location::geometry),
         st_distance(p.location, st_point(lng, lat)::geography) / 1000.0
  from places p
  where p.active and p.price_tier <= max_tier and (cat is null or p.category = cat)
    and st_dwithin(p.location, st_point(lng, lat)::geography, radius_km * 1000)
  order by 11
$$;

-- "It's a Match!": places both partners saved.
create view wishlist_matches with (security_invoker = true) as
  select couple_id, place_id from wishlist
  group by couple_id, place_id having count(distinct user_id) = 2;

-- Delete my account's couple data (Apple requires in-app account deletion; also delete the auth user server-side).
create function delete_my_data() returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from check_ins where user_id = auth.uid();
  delete from wishlist where user_id = auth.uid();
  delete from profiles where id = auth.uid();
  delete from couple_members where user_id = auth.uid();
end $$;
