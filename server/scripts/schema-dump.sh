#!/usr/bin/env bash
# Regenerates src/main/resources/db/schema/schema.sql: replays every migration
# into a throwaway empty database, then dumps the schema plus the
# flyway_schema_history rows and the reference data migrations insert (the six
# characters). Never edit the snapshot by hand; run this instead.
set -euo pipefail
cd "$(dirname "$0")/.."

name=chap-schema-dump
port=55432
docker run -d --rm --name "$name" -p "$port:5432" \
  -e POSTGRES_DB=chap -e POSTGRES_USER=chap -e POSTGRES_PASSWORD=chap postgres:17 >/dev/null
trap 'docker stop "$name" >/dev/null' EXIT
# TCP check: the image's init-time server only listens on a socket, then restarts.
until docker exec "$name" pg_isready -q -h 127.0.0.1 -U chap -d chap; do sleep 1; done

./mvnw -q flyway:migrate -Dflyway.url="jdbc:postgresql://localhost:$port/chap"

# \restrict / \unrestrict carry a random nonce per dump; they are psql guards, not schema.
{
  docker exec "$name" pg_dump -U chap -d chap --schema-only --no-owner --no-privileges
  docker exec "$name" pg_dump -U chap -d chap --data-only --no-owner \
    --table=flyway_schema_history --table=characters
} | grep -v -E '^\\(un)?restrict' > src/main/resources/db/schema/schema.sql
