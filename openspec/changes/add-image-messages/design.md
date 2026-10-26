## Context

The user decided images live in the mobile app, not on the server. The app's `Message` model carries `imagePaths` (local files on the phone), and the repository's `getReply(chatId)` is a separate call from `sendMessage`. Gemini needs the image bytes at the moment it writes the reply.

## Goals / Non-Goals

**Goals:**
- The friend's reply is grounded in what the photo actually shows.
- The server never stores photo contents.

**Non-Goals:**
- Showing photos on another device, cloud storage, image moderation beyond Gemini's own.

## Decisions

- **Table** `message_images`: `message_id → messages ON DELETE CASCADE`, `position SMALLINT NOT NULL CHECK (position BETWEEN 0 AND 3)`, `device_ref TEXT NOT NULL` (the app's local path), `created_at`, `updated_at`, `PRIMARY KEY (message_id, position)`. A reference to a file on the user's phone, not the image.
- **Send**: `POST /api/chats/{slug}/messages` accepts `{ text, postId?, imageRefs?: string[] }`. Text may be empty when at least one image ref is present (or, from `add-chats`, when it replies to a post). Max 4 refs, else `400 invalid_request`. Every message in responses carries `imageRefs` (empty when none).
- **Reply**: `POST /api/chats/{slug}/reply` also accepts `multipart/form-data` with up to 4 `images` parts. Each part: `image/jpeg`, `image/png`, `image/webp` or `image/heic`, max 5 MB. Wrong type, size or count → `400 invalid_image`, checked before Gemini is called. Bytes are sent to Gemini as `inlineData` (before the text) on the latest user turn and dropped after the request. `ChatService` owns the 5 MB rule; Spring's multipart limit is set higher (10 MB per file, 50 MB per request) only to stop absurd uploads early, and an upload over it also answers `invalid_image`.
- **Older photo messages** reach Gemini as text only: "(shared 2 photos)". Only the newest message's photos are seen as images.
- **Mobile**: `sendMessage` sends `imagePaths` as `imageRefs`. `getReply` reads the latest own message's files, shrinks them to JPEG with a new `ImageCompressService` (wrapping `flutter_image_compress`, which also reads HEIC), and posts them as multipart through `ApiService.postImages`. The shorter side is capped at 1200 px, so a 4:3 photo comes out 1600 × 1200. A missing file (deleted from the phone) is skipped. History shows photos from `device_ref`; a missing file shows a placeholder (image icon on a neutral fill, labelled "Photo N unavailable") instead of Flutter's error box.
- **Retry**: a failed reply saves nothing; retrying re-sends the same photos from the phone.

## Risks / Trade-offs

- Photos disappear from history if deleted on the phone, and never appear on a second phone → accepted by the "images stay in the app" decision.
- Gemini only sees the newest photos, so "remember the photo from yesterday?" won't work → acceptable without a memory feature.
- Large uploads on slow networks → downscaling on the phone keeps requests small.
