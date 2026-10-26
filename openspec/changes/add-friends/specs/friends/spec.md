## ADDED Requirements

### Requirement: Built-in characters
The server SHALL provide the six starting characters (Mina, Bo, Momo, Pip, Vera, Ziggy) to every user, each clearly an AI character, without exposing their hidden personality instructions.

#### Scenario: Browse Discover
- **WHEN** a signed-in user opens Discover
- **THEN** they see all six characters with name, tagline, bio, interests, home, voice and first hello

#### Scenario: Personality stays hidden
- **WHEN** the app loads the characters
- **THEN** the response contains no personality instructions

### Requirement: Add a friend
A user SHALL be able to add a character to their friends.

#### Scenario: Add Vera
- **WHEN** a user adds Vera
- **THEN** Vera shows as their friend on Discover and in their friends list, and stays a friend after reopening the app

#### Scenario: Add twice
- **WHEN** a user adds a character who is already their friend
- **THEN** nothing changes and no error is shown

#### Scenario: Unknown character
- **WHEN** the app asks to add a character id that does not exist
- **THEN** the server responds `404` with `character_not_found`

### Requirement: Remove a friend
A user SHALL be able to remove a character from their friends without losing the conversation with them.

#### Scenario: Remove Mina
- **WHEN** a user removes Mina
- **THEN** Mina no longer shows as their friend, and their chat with Mina is still in the inbox

### Requirement: Friend lists are per user
Each user's friend list SHALL be independent.

#### Scenario: Two users
- **WHEN** user A adds Bo and user B has not
- **THEN** Bo shows as a friend for A and not for B
