#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
compose=(docker compose --project-directory "$deployment_dir" --env-file "$env_path" -f "$deployment_dir/compose.yaml")

"$deployment_dir/scripts/validate.sh"
"${compose[@]}" up -d postgres redis minio
"${compose[@]}" run --rm minio-init
# Chatwoot intentionally runs as a non-superuser; only this approved preparation
# step creates the extensions its schema requires.
# shellcheck disable=SC2016
"${compose[@]}" exec -T postgres sh -ec '
  PGPASSWORD="$POSTGRES_PASSWORD" psql --username "$POSTGRES_USER" --dbname "$CHATWOOT_DATABASE" <<SQL
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector;
SQL
'
"${compose[@]}" run --rm rails bundle exec rails db:chatwoot_prepare
"${compose[@]}" up -d rails sidekiq caddy
printf 'Chatwoot core services started; run scripts/bootstrap.sh to create tenants and start the Claude agent.\n'
