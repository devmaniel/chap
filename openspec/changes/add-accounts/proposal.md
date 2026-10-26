## Why

Friends, chats and calls belong to one person. The app already has sign-up and sign-in screens running on a fake local account; they need a real account on the server so each user only sees their own data.

## What Changes

- Sign up with name, email and password.
- Sign in with email and password.
- Sign out (the app forgets its session).
- Every other server request requires a signed-in user and only touches that user's data.
- Mobile: `AuthRepositoryRemote` replaces `AuthRepositoryLocal`; the session survives an app restart.

Not included: password reset, email confirmation, changing email or password, deleting the account, social login.

## Capabilities

### New Capabilities
- `accounts`: sign up, sign in, sign out, and per-user data isolation.

### Modified Capabilities
- None.

## Impact

- Server: `users` and `user_credentials` tables, Spring Security, `/api/auth/*` and `/api/me`.
- Mobile: new remote auth repository, secure token storage, `ApiService` sends the token.
- Depends on: `add-server-foundation`.
