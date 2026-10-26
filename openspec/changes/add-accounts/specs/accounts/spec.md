## ADDED Requirements

### Requirement: Sign up
A visitor SHALL be able to create an account with a name, email and password. Emails SHALL be treated case-insensitively.

#### Scenario: New email
- **WHEN** a visitor signs up with name "Melco", email "Melco@Example.com" and an 8+ character password
- **THEN** the account is created with email "melco@example.com" and the user is signed in

#### Scenario: Email already used
- **WHEN** a visitor signs up with an email that already has an account, in any letter case
- **THEN** sign-up fails with `email_taken` and the app shows the "email taken" error

#### Scenario: Password too short
- **WHEN** a visitor signs up with a 7-character password
- **THEN** sign-up fails with `invalid_request` and no account is created

### Requirement: Sign in
A user SHALL be able to sign in with their email and password. A failed sign-in SHALL NOT reveal whether the email exists.

#### Scenario: Correct credentials
- **WHEN** a user signs in with their email and correct password
- **THEN** they are signed in and land in the app

#### Scenario: Wrong password or unknown email
- **WHEN** a user signs in with a wrong password, or with an email that has no account
- **THEN** both cases fail the same way with `wrong_credentials`

### Requirement: Session survives restart
A signed-in user SHALL stay signed in after closing and reopening the app until they sign out or the session expires.

#### Scenario: Reopen the app
- **WHEN** a signed-in user closes and reopens the app
- **THEN** they skip sign-in and see their chats

#### Scenario: Expired session
- **WHEN** the app's session is no longer accepted by the server
- **THEN** the app signs the user out and shows sign-in

### Requirement: Sign out
A signed-in user SHALL be able to sign out, after which the app no longer acts as that user.

#### Scenario: Sign out
- **WHEN** a user signs out
- **THEN** the app forgets the session and shows sign-in

### Requirement: Private data
Every request other than health, sign-up and sign-in SHALL require a signed-in user, and SHALL only read or change that user's own data.

#### Scenario: No session
- **WHEN** a request without a valid session asks for user data
- **THEN** the server responds `401`

#### Scenario: Another user's data
- **WHEN** user A requests a chat or friend record that belongs to user B
- **THEN** the server responds `404`, as if it does not exist
