## 1. Database

- [x] 1.1 Migration: `characters` and `user_friends` tables with indexes and `updated_at` triggers
- [x] 1.2 Migration: insert the six characters with profile text from the app sample data and a persona for each from the PRD
- [x] 1.3 Regenerate the schema snapshot and run the replay-vs-snapshot diff

## 2. Server

- [x] 2.1 `AiCharacter` and `UserFriend` entities and repositories
- [x] 2.2 `CharacterService`: list with `isFriend` for the user, add, remove, unknown slug → `character_not_found`
- [x] 2.3 `CharacterController` (`GET /api/characters`) and `FriendController` (`PUT`/`DELETE /api/friends/{slug}`) with response records that exclude `persona`
- [x] 2.4 Tests: list shows six, persona never returned, add/remove idempotent, unknown slug `404`, per-user isolation
- [x] 2.5 `./mvnw verify` passes

## 3. Mobile

- [x] 3.1 `CharacterRepositoryRemote`: `getCharacters` merges server fields with bundled portrait/posts/friend circle; `setFriend` calls the server; `setLiked` stays local
- [x] 3.2 Wire it in `config/dependencies.dart`; trim sample character data to the app-side parts
- [x] 3.3 Tests in `test/data/repositories/character/character_repository_remote_test.dart`
- [x] 3.4 `flutter analyze` and `flutter test` pass
