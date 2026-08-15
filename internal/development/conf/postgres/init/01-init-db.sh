#!/usr/bin/env bash
set -euo pipefail

: "${POSTGRES_EXPORTER_USERNAME:?POSTGRES_EXPORTER_USERNAME is required}"
: "${POSTGRES_EXPORTER_PASSWORD:?POSTGRES_EXPORTER_PASSWORD is required}"

psql \
  --username "$POSTGRES_USER" \
  --dbname "$POSTGRES_DB" \
  --set=db_name="$POSTGRES_DB" \
  --set=exporter_username="$POSTGRES_EXPORTER_USERNAME" \
  --set=exporter_password="$POSTGRES_EXPORTER_PASSWORD" <<'SQL'
REVOKE ALL ON DATABASE :'db_name' FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

SELECT format(
  'CREATE ROLE %I LOGIN PASSWORD %L', :'exporter_username', :'exporter_password'
) WHERE NOT EXISTS (
  SELECT 1 FROM pg_roles WHERE rolname = :'exporter_username'
)\gexec

ALTER ROLE :'exporter_username' WITH LOGIN PASSWORD :'exporter_password';

GRANT pg_monitor TO :'exporter_username';
SQL
