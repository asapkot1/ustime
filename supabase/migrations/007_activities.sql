-- Activities: the actual date idea at a place ("Go ice skating" at Gage Park).
-- Run in the Supabase SQL editor after 006_interest_quiz.sql, then run supabase/seed_activities.sql.
-- Safe to run twice.

create table if not exists activities (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references places on delete cascade,
  title text not null,                -- "Go ice skating on the skating trail"
  category text not null,             -- same categories as places (Outdoors, Creative, ...)
  price_tier smallint not null check (price_tier between 0 and 3),
  price_note text,                    -- per person, an estimate
  duration_min int,
  months smallint[],                  -- months it runs (1 = Jan); null = all year
  tip text,
  active boolean not null default true,
  unique (place_id, title)
);
create index if not exists activities_place on activities (place_id);
alter table activities enable row level security;
drop policy if exists "activities readable" on activities;
create policy "activities readable" on activities for select using (auth.uid() is not null and active);

-- Seed files match activities to places by name, so names must be unique.
create unique index if not exists places_name_key on places (name);

-- Radius search over activities. Pass mon (1-12) to only get what's running that month.
create or replace function activities_nearby(lat float8, lng float8, radius_km float8, max_tier int default 3, mon int default null)
returns table (id uuid, title text, category text, price_tier smallint, price_note text, duration_min int, months smallint[], tip text,
               place_id uuid, place_name text, address text, description text, lat float8, lng float8,
               photo_url text, photo_credit text, distance_km float8)
language sql stable as $$
  select a.id, a.title, a.category, a.price_tier, a.price_note, a.duration_min, a.months, a.tip,
         p.id, p.name, p.address, p.description, st_y(p.location::geometry), st_x(p.location::geometry),
         p.photo_url, p.photo_credit, st_distance(p.location, st_point(lng, lat)::geography) / 1000.0
  from activities a join places p on p.id = a.place_id
  where a.active and p.active and a.price_tier <= max_tier
    and (mon is null or a.months is null or mon = any(a.months))
    and st_dwithin(p.location, st_point(lng, lat)::geography, radius_km * 1000)
  order by 17
$$;
