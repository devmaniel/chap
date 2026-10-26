## 1. Database

- [x] 1.1 Migration: `users` and `user_credentials` tables with `updated_at` triggers
- [x] 1.2 Regenerate the schema snapshot and run the replay-vs-snapshot diff

## 2. Server

- [x] 2.1 Add `spring-boot-starter-security-oauth2-resource-server` (Boot 4 name, includes security); security config with public `/api/health` and `/api/auth/**`
- [x] 2.2 `User` and `UserCredential` entities and repositories
- [x] 2.3 `TokenService` (issue + JWT decoder config from `JWT_SECRET`, 30-day expiry)
- [x] 2.4 `AuthService`: sign up (lowercase email, BCrypt, `EmailTakenException`), sign in (`WrongCredentialsException`), current user lookup
- [x] 2.5 `AuthController` (`/api/auth/sign-up`, `/api/auth/sign-in`) and `MeController` (`/api/me`) with request/response records and validation
- [x] 2.6 Tests: sign-up, duplicate email in different case, short password, sign-in success, wrong password and unknown email give the same error, `/api/me` without token is `401`
- [x] 2.7 `./mvnw verify` passes

## 3. Mobile

- [x] 3.1 Add `flutter_secure_storage`
- [x] 3.2 `ApiService` sends the stored token and reports `401`
- [x] 3.3 `AuthRepositoryRemote`: sign up, sign in, sign out, `isAuthenticated` via stored token + `/api/me`; map `email_taken`, `wrong_credentials`, offline
- [x] 3.4 Wire `AuthRepositoryRemote` in `config/dependencies.dart`; remove the hard-coded test account
- [x] 3.5 Tests in `test/data/repositories/auth/auth_repository_remote_test.dart`
- [x] 3.6 `flutter analyze` and `flutter test` pass
