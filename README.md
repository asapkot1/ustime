# UsTime

A couples app: date discovery with a radius filter, shared wishlist and matches, games, mood check-ins, a shared pet, memories and time capsules.

```
frontend/index.html          Clickable prototype (simulated data), open it in a browser
frontend/src/api.js          Supabase data layer (not yet wired into the UI)
supabase/migrations/001_schema.sql   Tables, row level security, radius search, invites, capsule locking
supabase/seed.sql            Starter places (London, ON test data, replace with Brampton / Peel / Toronto)
```

## Backend setup (Supabase)
1. Create a project at supabase.com.
2. SQL editor: run `supabase/migrations/001_schema.sql`, then `supabase/seed.sql`.
3. Storage: create private buckets `avatars` and `memories`, and a policy limiting access to couple members.
4. Settings > API: copy the project URL and **anon** key into `frontend/src/config.js`. Never commit the service_role key.

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
