#!/bin/sh

set -x

# Remove a potentially pre-existing pid.
rm -rf /app/tmp/pids/sidekiq.pid

# Let DATABASE_URL env take presedence over individual connection params.
$(docker/entrypoints/helpers/pg_database_url.rb)
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

until $PG_READY
do
  sleep 2;
done

echo "Database ready to accept connections."

# Wait until the rails boot process has applied migrations.
# Without this gate, sidekiq can start (and pick up scheduled jobs like
# Inboxes::FetchImapEmailInboxesJob) against an un-migrated database and fail
# with "relation \"inboxes\" does not exist". Rails runs the migrations in its
# own entrypoint, so we simply poll until the schema is present.
echo "Waiting for migrations to be applied by the rails container..."
until bundle exec rails runner \
  "exit(ActiveRecord::Base.connection.table_exists?('inboxes') ? 0 : 1)" 2>/dev/null
do
  echo "Migrations not applied yet — sleeping 5s..."
  sleep 5
done

echo "Schema is up to date. Starting sidekiq."

# Execute the main process of the container
exec "$@"
