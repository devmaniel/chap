## Context

The app's `CharacterRepository` exposes `getCharacters()` and `setFriend(id, isFriend)`, and identifies characters by slugs like `mina`. The `Character` model also carries a portrait asset, posts, post count, likes and a character-to-character friend list. The PRD lists likes and feeds as outside the first version, and there is one day left, so those stay app-side.

## Goals / Non-Goals

**Goals:**
- One source of truth for the six friends' profiles and personalities.
- Per-user friend lists.

**Non-Goals:**
- Creating custom friends (parked in the PRD).
- Posts, likes, character-to-character friendships on the server.

## Decisions

- **Tables**:
  - `characters`: `id UUID PK`, `slug TEXT UNIQUE NOT NULL` (`mina`…), `name`, `tagline`, `bio`, `home`, `voice_label` ("Warm & gentle"), `first_hello`, `persona TEXT NOT NULL` (the AI's character brief), `interests TEXT[] NOT NULL`, `elevenlabs_voice_id TEXT NULL` (filled by a later migration once voices are picked), `created_at`, `updated_at`.
  - `user_friends`: `user_id UUID REFERENCES users ON DELETE CASCADE`, `character_id UUID REFERENCES characters ON DELETE RESTRICT`, `created_at`, `updated_at`, `PRIMARY KEY (user_id, character_id)`, index on `character_id`.
- **Seeding**: the six characters are reference data the app cannot run without, so they are inserted by a migration (not a fixture). Profile text is copied from the current app sample data; `persona` is written from the PRD's life / pros / cons / practice notes and holds only that friend's own brief. The shared rules (fictional AI, never claims to be human, no guilt or pressure to keep talking, short chat-style replies) are added in code when the chat or call prompt is built (`add-chats`, `add-voice-call-pass`).
- **Snapshot carries the seed**: `schema-dump.sh` also dumps the `characters` rows, so a database built from the snapshot has the six friends.
- **Entity name**: `AiCharacter` (table `characters`), since `Character` clashes with `java.lang.Character`.
- **API uses the slug as the character id**, so the app's ids don't change.
  - `GET /api/characters` → list of `{ id: slug, name, tagline, bio, interests, home, voice, firstHello, isFriend }`. `persona` is never sent.
  - `PUT /api/friends/{slug}` → `204`, idempotent.
  - `DELETE /api/friends/{slug}` → `204`, idempotent.
  - Unknown slug → `404 character_not_found` (a `DomainException`, like every other error).
  - The server lists characters by name; the app shows them in its bundled order, so Discover keeps its layout.
- **Removing a friend keeps the chat.** It only takes them off the friends list, like unfriending in a messaging app. (Matches current app behavior.)
- **Mobile**: `CharacterRepositoryRemote` merges server fields with bundled app-side data (portrait asset, profile picture, posts, post count, friend circle) keyed by slug. A server character the app has no bundled portrait for is skipped. `setLiked` stays local. The `CHARACTER_SCENARIO=load-error` dev flag goes away with the local fake.

## Risks / Trade-offs

- Profile text exists in two places (bundled posts vs. server profile) → acceptable while posts stay app-side; only the server's fields are authoritative.
- Persona text quality decides how distinct the friends feel → write it carefully once, tune via a later migration.
