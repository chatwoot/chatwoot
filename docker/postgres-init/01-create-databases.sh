#!/bin/sh
# CUSTOMIZAÇÃO_SYNAPSEOS — cria databases adicionais no boot do Postgres.
# Roda apenas em volume virgem (Postgres entrypoint só executa /docker-entrypoint-initdb.d/
# quando POSTGRES_DATA está vazio). Pra deploys existentes usar a rake task
# `synapseos:provision_companion_dbs`.

set -e

# Lista de databases adicionais que o ecossistema precisa (n8n, gateway, etc.).
# Mantida idempotente via WHERE NOT EXISTS pra ser segura mesmo se script for
# replayed manualmente.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-SQL
  SELECT 'CREATE DATABASE n8n'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'n8n')\gexec

  SELECT 'CREATE DATABASE dexi_gateway'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'dexi_gateway')\gexec
SQL

echo "[synapseos] companion databases ensured: n8n, dexi_gateway"
