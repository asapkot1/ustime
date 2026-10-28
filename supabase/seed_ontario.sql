-- More starter places: Peel Region, Toronto and the rest of the GTA, Guelph, Waterloo Region.
-- Run in the Supabase SQL editor after seed.sql. The London places stay as they are.
-- Safe to run twice: places whose name already exists are skipped.
-- Coordinates were looked up on OpenStreetMap. Prices, hours and seasons are ESTIMATES: check them before launch.

-- The London rows had no city in their address. The app now shows the address as-is, so add it.
update places set address = address || ', London'
where address not like '%,%' and st_dwithin(location, st_point(-81.2453, 42.9849)::geography, 40000);

insert into places (name, category, price_tier, price_note, duration_min, address, location, description)
select v.name, v.category, v.tier, v.note, v.dur, v.addr, st_point(v.lng, v.lat)::geography, v.descr
from (values
  -- Peel: Brampton
  ('Gage Park','Outdoors',0,'Free',60,'45 Main St S, Brampton',-79.7581,43.6837,'Downtown park with gardens, a gazebo and a winter skating trail.'),
  ('Chinguacousy Park','Outdoors',0,'Free',120,'9050 Bramalea Rd, Brampton',-79.7218,43.7276,'Big park with a petting zoo, greenhouse and walking paths.'),
  ('Heart Lake Conservation Area','Outdoors',1,'~$10 per car',120,'10818 Heart Lake Rd, Brampton',-79.7964,43.7433,'Forest trails around the lake, with paddling in summer.'),
  ('Rose Theatre','Relaxing',2,'~$40',150,'1 Theatre Ln, Brampton',-79.7601,43.6871,'Concerts, comedy and touring shows in downtown Brampton.'),
  ('Professor''s Lake','Outdoors',1,'~$10',120,'1660 North Park Dr, Brampton',-79.7351,43.7465,'Sandy beach and a swimming lake. Summer only.'),
  ('PAMA (Peel Art Gallery Museum + Archives)','Creative',1,'Under $10',90,'9 Wellington St E, Brampton',-79.7576,43.6849,'Local art and history, partly in the old county jail.'),
  ('Eldorado Park','Outdoors',0,'Free',90,'8520 Creditview Rd, Brampton',-79.7801,43.6452,'Riverside trails along the Credit River.'),
  -- Peel: Mississauga
  ('Celebration Square','Relaxing',0,'Free',90,'300 City Centre Dr, Mississauga',-79.6426,43.5879,'Free outdoor concerts and movies in summer, skating in winter.'),
  ('Rattray Marsh Conservation Area','Outdoors',0,'Free',60,'660 Bexhill Rd, Mississauga',-79.6086,43.5172,'Boardwalk through a lakeside marsh.'),
  ('Kariya Park','Relaxing',0,'Free',45,'3620 Kariya Dr, Mississauga',-79.6363,43.5897,'Small Japanese garden with a pond and spring cherry blossoms.'),
  ('J.C. Saddington Park','Outdoors',0,'Free',60,'Port Credit, Mississauga',-79.5839,43.5463,'Lakefront park in Port Credit. Great for sunsets.'),
  ('Port Credit Lighthouse & Village','Food & Drinks',2,'~$40',120,'105 Lakeshore Rd W, Mississauga',-79.5869,43.5503,'Lighthouse, waterfront walk and plenty of patios nearby.'),
  -- Peel: Caledon
  ('Forks of the Credit Provincial Park','Outdoors',1,'~$15 per car',150,'17760 McLaren Rd, Caledon',-80.0127,43.8154,'Hiking with valley views and a waterfall.'),
  ('Belfountain Conservation Area','Outdoors',1,'~$10',90,'Belfountain, Caledon',-80.0088,43.7956,'Small waterfall, a suspension bridge and lookouts.'),
  ('Albion Hills Conservation Area','Outdoors',1,'~$10',150,'16500 Hwy 50, Caledon',-79.8288,43.9253,'Trails, mountain biking and a summer beach.'),
  -- Toronto
  ('Toronto Island Ferry','Outdoors',1,'~$9 return',240,'9 Queens Quay W, Toronto',-79.3753,43.6401,'Ferry to the Toronto Islands for bikes, beaches and skyline views.'),
  ('Distillery District','Relaxing',0,'Free to wander',120,'55 Mill St, Toronto',-79.3592,43.6503,'Car-free Victorian lanes with shops, cafes and a winter market.'),
  ('St. Lawrence Market','Food & Drinks',1,'~$20',90,'93 Front St E, Toronto',-79.3717,43.6491,'Historic food market. Graze, then grab a peameal bacon sandwich.'),
  ('Art Gallery of Ontario','Creative',2,'~$30',150,'317 Dundas St W, Toronto',-79.3928,43.6536,'Ontario''s major art gallery, Canadian and international.'),
  ('Royal Ontario Museum','Creative',2,'~$30',150,'100 Queens Park, Toronto',-79.3947,43.6677,'Dinosaurs, world cultures and the crystal-shaped entrance.'),
  ('Ripley''s Aquarium of Canada','Adventurous',2,'~$45',120,'288 Bremner Blvd, Toronto',-79.3861,43.6425,'Walk through the shark tunnel. Evenings are quieter.'),
  ('CN Tower','Adventurous',2,'~$45',90,'290 Bremner Blvd, Toronto',-79.3871,43.6426,'Glass floor and city views. Go at sunset.'),
  ('High Park','Outdoors',0,'Free',120,'1873 Bloor St W, Toronto',-79.4638,43.6463,'Toronto''s biggest park. Cherry blossoms in spring.'),
  ('Evergreen Brick Works','Outdoors',0,'Free',120,'550 Bayview Ave, Toronto',-79.3650,43.6842,'Old brick factory turned into ponds, trails and a Saturday farmers market.'),
  ('Bluffer''s Park','Outdoors',0,'Free',120,'1 Brimley Rd S, Toronto',-79.2394,43.7081,'Beach under the white Scarborough Bluffs.'),
  ('Casa Loma','Relaxing',2,'~$45',150,'1 Austin Terrace, Toronto',-79.4094,43.6781,'Tour a real castle with towers, tunnels and gardens.'),
  ('Allan Gardens Conservatory','Relaxing',0,'Free',45,'160 Gerrard St E, Toronto',-79.3744,43.6617,'Glass greenhouses full of tropical plants. Warm in winter.'),
  ('Kensington Market','Food & Drinks',1,'~$20',120,'Kensington Ave, Toronto',-79.4023,43.6552,'Vintage shops and cheap eats on every corner.'),
  ('Edwards Gardens','Relaxing',0,'Free',90,'755 Lawrence Ave E, Toronto',-79.3582,43.7314,'Formal gardens and a ravine trail beside the Toronto Botanical Garden.'),
  ('Toronto Zoo','Adventurous',2,'~$35',240,'2000 Meadowvale Rd, Toronto',-79.1845,43.8196,'Huge zoo. Wear comfy shoes.'),
  -- Rest of the GTA
  ('Canada''s Wonderland','Adventurous',3,'~$60+',360,'1 Canada''s Wonderland Dr, Vaughan',-79.5430,43.8420,'Roller coasters and rides. Open spring to fall.'),
  ('Kelso Conservation Area','Outdoors',1,'~$12',150,'5234 Kelso Rd, Milton',-79.9408,43.5058,'Escarpment hiking with lake views.'),
  ('Gairloch Gardens','Relaxing',0,'Free',60,'1306 Lakeshore Rd E, Oakville',-79.6487,43.4612,'Lakeside gardens with a pond.'),
  ('Toogood Pond Park','Outdoors',0,'Free',60,'Unionville, Markham',-79.3159,43.8722,'Pond loop next to the cafes on Main Street Unionville.'),
  -- Guelph area
  ('University of Guelph Arboretum','Outdoors',0,'Free',90,'Arboretum Rd, Guelph',-80.2152,43.5390,'Free trails and gardens on the university campus.'),
  ('Riverside Park','Outdoors',0,'Free',60,'709 Woolwich St, Guelph',-80.2704,43.5651,'Riverside paths and gardens.'),
  ('Guelph Civic Museum','Creative',1,'~$10',75,'52 Norfolk St, Guelph',-80.2515,43.5435,'Local history in a converted convent downtown.'),
  ('River Run Centre','Relaxing',2,'~$40',150,'35 Woolwich St, Guelph',-80.2462,43.5477,'Concerts and theatre by the Speed River.'),
  ('Elora Gorge Conservation Area','Outdoors',1,'~$10',180,'7400 Wellington Rd 21, Elora',-80.4515,43.6677,'Limestone gorge with tubing in summer.'),
  -- Waterloo Region
  ('Waterloo Park','Outdoors',0,'Free',90,'Waterloo Park, Waterloo',-80.5325,43.4669,'Lake, trails and a free animal farm uptown.'),
  ('THEMUSEUM','Creative',1,'~$20',90,'10 King St W, Kitchener',-80.4895,43.4501,'Interactive exhibits that change often.'),
  ('Kitchener Market','Food & Drinks',1,'~$15',90,'300 King St E, Kitchener',-80.4835,43.4480,'Saturday farmers market with food stalls.'),
  ('St. Jacobs Farmers'' Market','Food & Drinks',1,'~$20',150,'878 Weber St N, Woolwich',-80.5546,43.5116,'Big farmers market. Try the apple fritters.'),
  ('Victoria Park','Outdoors',0,'Free',60,'Victoria Park, Kitchener',-80.4983,43.4464,'Lake with paddle boats in summer and skating in winter.'),
  ('Laurel Creek Conservation Area','Outdoors',1,'~$10',120,'625 Westmount Rd N, Waterloo',-80.5758,43.4832,'Reservoir trails and a beach.'),
  ('Bingemans','Adventurous',2,'~$30',150,'425 Bingemans Centre Dr, Kitchener',-80.4498,43.4745,'Go-karts, laser tag and mini golf.')
) as v(name, category, tier, note, dur, addr, lng, lat, descr)
where not exists (select 1 from places p where p.name = v.name);
