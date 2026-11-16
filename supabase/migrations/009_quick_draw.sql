-- Quick Draw: one partner draws a secret word, the other guesses it (3 tries).
-- Run in the Supabase SQL editor after 008_couple_challenges.sql. Safe to run twice.
-- The word is stored separately (drawing_secrets), readable by the guesser only once the round is over,
-- and the app can only write through the two functions below, so nobody can peek or cheat.

create table if not exists drawings (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references couples on delete cascade,
  drawer_id uuid not null references auth.users on delete cascade,
  strokes jsonb not null,             -- [{c: colour, w: width, p: [x1,y1,x2,y2,...]}], coordinates 0-1000
  hint text,                          -- category shown to the guesser, e.g. "Food"
  shape text,                         -- letters per word, e.g. "3,5" for "ice cream"
  tries smallint not null default 0,
  guess text,                         -- latest guess
  guesser_id uuid references auth.users,
  correct boolean,                    -- set when the round ends
  guessed_at timestamptz,             -- set when the round ends (right, or out of tries)
  created_at timestamptz default now()
);
create index if not exists drawings_couple on drawings (couple_id, created_at desc);

create table if not exists drawing_secrets (
  drawing_id uuid primary key references drawings on delete cascade,
  word text not null
);

alter table drawings enable row level security;
alter table drawing_secrets enable row level security;

drop policy if exists "drawings read" on drawings;
drop policy if exists "drawings delete own" on drawings;
drop policy if exists "secret word read" on drawing_secrets;
create policy "drawings read" on drawings for select using (couple_id = my_couple());
create policy "drawings delete own" on drawings for delete using (drawer_id = auth.uid());
-- The drawer always sees the word; the guesser only after the round is over.
create policy "secret word read" on drawing_secrets for select using (
  exists (select 1 from drawings d where d.id = drawing_id and d.couple_id = my_couple()
          and (d.drawer_id = auth.uid() or d.guessed_at is not null)));

-- Save a new drawing and its secret word together.
create or replace function create_drawing(p_strokes jsonb, p_word text, p_hint text, p_shape text) returns uuid
language plpgsql security definer set search_path = public as $$
declare cid uuid := my_couple(); did uuid := gen_random_uuid();
begin
  if cid is null then raise exception 'Pair with your partner first'; end if;
  if length(p_strokes::text) > 400000 then raise exception 'That drawing is too big'; end if;
  insert into drawings (id, couple_id, drawer_id, strokes, hint, shape) values (did, cid, auth.uid(), p_strokes, p_hint, p_shape);
  insert into drawing_secrets (drawing_id, word) values (did, lower(trim(p_word)));
  return did;
end $$;

-- Check a guess. Ignores case, spaces and punctuation, and accepts a plural ("pizzas" for "pizza").
-- Returns {correct, tries_left, word}; word is only filled in once the round is over.
create or replace function guess_drawing(p_id uuid, p_guess text) returns json
language plpgsql security definer set search_path = public as $$
declare drawer uuid; n smallint; w text; g text; ok boolean; finished boolean;
begin
  drawer := (select drawer_id from drawings where id = p_id and couple_id = my_couple());
  if drawer is null then raise exception 'Drawing not found'; end if;
  if drawer = auth.uid() then raise exception 'You drew this one'; end if;
  if (select guessed_at from drawings where id = p_id) is not null then raise exception 'Already guessed'; end if;
  n := (select tries from drawings where id = p_id) + 1;
  w := (select regexp_replace(lower(word), '[^a-z]', '', 'g') from drawing_secrets where drawing_id = p_id);
  g := regexp_replace(lower(coalesce(p_guess, '')), '[^a-z]', '', 'g');
  ok := g <> '' and (g = w or g = w || 's' or g || 's' = w);
  finished := ok or n >= 3;
  update drawings set tries = n, guess = left(p_guess, 60), guesser_id = auth.uid(),
         correct = case when finished then ok end, guessed_at = case when finished then now() end
   where id = p_id;
  return json_build_object('correct', ok, 'tries_left', 3 - n,
         'word', case when finished then (select word from drawing_secrets where drawing_id = p_id) end);
end $$;
