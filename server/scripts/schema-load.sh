#!/usr/bin/env bash
# Loads the schema snapshot into the local compose database, which must be empty
# (docker compose down -v && docker compose up -d). Always follow with
# ./mvnw flyway:migrate to apply migrations newer than the snapshot.
set -euo pipefail
cd "$(dirname "$0")/.."

until docker compose exec -T postgres pg_isready -q -h 127.0.0.1 -U chap -d chap; do sleep 1; done
docker compose exec -T postgres psql -q -v ON_ERROR_STOP=1 -U chap -d chap \
  < src/main/resources/db/schema/schema.sql > /dev/null
