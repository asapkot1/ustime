-- Starter places (London, ON prototype data). Replace with Brampton / Peel / Toronto spots.
-- Prices are ESTIMATES. Verify hours and prices yourself before launch.
insert into places (name, category, price_tier, price_note, duration_min, address, location, description) values
('Tin Cup','Adventurous',1,'$15',90,'1324 Adelaide St N',st_point(-81.2479,43.0238)::geography,'Two mini-putt courses and a driving range.'),
('Cottage Pottery Studio','Creative',3,'~$60',180,'787 Adelaide St N',st_point(-81.2377,43.0009)::geography,'Intro pottery date nights.'),
('Hunter & Co.','Food & Drinks',3,'~$100',120,'349 Talbot St',st_point(-81.2512,42.9814)::geography,'Cocktails and shared plates downtown.'),
('Meadowlily Woods Trail','Outdoors',0,'Free',90,'25 Meadowlily Rd S',st_point(-81.1869,42.9717)::geography,'River views and forest paths.'),
('Monarch Culinary Studio','Classes',3,'~$75',180,'71 King St',st_point(-81.2528,42.9812)::geography,'Hands-on cooking classes.'),
('Crock A Doodle','Creative',2,'~$30',90,'671 Wonderland Rd N',st_point(-81.2920,42.9858)::geography,'Paint a ceramic piece together.'),
('Clayworx','Creative',3,'~$65',120,'664 Dundas St',st_point(-81.2297,42.9898)::geography,'Wheel throwing. Open Thu-Sat.'),
('J J Ceramics','Creative',1,'~$20',120,'452 Horton St E',st_point(-81.2352,42.9824)::geography,'Ceramic painting. Open Tue-Sat.'),
('The Tasting Room','Food & Drinks',3,'~$80',120,'483 Richmond St',st_point(-81.2508,42.9862)::geography,'Wine flights and bistro plates.'),
('Fleetway','Adventurous',1,'~$20',120,'720 Proudfoot Ln',st_point(-81.2864,42.9872)::geography,'Bowling, arcade and glow mini putt.'),
('The Club House','Adventurous',1,'$15',120,'100 Kellogg Ln',st_point(-81.2144,42.9924)::geography,'Indoor mini golf and simulators.'),
('Medway Valley Heritage Forest','Outdoors',0,'Free',90,'29 Doncaster Ave',st_point(-81.2979,43.0115)::geography,'Easy forest trails.'),
('Warbler Woods','Relaxing',0,'Free',60,'1968 Commissioners Rd W',st_point(-81.3528,42.9652)::geography,'Hilly Carolinian forest.'),
('Los Olivos','Food & Drinks',2,'~$40',90,'2140 Kains Rd',st_point(-81.3583,42.9738)::geography,'Casual dinner and cocktails.'),
('East Park London','Adventurous',2,'~$30',120,'1275 Hamilton Rd',st_point(-81.1671,42.9724)::geography,'Go-karts and mini golf.'),
('Papi''s','Food & Drinks',3,'~$150',150,'100 Kellogg Ln',st_point(-81.2141,42.9932)::geography,'Speakeasy-style steakhouse.');
