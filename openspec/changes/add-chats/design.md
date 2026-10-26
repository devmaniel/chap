## Context

The app's `ChatRepository` already splits sending from replying: `sendMessage(chatId, text, …)` returns your stored message, then `getReply(chatId)` waits for the friend's answer. The app uses the character id as the chat id (one chat per friend), and shows a "typing" state and a reply-error state already. The server should fit that flow rather than change it.

## Goals / Non-Goals

**Goals:**
- Real, in-character Gemini replies.
- History survives app restarts and works across devices for the same account.

**Non-Goals:**
- Streaming replies, deleting chats, memory review/opt-out, moderation beyond Gemini's built-in safety and the persona rules.

## Decisions

- **Tables**:
  - `conversations`: `id UUID PK`, `user_id → users ON DELETE CASCADE`, `character_id → characters ON DELETE RESTRICT`, `last_read_at TIMESTAMPTZ NULL`, `created_at`, `updated_at`, `UNIQUE (user_id, character_id)`, index on `character_id`. `last_read_at` is a fact about this user's own conversation, not a counter.
  - `messages`: `id UUID PK`, `conversation_id → conversations ON DELETE CASCADE`, `sender TEXT NOT NULL CHECK (sender IN ('user','friend'))`, `body TEXT NOT NULL`, `post_ref TEXT NULL` (id of an app-side post the message replies to), `sent_at TIMESTAMPTZ NOT NULL DEFAULT now()`, `created_at`, `updated_at`, index on `(conversation_id, sent_at)`.
  - Last message, last message time and unread count are computed at read time, never stored.
- **Chat id in the API is the character slug** (`/api/chats/mina`), matching the app.
- **Endpoints**:
  - `GET /api/chats` → `[{ id, friendName, friendVoice, lastMessage, unreadCount }]`, newest first. `lastMessage` is a full message (`{ id, text, sentAt, isFromYou, postId }`), so the app keeps building its own preview line ("Replied to a post", later "Shared a photo", "Voice call").
  - `PUT /api/chats/{slug}` → creates the chat with the friend's `first_hello` as the first friend message if missing; returns the chat. Idempotent. Unknown slug → `404 character_not_found`; every other chat endpoint answers `404 chat_not_found` for an unknown slug or a chat the user hasn't started.
  - `GET /api/chats/{slug}` → one chat summary.
  - `GET /api/chats/{slug}/messages` → oldest first.
  - `POST /api/chats/{slug}/read` → sets `last_read_at = now()`, `204`.
  - `POST /api/chats/{slug}/messages` `{ text, postId? }` → `201` your stored message.
  - `POST /api/chats/{slug}/reply` → `200` the friend's stored reply.
- **Unread** = friend messages with `sent_at > last_read_at` (all friend messages when null).
- **Message limits**: text up to 2000 chars, not blank after trim, except that a reply to a post may have no text (the app already lets you send a post reply on its own). Images come in a later change.
- **Inbox computed per chat**: a few small queries per chat (at most six chats per user) instead of one native SQL query.
- **Reply flow**: the service method is not transactional. Loading the persona and last 30 messages and saving the reply each run in their own repository transaction, and Gemini is called in between, outside any transaction. If the latest message is already from the friend, respond `409 nothing_to_answer`.
- **Gemini**: plain `RestClient` call to `generateContent` (no SDK), model from `GEMINI_MODEL` (default `gemini-2.5-flash`), `x-goog-api-key` header, 30 s timeout. `systemInstruction` = shared rules (a constant in `ChatService`) + character persona. History mapped to `user` / `model` turns; a post reply is prefixed "(replying to your post)". The base URL is a property (`chap.gemini.base-url`, defaulting to Google's) so tests can point the client at a local fake.
- **Errors**: key missing → `503 ai_unavailable`; Gemini error, timeout or blocked/empty answer → `502 ai_failed`. Nothing is saved for a failed reply, so the user can retry.
- **Mobile**: `ChatRepositoryRemote` in `data/repositories/chat/` keeps the existing in-memory caches and drafts, calls the server for chats/messages/reply, and `startChat` becomes `PUT /api/chats/{slug}`. Portraits come from the app's bundled assets. The chat view model calls a new `markRead(chatId)` when the chat is shown and after a reply arrives while it is shown, and loads messages whenever they aren't cached yet (the inbox knows chats before their messages). Photo-library methods delegate to `PhotoLibraryService` unchanged; picked photos aren't sent until `add-image-messages`. Calls still ring locally, and the call record stays in the app session only until `add-voice-call-pass`. The `CHAT_SCENARIO` dev flags go away with the local fake.

## Risks / Trade-offs

- Gemini latency of several seconds → the app already shows a typing state.
- Only the last 30 messages reach Gemini → older details fade; acceptable without a memory feature.
- `post_ref` points at app-side posts the server can't read → Gemini only knows "this replies to your post", not its content.
