## Why

The six friends (Mina, Bo, Momo, Pip, Vera, Ziggy) are hard-coded in the app, and "is my friend" lives only in memory. The server needs to own who the characters are, including the hidden personality each one uses when talking, and which of them each user has added.

## What Changes

- The six friends become reference data in the database, added by a migration, each with a personality description for the AI.
- Users can list the characters (with "is my friend" for them), add a friend, and remove a friend.
- Mobile: `CharacterRepositoryRemote` loads characters and friend status from the server. Portraits, timeline posts, likes and the characters' own friend circles stay bundled in the app for now.

## Capabilities

### New Capabilities
- `friends`: browse the built-in characters, add and remove them as friends.

### Modified Capabilities
- None.

## Impact

- Server: `characters` and `user_friends` tables, `/api/characters`, `/api/friends/{characterId}`.
- Mobile: new remote character repository; sample character data shrinks to the parts the server doesn't own.
- Depends on: `add-accounts`.
