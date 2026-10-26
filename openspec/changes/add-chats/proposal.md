## Why

Chatting is the core of Chap. Today replies are canned lines picked by the app. Users need real replies in each friend's own personality, and conversations that are still there when they come back.

## What Changes

- Adding a friend starts a chat that opens with the friend's first hello.
- Inbox: every chat, newest first, with the last message and an unread count.
- Opening a chat shows the full history and marks it read.
- Sending a message saves it; asking for a reply sends the friend's personality plus recent messages to Gemini, saves the answer, and returns it.
- Gemini runs only on the server; its key never reaches the app.
- Mobile: `ChatRepositoryRemote` replaces `ChatRepositoryLocal` for chats and text messages.

Not included: word-by-word (streaming) replies, deleting chats, long-term memory controls, search on the server.

## Capabilities

### New Capabilities
- `chats`: inbox, conversation history, and AI replies in character.

### Modified Capabilities
- None.

## Impact

- Server: `conversations` and `messages` tables, Gemini client, `/api/chats/*`.
- Mobile: new remote chat repository for chats and text; photo library helpers stay as they are.
- Depends on: `add-friends`.
