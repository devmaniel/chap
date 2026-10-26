## Why

Voice calls are part of the core journey. The call screen exists but fakes the call. ElevenLabs will run the live call (listening, thinking and speaking) directly from the app, but its key must not ship inside the app, and the call must sound and behave like the friend the user is calling.

## What Changes

- The server hands the app a short-lived ElevenLabs call pass plus the friend's personality, first line and voice.
- The app starts the ElevenLabs call with that pass; ElevenLabs does the thinking during the call.
- When a call ends, a call record (with its length) is saved in the chat.
- Mobile: microphone permission, ElevenLabs SDK in the call flow, real connection state for the existing "call dropped" UI.

Not included: putting the call's words into the chat, the chat history reaching the call, recording audio, renewing very long calls.

## Capabilities

### New Capabilities
- `voice-calls`: start a live voice call with a friend and keep a record of it in the chat.

### Modified Capabilities
- None.

## Impact

- Server: ElevenLabs client, `messages.call_duration_seconds`, `/api/chats/{slug}/call` and `/api/chats/{slug}/calls`.
- Mobile: ElevenLabs agents SDK, microphone permission strings, remote call methods in the chat repository.
- Setup outside code: one shared ElevenLabs agent with overrides allowed, one voice picked per friend.
- Depends on: `add-chats`.
