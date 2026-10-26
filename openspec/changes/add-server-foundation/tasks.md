## 1. Server project

- [x] 1.1 Create `server/` Spring Boot 4.1.2 project with Maven wrapper, Java 21, base package `com.chap.server`, and the AGENTS.md package folders
- [x] 1.2 Add `server/docker-compose.yml` with `postgres:17`, database/user/password `chap`, named volume
- [x] 1.3 Add `application.yml`: datasource from env with local defaults, `ddl-auto: validate`, `open-in-view: false`, empty-default AI key properties
- [x] 1.4 Add `.gitignore` entries for `server/target/` and any local env file
- [x] 1.5 Update AGENTS.md §4.1 base package to `com.chap.server`

## 2. Database

- [x] 2.1 Add `V1__baseline.sql` with the `set_updated_at()` trigger function
- [x] 2.2 Add `server/scripts/schema-dump.sh` and `server/scripts/schema-load.sh`
- [x] 2.3 Generate `server/src/main/resources/db/schema/schema.sql` with the dump script
- [x] 2.4 Run the AGENTS.md §2.4 replay-vs-snapshot diff and confirm no output

## 3. Health and errors

- [x] 3.1 Add `DomainException` (kind + code) and `GlobalExceptionHandler` (`@RestControllerAdvice`) for domain, validation, and unknown errors
- [x] 3.2 Add `HealthRepository`, `HealthService` and `HealthController` for `GET /api/health`
- [x] 3.3 Add tests: health returns 200 with DB up; validation error returns `invalid_request`; server starts with no AI keys
- [x] 3.4 `./mvnw verify` passes

## 4. Mobile

- [x] 4.1 Add `http` dependency
- [x] 4.2 Add `data/services/api_service.dart`: base URL from `API_BASE_URL` dart-define with emulator defaults, JSON get/post/put/delete returning `Result`, unreachable server → `ClientException` (repositories map to `OfflineException`), error bodies → `ApiException`
- [x] 4.3 Add `test/data/services/api_service_test.dart` with a mock HTTP client
- [x] 4.4 `flutter analyze` and `flutter test` pass

## 5. Docs

- [x] 5.1 Add `server/README.md` with the three-command setup and the env variable list
