// Data layer for UsTime. Each function maps to a table or SQL function in supabase/migrations/001_schema.sql.
// Loaded from a CDN so the plain web page needs no build step. Switch to `npm i @supabase/supabase-js` with Expo.
import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.117.3/+esm";
import { SUPABASE_URL, SUPABASE_ANON_KEY } from "./config.js";

export const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
const ok = ({ data, error }) => { if (error) throw error; return data; };

// ---------- Photos ----------
// Phone photos are often 5-10 MB, so shrink them to `max` pixels before uploading. If the browser
// can't decode the file (e.g. HEIC in some browsers), the original is uploaded instead.
const shrink = async (file, max) => {
  try {
    const img = await createImageBitmap(file);
    const s = Math.min(1, max / Math.max(img.width, img.height));
    const c = Object.assign(document.createElement("canvas"), { width: Math.round(img.width * s), height: Math.round(img.height * s) });
    c.getContext("2d").drawImage(img, 0, 0, c.width, c.height);
    return await new Promise((res) => c.toBlob((b) => res(b || file), "image/jpeg", 0.85));
  } catch { return file; }
};
const upload = async (bucket, folder, file, max) => {
  const blob = await shrink(file, max);
  const ext = blob.type === "image/jpeg" ? "jpg" : (file.name.split(".").pop() || "jpg").toLowerCase();
  const path = `${folder}/${crypto.randomUUID()}.${ext}`;
  ok(await sb.storage.from(bucket).upload(path, blob, { contentType: blob.type || file.type }));
  return path;
};
// All buckets are private: rows store a path, and the app shows a link that expires after an hour.
const signed = async (bucket, rows, key = "photo_path", out = "photo_url") => {
  const paths = rows.map((r) => r?.[key]).filter(Boolean);
  if (!paths.length) return rows;
  const urls = ok(await sb.storage.from(bucket).createSignedUrls(paths, 3600));
  const by = Object.fromEntries(urls.map((u) => [u.path, u.signedUrl]));
  rows.forEach((r) => r && (r[out] = r[key] ? by[r[key]] ?? null : null));
  return rows;
};

// Auth + profile. The name rides along in user metadata so the profile row can be created
// on first sign-in (with email confirmation on, sign-up returns no session to write it with).
export const signUp = (email, password, name) =>
  sb.auth.signUp({ email, password, options: { data: { name }, emailRedirectTo: location.origin + location.pathname } }).then(ok);
export const signIn = (email, password) => sb.auth.signInWithPassword({ email, password }).then(ok);
export const signOut = async () => { const { error } = await sb.auth.signOut(); if (error) throw error; };
export const getUser = async () => (await sb.auth.getSession()).data.session?.user ?? null;
export const saveProfile = async (p) => ok(await sb.from("profiles").upsert(p).select().single());
export const ensureProfile = async (user) => {
  const p = ok(await sb.from("profiles").select("*").eq("id", user.id).maybeSingle());
  return p ?? saveProfile({ id: user.id, name: user.user_metadata?.name || user.email.split("@")[0] });
};
// Partial update (upsert would need every not-null column, like name).
export const updateProfile = async (id, fields) => ok(await sb.from("profiles").update(fields).eq("id", id).select().single());
// Profile pictures: avatars/<user_id>/<file>. Adds avatar_src (a viewable link) to each profile.
export const withAvatars = (...profiles) => signed("avatars", profiles, "avatar_url", "avatar_src");
export const setAvatar = async (profile, file) => {
  const path = await upload("avatars", profile.id, file, 512);
  const p = ok(await sb.from("profiles").update({ avatar_url: path }).eq("id", profile.id).select().single());
  if (profile.avatar_url) await sb.storage.from("avatars").remove([profile.avatar_url]); // old one; fine if it fails
  return (await withAvatars(p))[0];
};

// Pairing
export const createInvite = async () => ok(await sb.rpc("create_invite"));
export const joinCouple = async (code) => ok(await sb.rpc("join_couple", { invite_code: code }));
// RLS only returns rows for my own couple, so this lists me and (if joined) my partner.
export const getCouple = async (userId) => {
  const rows = ok(await sb.from("couple_members").select("couple_id, user_id"));
  if (!rows.length) return null;
  const partnerId = rows.find((r) => r.user_id !== userId)?.user_id;
  const partner = partnerId ? ok(await sb.from("profiles").select("id, name, avatar_url, activity_prefs, budget_pref").eq("id", partnerId).maybeSingle()) : null;
  const couple = ok(await sb.from("couples").select("started_on").eq("id", rows[0].couple_id).single());
  return { coupleId: rows[0].couple_id, partner, startedOn: couple.started_on };
};
export const setStartedOn = async (coupleId, date) =>
  ok(await sb.from("couples").update({ started_on: date }).eq("id", coupleId));

// Explore: radius search (powers the distance slider)
export const placesNearby = async ({ lat, lng, radiusKm, maxTier = 3, category = null }) =>
  ok(await sb.rpc("places_nearby", { lat, lng, radius_km: radiusKm, max_tier: maxTier, cat: category }));

// Wishlist + "It's a Match!"
export const saveToWishlist = async (coupleId, placeId, userId) =>
  ok(await sb.from("wishlist").insert({ couple_id: coupleId, place_id: placeId, user_id: userId }));
export const removeFromWishlist = async (placeId, userId) =>
  ok(await sb.from("wishlist").delete().match({ place_id: placeId, user_id: userId }));
export const getMatches = async () => ok(await sb.from("wishlist_matches").select("place_id"));
export const listWishlist = async () => ok(await sb.from("wishlist").select("place_id, user_id"));
export const onWishlistChange = (coupleId, cb) =>
  sb.channel("wishlist-" + coupleId)
    .on("postgres_changes", { event: "INSERT", schema: "public", table: "wishlist", filter: `couple_id=eq.${coupleId}` }, cb)
    .subscribe();

// Check-ins (private ones are hidden from your partner by RLS)
export const addCheckIn = async (coupleId, userId, mood, note, shared = true) =>
  ok(await sb.from("check_ins").insert({ couple_id: coupleId, user_id: userId, mood, note, shared }));
export const listCheckIns = async () =>
  ok(await sb.from("check_ins").select("*").order("created_at", { ascending: false }).limit(60));

// Pet + games
export const getPet = async () => ok(await sb.from("pets").select("*").maybeSingle());
export const setPet = async (coupleId, fields) =>
  ok(await sb.from("pets").update(fields).eq("couple_id", coupleId).select().single());
export const feedPet = (coupleId, pet) => setPet(coupleId, { xp: pet.xp + 10, happiness: Math.min(100, pet.happiness + 5) });
export const recordGame = async (coupleId, game, points) =>
  ok(await sb.from("game_sessions").insert({ couple_id: coupleId, game, points }));

// Memories. Photos go in the private "memories" bucket under <couple_id>/, and are shown through
// short-lived signed links (see 003_together_and_photos.sql).
export const listMemories = async () =>
  signed("memories", ok(await sb.from("memories").select("*").order("occurred_on", { ascending: false })));
export const addMemory = async (coupleId, userId, title, occurredOn, file) => {
  const photo_path = file ? await upload("memories", coupleId, file, 1600) : null;
  return ok(await sb.from("memories").insert({ couple_id: coupleId, author_id: userId, title, occurred_on: occurredOn, photo_path }));
};
export const deleteMemory = async (m) => {
  ok(await sb.from("memories").delete().eq("id", m.id));
  if (m.photo_path) ok(await sb.storage.from("memories").remove([m.photo_path]));
};

// Capsules (contents are locked server-side until unlock_at). Photos: capsules/<couple_id>/<capsule_id>/<file>,
// which storage also refuses to show before unlock (see 005_capsule_photos_and_avatars.sql).
export const createCapsule = async (coupleId, userId, title, unlockAt, firstNote, file) => {
  const c = ok(await sb.from("capsules").insert({ couple_id: coupleId, created_by: userId, title, unlock_at: unlockAt }).select().single());
  if (firstNote || file) await addCapsuleNote(coupleId, c.id, userId, firstNote, file);
  return c;
};
export const listCapsules = async () => ok(await sb.from("capsules").select("*").order("unlock_at"));
export const addCapsuleNote = async (coupleId, capsuleId, userId, body, file) => { // refused once unlocked
  const photo_path = file ? await upload("capsules", `${coupleId}/${capsuleId}`, file, 1600) : null;
  return ok(await sb.from("capsule_items").insert({ capsule_id: capsuleId, author_id: userId, body: body || null, photo_path }));
};
export const openCapsule = async (capsuleId) => // empty until unlock_at passes
  signed("capsules", ok(await sb.from("capsule_items").select("*").eq("capsule_id", capsuleId).order("created_at")));
