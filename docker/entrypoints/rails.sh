#!/bin/sh

set -x

# Remove a potentially pre-existing server.pid for Rails.
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

echo "Waiting for postgres to become ready...."

PGPASSWORD=$POSTGRES_PASSWORD
PSQL="pg_isready -h $POSTGRES_HOST -p 5432 -U $POSTGRES_USERNAME"
until $PSQL
do
  sleep 2;
done

echo "Database ready to accept connections."

BUNDLE="bundle check"

until $BUNDLE
do
  sleep 2;
done

# Execute the main process of the container
exec "$@"
