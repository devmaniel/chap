## ADDED Requirements

### Requirement: Local database through Docker
The server SHALL run against a PostgreSQL database started with Docker Compose, with its schema created only by Flyway migrations.

#### Scenario: Fresh laptop setup
- **WHEN** a developer runs `docker compose up -d` and then `./mvnw spring-boot:run` in `server/`
- **THEN** the server starts, Flyway applies every migration, and Hibernate schema validation passes

#### Scenario: Schema snapshot matches migrations
- **WHEN** a database is built by replaying migrations and another is built from the snapshot plus `flyway:migrate`
- **THEN** their `pg_dump --schema-only` outputs are identical

### Requirement: Health check
The server SHALL expose `GET /api/health` that reports whether it can reach its database.

#### Scenario: Database reachable
- **WHEN** the app calls `GET /api/health` and the database is up
- **THEN** the server responds `200` with `{ "status": "ok" }`

#### Scenario: Database down
- **WHEN** the app calls `GET /api/health` and the database is unreachable
- **THEN** the server responds `503` with code `database_unavailable`

### Requirement: One error shape
Every failed request SHALL return a JSON body `{ "code", "message" }` with a matching HTTP status, and SHALL NOT include stack traces.

#### Scenario: Invalid request body
- **WHEN** a request body fails validation
- **THEN** the server responds `400` with code `invalid_request`

#### Scenario: Unexpected failure
- **WHEN** an unhandled exception occurs
- **THEN** the server responds `500` with code `internal_error` and no internal details

### Requirement: Starts without AI keys
The server SHALL start when the Gemini and ElevenLabs keys are missing; only the features that need them SHALL fail.

#### Scenario: No keys configured
- **WHEN** the server starts with `GEMINI_API_KEY` and `ELEVENLABS_API_KEY` unset
- **THEN** startup succeeds and `GET /api/health` returns `200`

### Requirement: App reaches the server
The mobile app SHALL send every server request through one service whose server address is set at build time.

#### Scenario: Server unreachable
- **WHEN** the app makes a request and the server cannot be reached
- **THEN** the call returns an error result instead of crashing, which repositories report as offline
