## Context

The app's `AuthRepository` already defines `signUp(name, email, password)`, `signIn(email, password)`, `signOut()`, `isAuthenticated`, and the errors `WrongCredentialsException`, `EmailTakenException`, `OfflineException`. The sign-up form requires a valid email and a password of at least 8 characters. The server must match these, not redesign them.

## Goals / Non-Goals

**Goals:**
- Basic email + password accounts that work end to end today.
- No user can read or change another user's data.

**Non-Goals:**
- Password reset, email verification, refresh tokens, rate limiting, account deletion.

## Decisions

- **Tables** (table purity, AGENTS.md §2.1):
  - `users`: `id UUID PK`, `name TEXT NOT NULL`, `email TEXT NOT NULL UNIQUE` (stored lowercase, `CHECK (email = lower(email))`), `created_at`, `updated_at`.
  - `user_credentials`: `user_id UUID PK REFERENCES users ON DELETE CASCADE`, `password_hash TEXT NOT NULL`, `created_at`, `updated_at`. Password hash is auth state, so it does not live on `users`.
- **Hashing**: BCrypt from `spring-security-crypto`.
- **Session**: a signed JWT (HS256) holding the user id, valid 30 days, no refresh. Verified by Spring Security's OAuth2 resource server. Secret from `JWT_SECRET`; a local-only default in `application.yml`, documented as "must be set anywhere real".
- **Sign-out** is client-side: the app deletes its token. No server endpoint, no token blocklist (acceptable for a demo).
- **Endpoints**:
  - `POST /api/auth/sign-up` `{ name, email, password }` → `201 { token, user }`; `409 email_taken`.
  - `POST /api/auth/sign-in` `{ email, password }` → `200 { token, user }`; `401 wrong_credentials` for unknown email or wrong password alike.
  - `GET /api/me` → `{ id, name, email }`; used on app start to check the stored token.
- **Validation**: name 1–50 chars after trim; email matches the app's pattern; password 8–72 chars (72 is BCrypt's limit).
- **Security config**: `/api/health` and `/api/auth/**` are public, everything else needs a valid token, so an unknown path without a token is `401`, not `404`. A missing or invalid token gets `401 unauthorized` in the usual error shape. The token's subject becomes the request principal, so controllers take `@AuthenticationPrincipal UUID userId`; services take the user id as a parameter and scope every query by it.
- **Deleted account**: `/api/me` with a valid token for a user that no longer exists (e.g. after a local database reset) is `401 unauthorized`, so the app signs out instead of getting stuck.
- **Mobile**: `AuthRepositoryRemote` in `data/repositories/auth/`. Token stored with `flutter_secure_storage`, used directly (no wrapper service; tests use `FlutterSecureStorage.setMockInitialValues`). `ApiService` holds the token and adds `Authorization: Bearer <token>`. A `401` on any request that carried a token calls `ApiService.onUnauthorized`, which the repository uses to sign out locally (`notifyListeners`), sending the user back to sign-in. On app start a stored token is checked with `/api/me`; if the server can't be reached the token is kept.

## Risks / Trade-offs

- A stolen token works for 30 days and sign-out cannot revoke it → acceptable for a hackathon demo, noted as a follow-up.
- No rate limit on sign-in → brute force is possible; out of scope for one day.
