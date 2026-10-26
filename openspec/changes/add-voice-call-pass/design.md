## Context

Decided: ElevenLabs does the thinking during calls (its own agent model), and the voice runs in the app. The app's `ChatRepository` already has `startCall(chatId)`, `isCallOnline`, and `endCall(chatId, duration)` which returns a call-record message. The ElevenLabs key and agent id stay on the server.

## Goals / Non-Goals

**Goals:**
- A live call where each friend has their own voice and personality.
- No ElevenLabs secret in the app.

**Non-Goals:**
- Call transcripts in the chat, chat context in the call, audio recording, call renewal past provider limits.

## Decisions

- **One shared ElevenLabs agent** ("Chap friends", created through the ElevenLabs API) whose system prompt is `{{friend_prompt}}` and first message `{{greeting}}`. Each call fills both in as dynamic variables and overrides only the voice (the only override the agent allows). Authentication is on, so calls need a server-issued token. Less setup than six agents.
- **Why dynamic variables, not overrides** (found by testing against ElevenLabs over its WebSocket API): the Flutter SDK 0.6.1 sends `agent.prompt` as a plain string, and ElevenLabs rejects it ("validation error", connection closed); it expects `agent.prompt.prompt`. Separately, a `first_message` override was refused ("not allowed by config") even with it enabled. Dynamic variables plus a voice override worked: the friend greeted with the passed greeting, used the passed persona, and said it was a fictional AI when asked.
- **Voice per friend** lives in `characters.elevenlabs_voice_id` (added in `add-friends`), set by `V8__friend_voices.sql` from ElevenLabs premade voices: Mina = Charlie, Bo = Brian, Pip = Sarah, Vera = Alice, Momo = River, Ziggy = Liam.
- **Schema**: migration adds `messages.call_duration_seconds INTEGER NULL CHECK (call_duration_seconds >= 0)` — a fact about that message (a call record). Body is empty for call records.
- **Endpoints**:
  - `POST /api/chats/{slug}/call` → `{ conversationToken, prompt, firstMessage, voiceId }`. Server fetches a conversation token with `GET https://api.elevenlabs.io/v1/convai/conversation/token?agent_id=<ELEVENLABS_AGENT_ID>` and the `xi-api-key` header; the answer is `{ "token": … }` (confirmed in the Flutter SDK source, `elevenlabs_agents` 0.6.1). `prompt` = shared rules + call rules ("this is a live voice call: speak briefly and naturally") + persona; the chat-only rules (text-message style, post and photo notes) are left out. `firstMessage` = "Hey, it's <name>!". The friend must have a chat with the user (`404 chat_not_found` otherwise).
  - Both endpoints live in `ChatController` / `ChatService`, reusing its chat lookups and rules, rather than a separate `CallService`.
  - `POST /api/chats/{slug}/calls` `{ durationSeconds }` → `201` the stored call-record message (from the user, like the app does today). Every message now carries `callDurationSeconds` (null unless a call record). In a later chat reply, Gemini sees a call record as "(we had a voice call, 2:31)", never as an empty message.
- **Errors**: missing key, agent id or friend voice → `503 call_unavailable`; ElevenLabs request failure → `502 call_failed`.
- **Mobile**: add the official ElevenLabs agents Flutter SDK (`elevenlabs_agents`) behind a `VoiceCallService`, and microphone permission strings (iOS `NSMicrophoneUsageDescription`, Android `RECORD_AUDIO` + `MODIFY_AUDIO_SETTINGS`). The main Android manifest also gets `INTERNET`, which only the debug manifest had, so release builds can reach the server. `startCall` asks for the microphone first (`permission_handler`, enabled on iOS with `PERMISSION_MICROPHONE=1` in the Podfile, and pinned to `^12.0.1` because 13.x's Android part needs Android Gradle Plugin 9 and the app is on 8.11), then gets the pass, starts the session with `dynamicVariables: {friend_prompt, greeting}` and `TtsOverrides(voiceId)`, and completes when connected. `isCallOnline` follows the SDK status. The SDK only reports connected or disconnected: a short blip it recovers from on its own isn't visible, and a call that fully drops shows the connection-lost state until the user hangs up (it doesn't come back). `endCall` ends the session and posts the duration. Denial returns a `MicrophoneDeniedException` the call screen shows as an error. Mute, speaker and the talking indicators stay simulated on the call screen; they are not wired to the SDK in this change.
- **Verify the SDK API at build time**: confirm the current token endpoint and override field names against ElevenLabs docs before coding; adjust names, not the design.

## Risks / Trade-offs

- The persona prompt is sent to the app for the call → it is not secret, so acceptable; the API key still never leaves the server.
- ElevenLabs uses its own model, so a friend may sound slightly different in calls than in chat → accepted trade for a one-day build.
- The call doesn't know what was said in the chat → listed as the first follow-up.
