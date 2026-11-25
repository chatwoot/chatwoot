#!/bin/sh

set -x

# Hold the worker until the schema it is about to load is the current one.
#
# ActiveRecord reads a model's columns once and keeps them for the life of the process, so
# a worker that loads Conversation one migration behind carries that schema until it is
# restarted. Every write that needs the new column then raises NoMethodError, and only the
# paths that CREATE a record reach it: an inbox with existing threads keeps receiving, and
# the loss surfaces as dead jobs nobody is watching. Measured on a real deploy: 672 history
# import jobs and 12 live messages dropped over eighty minutes, with nothing on the inbox
# saying so.
#
# docker-compose.coolify.yaml also states this as `depends_on: condition: service_healthy`,
# and that is not enough on its own. Coolify strips `depends_on` from the compose it
# actually deploys (verified on the stack that hit the bug), and docker does not re-apply
# the ordering when a single container is restarted later. The gate has to live somewhere
# it cannot be dropped, which is here.
#
# Reached from the image's ENTRYPOINT (docker/entrypoints/docker-entrypoint.sh), which
# dispatches by argv, so every deployment of this image gets the gate whether or not its
# compose knows this file exists. That indirection is the point: while this was wired from
# docker-compose.coolify.yaml and nowhere else, the protection was present exactly where
# somebody had remembered it, and it went missing twice.
#
# docker-compose.production.yaml stays untouched on purpose. It is upstream's file and
# names upstream's image, which has no such script; pointing its worker here by name would
# break every deployment that runs it as checked in. Running that same file against this
# fork's image does get the gate, because the gate travels in the image.
#
# The Rails container owns the migrations; this one only waits for them. A worker that
# comes up alone against a database nobody is migrating waits forever, on purpose: the
# wait shows up as an unhealthy container instead of as a worker quietly writing against
# the wrong schema. That only holds because the healthcheck drops this script from its
# match -- while the wait runs, PID 1 is still `sh docker/entrypoints/sidekiq.sh bundle
# exec sidekiq ...`, which a plain grep for sidekiq is happy to call a worker.

# enterprise/ arrives at boot (see docker/entrypoints/helpers/enterprise.sh). Composes use
# this script as the entrypoint itself, so it does not rely on docker-entrypoint.sh for it;
# when both run, the second call finds the tree in place and returns.
docker/entrypoints/helpers/enterprise.sh ensure || exit 1

# Let DATABASE_URL env take presedence over individual connection params.
$(docker/entrypoints/helpers/pg_database_url.rb)
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

echo "Waiting for postgres to become ready...."

until $PG_READY
do
  sleep 2;
done

echo "Database ready to accept connections."

echo "Waiting for the schema to exist...."

# Asking Rails whether the schema is current is itself a write on an empty database, and
# that is what broke every fresh install. `rake db:abort_if_pending_migrations` boots a db:
# task, and booting one against a database with no tables CREATES ar_internal_metadata and
# schema_migrations. `db:chatwoot_prepare` (lib/tasks/db_enhancements.rake), which the web
# container runs, decides whether the database is fresh by `table_exists?
# 'ar_internal_metadata'` -- so a worker that got there first made the web container skip
# the schema load and run every migration from InitSchema instead. That path dies on
# 20231211010807_add_cached_labels_list, which calls ActsAsTaggableOn::Taggable::Cache,
# removed in acts-as-taggable-on 12 (the Gemfile pins no version). The web container then
# crash-loops with `uninitialized constant`, and it reads as a broken image rather than as
# a race. Measured on a fresh install: an empty database, then those two tables and nothing
# else after the rake.
#
# `rails runner` only connects, so it can ask the question without answering it: measured
# on the same empty database, it creates no table. Wait on a schema_migrations that exists
# AND has rows, which is the web container having finished loading the schema, and only
# then ask the real gate below.
until bundle exec rails runner "exit(ActiveRecord::Base.connection.table_exists?('schema_migrations') && ActiveRecord::Base.connection.select_value('SELECT 1 FROM schema_migrations LIMIT 1') ? 0 : 1)"
do
  sleep 5;
done

echo "Waiting for the schema to be current...."

until bundle exec rake db:abort_if_pending_migrations
do
  sleep 5;
done

echo "Schema is current. Starting the worker."

# The WhatsApp connector rides in this container unless told otherwise
# (docker/entrypoints/helpers/whatsapp_connector.rb says how). An installation that runs the
# connector as its own service sets WHATSAPP_CONNECTOR_EMBEDDED=false, or a second connector
# with none of the pairings would compete with the first for the same sessions.
if [ "${WHATSAPP_CONNECTOR_ENABLED:-true}" != "false" ] && [ "${WHATSAPP_CONNECTOR_EMBEDDED:-true}" != "false" ]; then
  exec docker/entrypoints/helpers/whatsapp_connector.rb "$@"
fi

# Execute the main process of the container
exec "$@"
