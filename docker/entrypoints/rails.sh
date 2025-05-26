#!/bin/sh

set -x

# Remove a potentially pre-existing server.pid for Rails.
rm -rf /app/tmp/pids/server.pid
rm -rf '/app/tmp/cache/*'

echo 'Waiting for postgres to become ready....'
export POSTGRES_PORT=5432
PG_READY="pg_isready -h pgvector -p 5432 -U postgres"

until $PG_READY
do
  echo "Waiting for postgres to become ready...."
  sleep 2
done

echo 'Database ready to accept connections.'

# Executa as migrações do banco de dados
bundle exec rails db:migrate

#install missing gems for local dev as we are using base image compiled for production
bundle install

BUNDLE="bundle check"

until $BUNDLE
do
  sleep 2;
done

# Execute the main process of the container
exec "$@"
