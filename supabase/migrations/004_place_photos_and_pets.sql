-- Place photos + choose-your-own pet. Run in the Supabase SQL editor after 003_together_and_photos.sql.
-- Safe to run twice.

-- 1. Photos for places (Wikimedia Commons links; the credit is shown under the photo, as the licences require).
alter table places add column if not exists photo_url text;
alter table places add column if not exists photo_credit text;

-- places_nearby now also returns the photo, so it has to be recreated.
drop function if exists places_nearby(float8, float8, float8, int, text);
create function places_nearby(lat float8, lng float8, radius_km float8, max_tier int default 3, cat text default null)
returns table (id uuid, name text, category text, price_tier smallint, price_note text, duration_min int, address text,
               description text, lat float8, lng float8, photo_url text, photo_credit text, distance_km float8)
language sql stable as $$
  select p.id, p.name, p.category, p.price_tier, p.price_note, p.duration_min, p.address, p.description,
         st_y(p.location::geometry), st_x(p.location::geometry), p.photo_url, p.photo_credit,
         st_distance(p.location, st_point(lng, lat)::geography) / 1000.0
  from places p
  where p.active and p.price_tier <= max_tier and (cat is null or p.category = cat)
    and st_dwithin(p.location, st_point(lng, lat)::geography, radius_km * 1000)
  order by 13
$$;

-- 2. Pets start unnamed so each couple picks the animal and name themselves.
alter table pets alter column name drop default;
alter table pets alter column name drop not null;
update pets set name = null where name = 'Mochi' and xp = 0;

-- 3. Photos from Wikimedia Commons (matched by Wikipedia article within 2.5 km, then reviewed by hand).
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c2/GAGE_PARK_FALL_BEAUTY_OCT_09_Rotated.jpg/960px-GAGE_PARK_FALL_BEAUTY_OCT_09_Rotated.jpg', photo_credit = 'Keith Roy Miller / CC0, via Wikimedia Commons' where name = 'Gage Park';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/11/Chinguacousy_Park_2022.jpg/960px-Chinguacousy_Park_2022.jpg', photo_credit = 'Canmenwalker / CC BY 4.0, via Wikimedia Commons' where name = 'Chinguacousy Park';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/98/Heart_Lake_Conservation2.jpg/960px-Heart_Lake_Conservation2.jpg', photo_credit = 'Mykola Swarnyk / CC BY-SA 4.0, via Wikimedia Commons' where name = 'Heart Lake Conservation Area';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1f/Rose_Theatre_%286012909875%29.jpg/960px-Rose_Theatre_%286012909875%29.jpg', photo_credit = '^ Missi ^ from Mississauga, Canada / CC BY 2.0, via Wikimedia Commons' where name = 'Rose Theatre';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/53/Professor%27s_Lake_2022.jpg/960px-Professor%27s_Lake_2022.jpg', photo_credit = 'Canmenwalker / CC BY 4.0, via Wikimedia Commons' where name = 'Professor''s Lake';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/dc/Mississauga_Celebration_Square%2C_May_16_2026.jpg/960px-Mississauga_Celebration_Square%2C_May_16_2026.jpg', photo_credit = 'Dillan Payne / CC BY-SA 4.0, via Wikimedia Commons' where name = 'Celebration Square';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/32/Rattray_Marsh_Conservation_Area2.jpg/960px-Rattray_Marsh_Conservation_Area2.jpg', photo_credit = 'Mykola Swarnyk / CC BY-SA 4.0, via Wikimedia Commons' where name = 'Rattray Marsh Conservation Area';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c1/Port_Credit_Scene_July_2019.jpeg/960px-Port_Credit_Scene_July_2019.jpeg', photo_credit = 'Jjj84206 / CC BY-SA 4.0, via Wikimedia Commons' where name = 'Port Credit Lighthouse & Village';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/ca/Forks_of_the_Credit_Provincial_Park.jpg/960px-Forks_of_the_Credit_Provincial_Park.jpg', photo_credit = 'Richard apple / CC BY-SA 3.0, via Wikimedia Commons' where name = 'Forks of the Credit Provincial Park';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/11/Toronto_Islands_2025-05-08.jpg/960px-Toronto_Islands_2025-05-08.jpg', photo_credit = 'JK Liu / CC BY-SA 4.0, via Wikimedia Commons' where name = 'Toronto Island Ferry';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a0/St._Lawrence_Market%2C_Toronto.png/960px-St._Lawrence_Market%2C_Toronto.png', photo_credit = 'Jacob Rens / CC BY-SA 4.0, via Wikimedia Commons' where name = 'St. Lawrence Market';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/87/Art_Gallery_of_Ontario_2023.jpg/960px-Art_Gallery_of_Ontario_2023.jpg', photo_credit = 'Canmenwalker / CC BY 4.0, via Wikimedia Commons' where name = 'Art Gallery of Ontario';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/72/Royal_Ontario_Museum_in_Fall_2021.jpg/960px-Royal_Ontario_Museum_in_Fall_2021.jpg', photo_credit = 'Maksim Sokolov (Maxergon) / CC BY-SA 4.0, via Wikimedia Commons' where name = 'Royal Ontario Museum';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/47/Ripley%27s_Aquarium_of_Canada%2C_Toronto%2C_Ontario.jpg/960px-Ripley%27s_Aquarium_of_Canada%2C_Toronto%2C_Ontario.jpg', photo_credit = 'EuroCarGT / CC BY-SA 4.0, via Wikimedia Commons' where name = 'Ripley''s Aquarium of Canada';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a1/Hillside_Gardens_%2824677009128%29.jpg/960px-Hillside_Gardens_%2824677009128%29.jpg', photo_credit = 'Jeff Hitchcock from Seattle, WA, USA / CC BY 2.0, via Wikimedia Commons' where name = 'High Park';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/25/Don_Valley_Brick_Works_%2854010434534%29.jpg/960px-Don_Valley_Brick_Works_%2854010434534%29.jpg', photo_credit = 'V. L. / CC0, via Wikimedia Commons' where name = 'Evergreen Brick Works';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/43/Exterior_of_Casa_Loma%2C_June_2012.jpg/960px-Exterior_of_Casa_Loma%2C_June_2012.jpg', photo_credit = 'Priscilla Jordão from São Paulo, Brasil / CC BY-SA 2.0, via Wikimedia Commons' where name = 'Casa Loma';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/91/Allan_Gardens_seen_from_Jarvis_Street_in_2025.jpg/960px-Allan_Gardens_seen_from_Jarvis_Street_in_2025.jpg', photo_credit = 'Rosco1011 / CC BY-SA 4.0, via Wikimedia Commons' where name = 'Allan Gardens Conservatory';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ef/Kensington_Market_Toronto_August_2017_01.jpg/960px-Kensington_Market_Toronto_August_2017_01.jpg', photo_credit = 'Arild Vågen / CC BY-SA 4.0, via Wikimedia Commons' where name = 'Kensington Market';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/04/Edward_Gardens_waterfall_2023.jpg/960px-Edward_Gardens_waterfall_2023.jpg', photo_credit = 'Canmenwalker / CC BY 4.0, via Wikimedia Commons' where name = 'Edwards Gardens';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/ad/TorontoZoo.jpg/960px-TorontoZoo.jpg', photo_credit = 'Maelwys at English Wikipedia / Public domain, via Wikimedia Commons' where name = 'Toronto Zoo';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d5/A_very_Canadian_Canada%27s_Wonderland_%2841514872810%29.jpg/960px-A_very_Canadian_Canada%27s_Wonderland_%2841514872810%29.jpg', photo_credit = 'Enoch Leung from Canada / CC BY-SA 2.0, via Wikimedia Commons' where name = 'Canada''s Wonderland';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/52/Kelso_Conservation_Area-_Escarpment_-_Milton_Heights-Ontario_%282%29.jpg/960px-Kelso_Conservation_Area-_Escarpment_-_Milton_Heights-Ontario_%282%29.jpg', photo_credit = 'Mhsheikholeslami / CC BY-SA 4.0, via Wikimedia Commons' where name = 'Kelso Conservation Area';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/45/Toogood_Pond_Park.jpg/960px-Toogood_Pond_Park.jpg', photo_credit = 'Nath87 / CC BY 4.0, via Wikimedia Commons' where name = 'Toogood Pond Park';
update places set photo_url = 'https://upload.wikimedia.org/wikipedia/commons/0/0e/CIS-riverside.jpg', photo_credit = 'CIS-ATravers / CC BY-SA 3.0, via Wikimedia Commons' where name = 'Riverside Park';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0a/River_Run_Centre_in_Guelph_ON.jpg/960px-River_Run_Centre_in_Guelph_ON.jpg', photo_credit = 'Tabercil / CC BY 3.0, via Wikimedia Commons' where name = 'River Run Centre';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b3/Elora_Gorge.jpg/960px-Elora_Gorge.jpg', photo_credit = 'You may select the license of your choice. / CC BY-SA 3.0, via Wikimedia Commons' where name = 'Elora Gorge Conservation Area';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/89/TheMuseum-10KingStW-Kitchener.JPG/960px-TheMuseum-10KingStW-Kitchener.JPG', photo_credit = 'Illustratedjc / CC BY-SA 3.0, via Wikimedia Commons' where name = 'THEMUSEUM';
update places set photo_url = 'https://upload.wikimedia.org/wikipedia/commons/3/33/St_Jacobs_Market.jpg', photo_credit = 'Brona at English Wikipedia / CC BY-SA 3.0, via Wikimedia Commons' where name = 'St. Jacobs Farmers'' Market';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e6/Victoria-park-kitchener-lake.jpg/960px-Victoria-park-kitchener-lake.jpg', photo_credit = 'Lupin at en.wikipedia / CC BY-SA 3.0, via Wikimedia Commons' where name = 'Victoria Park';
update places set photo_url = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/01/500px_photo_%28118246393%29.jpeg/960px-500px_photo_%28118246393%29.jpeg', photo_credit = 'Chris Herborth / CC BY 3.0, via Wikimedia Commons' where name = 'Laurel Creek Conservation Area';
