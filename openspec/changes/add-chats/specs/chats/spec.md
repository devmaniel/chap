## ADDED Requirements

### Requirement: Chat starts with a hello
Adding a friend SHALL start one chat with them that opens with their first hello. A user SHALL have at most one chat per friend.

#### Scenario: First time adding Vera
- **WHEN** a user adds Vera and has no chat with her
- **THEN** a chat with Vera appears in the inbox with her first hello as the only message, marked unread

#### Scenario: Re-adding a friend
- **WHEN** a user removes Mina and adds her again
- **THEN** the existing chat and its history are kept and no second hello is added

### Requirement: Inbox
The inbox SHALL list every chat the user has, newest activity first, each with the last message, its time, and the number of unread friend messages.

#### Scenario: New reply arrives
- **WHEN** Bo replies in a chat the user is not viewing
- **THEN** Bo's chat moves to the top with his reply as the last message and an unread count of at least 1

#### Scenario: No chats yet
- **WHEN** a new user with no friends opens the inbox
- **THEN** the list is empty

### Requirement: Conversation history
Opening a chat SHALL show all its messages oldest first and mark the chat read. History SHALL persist across app restarts and devices for the same account.

#### Scenario: Come back later
- **WHEN** a user signs in on another phone and opens their chat with Pip
- **THEN** they see the same messages as before

#### Scenario: Open an unread chat
- **WHEN** a user opens a chat with 2 unread messages
- **THEN** its unread count becomes 0

### Requirement: Send a message
A user SHALL be able to send a text message of 1 to 2000 characters in a chat.

#### Scenario: Send text
- **WHEN** a user sends "How was your day?" to Momo
- **THEN** the message is saved and shown as theirs

#### Scenario: Empty or too long
- **WHEN** a user sends a blank message or one over 2000 characters
- **THEN** the server rejects it with `invalid_request` and nothing is saved

### Requirement: In-character AI reply
After the user's message, the friend SHALL reply using their own personality and the recent conversation. The friend SHALL never claim to be human, and SHALL NOT pressure or guilt the user into continuing.

#### Scenario: Reply in character
- **WHEN** a user tells Vera "I have an interview tomorrow"
- **THEN** Vera's reply is direct and blunt in her style and relates to the interview

#### Scenario: Asked if they are real
- **WHEN** a user asks Bo "Are you a real person?"
- **THEN** Bo says, in character, that he is a fictional AI friend

#### Scenario: Nothing to answer
- **WHEN** a reply is requested but the latest message is already from the friend
- **THEN** the server responds `409` with `nothing_to_answer`

### Requirement: Reply failures are recoverable
A failed reply SHALL save nothing and SHALL let the user try again.

#### Scenario: AI key not configured
- **WHEN** a reply is requested and the server has no Gemini key
- **THEN** the server responds `503` with `ai_unavailable` and the app shows its reply error

#### Scenario: AI request fails
- **WHEN** Gemini errors, times out, or returns no usable answer
- **THEN** the server responds `502` with `ai_failed`, and a retry can produce the reply

### Requirement: Chats are private
A user SHALL only see and write to their own chats.

#### Scenario: Chat with someone not started
- **WHEN** a user requests messages for a friend they have no chat with
- **THEN** the server responds `404` with `chat_not_found`
