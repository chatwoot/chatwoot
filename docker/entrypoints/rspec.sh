#!/usr/bin/env bash

set -x

# Remove a potentially pre-existing server.pid for Rails.
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/webpacker/*

PGPASSWORD=$POSTGRES_PASSWORD
PSQL="pg_isready -h $POSTGRES_HOST -p 5432 -U $POSTGRES_USERNAME"
until $PSQL
do
  echo "Waiting for postgres to become ready...."
  sleep 2;
done

echo "Database ready to accept connections."

# create the aeon development databases
bundle exec rails db:create db:migrate

# Execute the main process of the container
exec "$@"
