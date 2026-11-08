#!/bin/sh
# Staging only (DEV-Johnstocker/chatwoot#37). Runs once, on an empty volume.
# ai-service gets its own role and database, not the superuser; pgvector is
# created here by the superuser so the ai_service role needs no extra rights.
set -eu
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -v pw="$AI_DB_PASSWORD" <<'SQL'
CREATE ROLE ai_service LOGIN PASSWORD :'pw';
CREATE DATABASE ai_service OWNER ai_service;
\c ai_service
CREATE EXTENSION IF NOT EXISTS vector;
SQL
