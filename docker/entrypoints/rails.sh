#!/bin/sh

set -x

# enterprise/ arrives at boot (see docker/entrypoints/helpers/enterprise.sh). This script is
# also used as an entrypoint of its own, so it cannot count on docker-entrypoint.sh having
# done it, and it has to happen before db:chatwoot_prepare boots Rails.
docker/entrypoints/helpers/enterprise.sh ensure || exit 1

# Remove a potentially pre-existing server.pid for Rails.
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

echo "Waiting for postgres to become ready...."

# Let DATABASE_URL env take presedence over individual connection params.
# This is done to avoid printing the DATABASE_URL in the logs
$(docker/entrypoints/helpers/pg_database_url.rb)
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

until $PG_READY
do
  sleep 2;
done

echo "Database ready to accept connections."

#install missing gems for local dev as we are using base image compiled for production
bundle install

BUNDLE="bundle check"

until $BUNDLE
do
  sleep 2;
done

# Run pending migrations before starting the server so that workers
# (sidekiq) that depend on the rails healthcheck never see a stale schema.
echo "Running db:chatwoot_prepare..."
bundle exec rake db:chatwoot_prepare
echo "Database preparation complete."

# Execute the main process of the container
exec "$@"
