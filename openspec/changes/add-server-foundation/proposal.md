## Why

The app runs on built-in sample data. Every later slice (accounts, friends, chats, images, calls) needs a running server and database first. The deadline is one day away, so the foundation must be small and boring.

## What Changes

- New `server/` Spring Boot project (Java 21, Maven wrapper).
- PostgreSQL runs locally through Docker Compose.
- Flyway owns the schema; Hibernate only validates it.
- One health endpoint that proves the server is up and can reach the database.
- One error format for every failed request, from a single `@RestControllerAdvice`.
- AI keys (Gemini, ElevenLabs) are read from environment variables. The server starts without them; features that need them say "unavailable" instead of crashing.
- Schema snapshot scripts: `schema-dump.sh` and `schema-load.sh`.
- Mobile: one HTTP service that knows the server address, used by every later remote repository.

## Capabilities

### New Capabilities
- `server-foundation`: the server starts, reaches its database, reports health, and returns errors in one shape.

### Modified Capabilities
- None.

## Impact

- New folder `server/`.
- Mobile: new `http` dependency and `data/services/api_service.dart`. No screen changes.
- Depends on: nothing. Every other change depends on this one.
