## 1. Database

- [x] 1.1 Migration: `conversations` and `messages` tables with constraints, indexes and `updated_at` triggers
- [x] 1.2 Regenerate the schema snapshot and run the replay-vs-snapshot diff

## 2. Server

- [x] 2.1 `Conversation` and `Message` entities and repositories, including the inbox query (last message, unread count)
- [x] 2.2 `GeminiClient` (`@Component` in `service`) wrapping `generateContent` with key, model and timeout from config; `ai_unavailable` / `ai_failed` exceptions
- [x] 2.3 `ChatService`: start chat with first hello, list, get, history, mark read, send, reply (read → Gemini outside transaction → save)
- [x] 2.4 Shared persona rules text (fictional AI, no human claims, no guilt or pressure, short chat replies) combined with each character's persona
- [x] 2.5 `ChatController` for the seven `/api/chats` endpoints with request/response records
- [x] 2.6 Tests with a stubbed Gemini client: start is idempotent, inbox order and unread, mark read, send limits, reply saved, `nothing_to_answer`, `ai_unavailable`, `ai_failed` saves nothing, other user's chat `404`
- [x] 2.7 `./mvnw verify` passes

## 3. Mobile

- [x] 3.1 Add `markRead(chatId)` to `ChatRepository` and call it when a chat opens
- [x] 3.2 `ChatRepositoryRemote`: chats, chat, start, messages, send, reply via the server; drafts and caches in memory; photo methods via `PhotoLibraryService`; call methods unchanged for now
- [x] 3.3 Wire it in `config/dependencies.dart`; remove sample chats and messages
- [x] 3.4 Tests in `test/data/repositories/chat/chat_repository_remote_test.dart`
- [x] 3.5 `flutter analyze` and `flutter test` pass

## 4. Verify

- [ ] 4.1 With a real Gemini key: add a friend, send a message, get an in-character reply, restart the app, history is still there
