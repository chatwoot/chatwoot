#!/bin/sh

# CUSTOMIZAÇÃO_SYNAPSEOS — entrypoint de produção (VPS).
#
# Diferença pro rails.sh (dev): não roda `bundle install` nem limpa cache
# — a imagem já vem com as gems compiladas. Só espera o Postgres ficar
# pronto e repassa o comando (puma ou sidekiq).

set -e

rm -rf /app/tmp/pids/server.pid

echo "Waiting for postgres to become ready..."

# Resolve DATABASE_URL a partir das POSTGRES_* (mantém compat com rails.sh).
$(docker/entrypoints/helpers/pg_database_url.rb)
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

until $PG_READY
do
  sleep 2
done

echo "Database ready."

exec "$@"
