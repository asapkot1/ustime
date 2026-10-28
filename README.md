# UsTime

A couples app: date discovery with a radius filter, shared wishlist and matches, games, mood check-ins, a shared pet, memories and time capsules.

```
frontend/index.html          Clickable prototype (simulated data), open it in a browser
frontend/src/api.js          Supabase data layer (not yet wired into the UI)
supabase/migrations/001_schema.sql   Tables, row level security, radius search, invites, capsule locking
supabase/seed.sql            Starter places, London, ON
supabase/seed_ontario.sql    More places: Peel, Toronto + GTA, Guelph, Waterloo Region
```

## Backend setup (Supabase)
1. Create a project at supabase.com.
2. SQL editor: run `supabase/migrations/001_schema.sql`, then `supabase/seed.sql`, then `supabase/migrations/002_pairing_fixes.sql`, then `supabase/seed_ontario.sql`, then `supabase/migrations/003_together_and_photos.sql`, then `supabase/migrations/004_place_photos_and_pets.sql`, then `supabase/migrations/005_capsule_photos_and_avatars.sql`.
3. Storage: the migrations create three private buckets: `memories` (003), `capsules` and `avatars` (005), each limited to the couple. Capsule photos can't be viewed until the capsule unlocks.
4. Settings > API Keys: copy the project URL and **publishable** (anon) key into `frontend/src/config.js`. Never commit the secret / service_role key.

## Run the frontend locally
The page loads `src/api.js` as a JavaScript module, which browsers block when you double-click the file. Serve it instead:
```
python -m http.server 3000 --directory frontend
```
Then open http://localhost:3000. Port 3000 matches Supabase's default Site URL, so email confirmation links come back to the app.

## Status
- Prototype UI and schema are written. **The schema has not been run against a live Supabase project yet**, so expect small fixes.
- Next: wire `api.js` into the UI (auth, pairing, Explore, wishlist, check-ins), then move to Expo (React Native) for iOS/Android.
- Before launch: privacy policy, in-app account deletion (`delete_my_data()` plus removing the auth user server-side), Sign in with Apple if you offer social login, and legal review (PIPEDA).
- Place prices are estimates. Check hours and prices before launch.

## Put it on GitHub
```
git init
git add .
git commit -m "Initial UsTime prototype and Supabase schema"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/ustime.git
git push -u origin main
```
(Create the empty repo on github.com first. Keep it **private** while it's in development.)
