## Context

No `server/` folder exists. AGENTS.md fixes the stack (Spring Boot, Java 21, Maven, PostgreSQL, Flyway) and the package layout, but leaves the base package unchosen. The mobile app already has abstract repositories with `_local` implementations; remote implementations arrive slice by slice.

## Goals / Non-Goals

**Goals:**
- `docker compose up -d` + `./mvnw spring-boot:run` gives a working server on a fresh laptop.
- A phone or emulator can reach the server.
- Missing AI keys never stop the server from starting.

**Non-Goals:**
- Hosting, HTTPS, CI.
- Any product feature.

## Decisions

- **Base package `com.chap.server`.** Matches the product name in the PRD. Update AGENTS.md §4.1 in the same change.
- **Spring Boot 4.1.2** (Initializr no longer offers 3.5), dependencies: webmvc, validation, data-jpa, flyway (+ flyway-database-postgresql), postgresql driver; Testcontainers for tests. Actuator is NOT used — a plain `GET /api/health` controller is enough. The Flyway Maven plugin is configured so `./mvnw flyway:migrate` works.
- **Docker Compose** at `server/docker-compose.yml`: `postgres:17`, database `chap`, user/password `chap`/`chap` (local only), host port `5434` (5432 and 5433 are often taken by other local Postgres installs), named volume.
- **Config** in `application.yml` with env overrides: `DB_URL`, `DB_USER`, `DB_PASSWORD`, `GEMINI_API_KEY`, `ELEVENLABS_API_KEY`, `ELEVENLABS_AGENT_ID`. Keys default to empty. `spring.jpa.hibernate.ddl-auto=validate`, `open-in-view=false`.
- **Error shape**: `{ "code": "snake_case_code", "message": "Readable text" }`. Services throw `DomainException(kind, code, message)`; `kind` is a business category (`INVALID`, `NOT_FOUND`, `CONFLICT`, …), never an HTTP type. One `@RestControllerAdvice` (extending Spring's `ResponseEntityExceptionHandler`) maps kinds to statuses. Spring MVC failures: unknown path → `404 not_found`, other 4xx (validation, bad JSON) → `400 invalid_request`. Unknown errors → `500 internal_error` with no stack trace in the body.
- **Health**: `GET /api/health` `HealthService` asks `HealthRepository` (a `JdbcTemplate` `SELECT 1`, since SQL stays in the repository layer), returns `{ "status": "ok" }` or `503 database_unavailable`.
- **First migration** `V1__baseline.sql` creates the shared `set_updated_at()` trigger function every later table uses for `updated_at`.
- **Schema scripts**: `server/scripts/schema-dump.sh` (replay migrations into an empty DB, `pg_dump --schema-only` plus `flyway_schema_history` rows, strip `\restrict`/`\unrestrict`) and `server/scripts/schema-load.sh`. Snapshot at `server/src/main/resources/db/schema/schema.sql`.
- **Mobile `ApiService`** in `data/services/api_service.dart` wraps `package:http`. Base URL from `--dart-define=API_BASE_URL`, default `http://10.0.2.2:8080` on Android emulator and `http://localhost:8080` on iOS simulator. Returns decoded JSON as `Result<Object?>`; error bodies become `ApiException(status, code)`; an unreachable server comes back as `http.ClientException`. Like `PhotoLibraryService`, it returns raw errors and each repository maps them (`ClientException` → `OfflineException`). It holds the auth token once accounts exist.

## Risks / Trade-offs

- Real phones can't reach `localhost` → documented `API_BASE_URL` override with the laptop's LAN IP.
- Spring Boot version drift → pin in `pom.xml`, don't upgrade during the hackathon.
