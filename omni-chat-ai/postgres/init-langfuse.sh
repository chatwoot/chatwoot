#!/bin/bash
# Langfuse and the AI service each need their own database alongside Chatwoot's. Postgres runs
# this once, on first init (empty data dir). Idempotent via \gexec so a re-run is harmless.
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-'EOSQL'
  SELECT 'CREATE DATABASE langfuse'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'langfuse')\gexec
  SELECT 'CREATE DATABASE omni_ai'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'omni_ai')\gexec
EOSQL
