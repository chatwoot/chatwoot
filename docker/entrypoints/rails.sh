#!/bin/sh
 
set -x
 
# Remove a potentially pre-existing server.pid for Rails.
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*
 
mkdir -p /app/tmp/pids
 
echo "Waiting for postgres to become ready...."
 
# Let DATABASEURL env take presedence over individual connection params._
# This is done to avoid printing the DATABASEURL in the logs_
$(docker/entrypoints/helpers/pg_database_url.rb)
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"
 
until $PG_READY
do
sleep 2;
done
 
echo "Database ready to accept connections."
 
if [ ! -f public/vite/manifest.json ] || [ ! -s public/vite/manifest.json ]; then
echo "Vite manifest missing or empty - building assets..."
bundle exec vite build
fi
 
exec "_$@_"