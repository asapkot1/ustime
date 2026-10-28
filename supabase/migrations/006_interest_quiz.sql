-- Interest quiz answers. Run in the Supabase SQL editor after 005_capsule_photos_and_avatars.sql.
-- Safe to run twice.
-- The quiz also fills two columns that already exist: activity_prefs (categories) and budget_pref (0 free .. 3 $50+).
alter table profiles add column if not exists home_label text;   -- city name, or "Your area" for a phone location
alter table profiles add column if not exists home_lat float8;
alter table profiles add column if not exists home_lng float8;
alter table profiles add column if not exists travel_km smallint check (travel_km between 1 and 100);
