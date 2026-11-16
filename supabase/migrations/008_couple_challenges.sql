-- Daily couple challenges. Run in the Supabase SQL editor after 007_activities.sql. Safe to run twice.
-- The challenge text lives in the app; this stores who did which one, on which day, and their answer.

create table if not exists challenge_log (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references couples on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  day date not null,
  challenge text not null,           -- the challenge's key in the app's list
  answer text,                       -- reply to a question challenge, or an optional note
  created_at timestamptz default now(),
  unique (user_id, day)              -- one per person per day
);
alter table challenge_log enable row level security;

-- Did I complete the challenge on day d? (security definer so policies can ask without recursion)
create or replace function answered_on(d date) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from challenge_log where user_id = auth.uid() and day = d)
$$;

-- Has my partner completed day d? Lets the app say "Sam answered" without revealing the answer.
create or replace function partner_done(d date) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from challenge_log
                 where couple_id = my_couple() and user_id <> auth.uid() and day = d)
$$;

-- You always see your own entries. Your partner's answer for a day only becomes visible
-- once you've done that day's challenge too, so neither of you can copy the other.
drop policy if exists "challenge read" on challenge_log;
drop policy if exists "challenge add" on challenge_log;
drop policy if exists "challenge edit" on challenge_log;
create policy "challenge read" on challenge_log for select
  using (couple_id = my_couple() and (user_id = auth.uid() or answered_on(day)));
create policy "challenge add" on challenge_log for insert
  with check (couple_id = my_couple() and user_id = auth.uid());
create policy "challenge edit" on challenge_log for update
  using (user_id = auth.uid()) with check (user_id = auth.uid() and couple_id = my_couple());
