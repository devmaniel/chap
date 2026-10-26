## ADDED Requirements

### Requirement: Start a voice call
A user SHALL be able to start a live voice call with a friend they have a chat with, hearing that friend's own voice and personality.

#### Scenario: Call Ziggy
- **WHEN** a user taps call in their chat with Ziggy and allows the microphone
- **THEN** the call connects, Ziggy greets them in his voice, and they can talk back and forth

#### Scenario: Microphone denied
- **WHEN** a user starts a call and denies microphone access
- **THEN** the call does not start and the app shows the call error

#### Scenario: Calls not set up
- **WHEN** a user starts a call and the server has no ElevenLabs key, agent, or voice for that friend
- **THEN** the server responds `503` with `call_unavailable` and the app shows the call error

### Requirement: Call secrets stay on the server
The app SHALL start calls with a short-lived pass from the server and SHALL NOT contain the ElevenLabs API key.

#### Scenario: Inspect the app build
- **WHEN** the shipped app is inspected
- **THEN** no ElevenLabs API key is present in it

### Requirement: Friends stay honest on calls
During a call, the friend SHALL follow the same rules as in chat: they are a fictional AI and do not pressure the user to keep talking.

#### Scenario: Asked if they are real
- **WHEN** a user asks Vera during a call whether she is a real person
- **THEN** Vera says, in character, that she is a fictional AI friend

### Requirement: Call record in the chat
When a call ends, the chat SHALL show a record of the call with its length.

#### Scenario: Hang up
- **WHEN** a user hangs up after 2 minutes 31 seconds
- **THEN** the chat shows a call record of 02:31, and it is still there after reopening the app

### Requirement: Dropped connection is visible
The call screen SHALL show when the connection drops and when it comes back.

#### Scenario: Network blip
- **WHEN** the phone loses its connection during a call
- **THEN** the call screen shows the connection-lost state until it reconnects or the user hangs up
