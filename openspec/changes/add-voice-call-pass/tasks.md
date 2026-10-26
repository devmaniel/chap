## 1. Database

- [x] 1.1 Migration: add `messages.call_duration_seconds`
- [x] 1.2 Regenerate the schema snapshot and run the replay-vs-snapshot diff

## 2. Server

- [x] 2.1 Confirm the ElevenLabs conversation-token endpoint and override fields in current docs
- [x] 2.2 `ElevenLabsClient` (`@Component` in `service`) fetching a conversation token; `call_unavailable` / `call_failed` exceptions
- [x] 2.3 `CallService`: build the call pass (token, prompt, first message, voice) and save a call record
- [x] 2.4 `POST /api/chats/{slug}/call` and `POST /api/chats/{slug}/calls`; messages return `callDurationSeconds`
- [x] 2.5 Tests with a stubbed ElevenLabs client: pass contents, missing config `503`, provider failure `502`, call record saved, other user's chat `404`
- [x] 2.6 `./mvnw verify` passes

## 3. Mobile

- [x] 3.1 Add the ElevenLabs agents Flutter SDK and microphone permission strings for iOS and Android
- [x] 3.2 `ChatRepositoryRemote.startCall` / `isCallOnline` / `endCall` backed by the SDK and the server
- [x] 3.3 Remove the fake ring, failure and drop scenarios from `config/dependencies.dart`
- [x] 3.4 Tests for the call methods with a fake SDK session
- [x] 3.5 `flutter analyze` and `flutter test` pass

## 4. Setup and verify

- [x] 4.1 Document in `server/README.md`: create one ElevenLabs agent with overrides allowed, set `ELEVENLABS_API_KEY` and `ELEVENLABS_AGENT_ID`
- [x] 4.2 Migration setting `elevenlabs_voice_id` for the six friends once voices are picked
- [x] 4.3 On a real phone: call a friend, hear their voice, talk, hang up, see the call record
