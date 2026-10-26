## Why

Sharing a moment is part of the core journey: a user sends a photo and the friend talks about what is actually in it. The app can already pick photos and show them in the chat, but replies to photos are canned.

## What Changes

- A message can carry up to 4 photos, with or without text.
- Photos stay on the phone. The server only remembers which phone photos belonged to which message, so the chat can show them again.
- When the friend replies, the app sends the photos of the latest message along with the reply request; the server passes them to Gemini and does not keep them.
- Mobile: `ChatRepositoryRemote` sends photo references with the message and photo bytes with the reply.

Not included: cloud photo storage, photos showing on a second phone, the friend sending photos.

## Capabilities

### New Capabilities
- `image-messages`: send photos in a chat and get a reply about what they show.

### Modified Capabilities
- None (`chats` is not archived yet; this change adds alongside it).

## Impact

- Server: `message_images` table, multipart reply endpoint, Gemini inline image parts.
- Mobile: remote chat repository send/reply paths.
- Depends on: `add-chats`.
