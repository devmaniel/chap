# Chap server

Spring Boot 4 + Java 21 + PostgreSQL 17. Needs Docker and a JDK 21; Maven comes with the wrapper.

## Run it

```sh
docker compose up -d        # PostgreSQL on localhost:5434
./mvnw spring-boot:run      # applies migrations, serves on localhost:8080
curl localhost:8080/api/health   # {"status":"ok"}
```

Tests: `./mvnw verify` (starts its own throwaway database through Testcontainers).

## Environment variables

All optional locally. The server starts without the AI keys; only the features that need them report themselves unavailable.

| Variable | Default | Purpose |
|---|---|---|
| `DB_URL` | `jdbc:postgresql://localhost:5434/chap` | Database |
| `DB_USER` / `DB_PASSWORD` | `chap` / `chap` | Database login |
| `JWT_SECRET` | a local-only value | Signs session tokens. Set it (32+ characters) anywhere real |
| `GEMINI_API_KEY` | empty | Chat replies |
| `GEMINI_MODEL` | `gemini-2.5-flash` | Chat replies |
| `ELEVENLABS_API_KEY` | empty | Voice calls |
| `ELEVENLABS_AGENT_ID` | empty | Voice calls |

## Voice calls (ElevenLabs)

Calls use one shared ElevenLabs agent ("Chap friends"); each call turns it into the friend being called. The app only ever gets a short-lived call token.

The agent is set up like this (already done for the current account):

1. System prompt `{{friend_prompt}}` and first message `{{greeting}}`. The app fills both in per call as dynamic variables.
2. Security: authentication on, and only the voice override allowed. Don't use the prompt or first-message overrides: ElevenLabs rejects the prompt override as the Flutter SDK sends it.
3. Each friend's voice is `characters.elevenlabs_voice_id`, set by migration. A friend without one answers `call_unavailable`.
4. `ELEVENLABS_API_KEY` and `ELEVENLABS_AGENT_ID` live in `server/.env` (git-ignored), which the server reads on start.

## Schema

Migrations in `src/main/resources/db/migration/` are the source of truth. After adding one, regenerate the snapshot with `./scripts/schema-dump.sh`; never edit `db/schema/schema.sql` by hand. `./scripts/schema-load.sh` loads the snapshot into an empty local database (follow it with `./mvnw flyway:migrate`).

## Phone to server

The app calls `http://localhost:8080` (iOS simulator) or `http://10.0.2.2:8080` (Android emulator). On a real phone, run the app with `--dart-define=API_BASE_URL=http://<laptop-ip>:8080`.
