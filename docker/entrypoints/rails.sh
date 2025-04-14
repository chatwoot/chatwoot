#!/bin/sh
set -x

# Remove any pre-existing server.pid and clear cache.
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

echo "Waiting for postgres to become ready...."

# If DATABASE_URL is set, parse out connection details.
if [ -n "$DATABASE_URL" ]; then
  echo "DATABASE_URL found: $DATABASE_URL"
  # For example, if DATABASE_URL is in the form postgres://username:password@host:port/dbname,
  # extract host, port, and username.
  export POSTGRES_HOST=$(echo "$DATABASE_URL" | sed -n 's#.*@\([^:/]\+\).*#\1#p')
  export POSTGRES_PORT=$(echo "$DATABASE_URL" | sed -n 's#.*:\([0-9]\+\)/.*#\1#p')
  export POSTGRES_USERNAME=$(echo "$DATABASE_URL" | sed -n 's#.*//\([^:]*\):.*#\1#p')
fi

# Debug output – remove in production if needed.
echo "Parsed POSTGRES_HOST: $POSTGRES_HOST"
echo "Parsed POSTGRES_PORT: $POSTGRES_PORT"
echo "Parsed POSTGRES_USERNAME: $POSTGRES_USERNAME"

# Construct the pg_isready command.
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

# Wait until the database is ready.
until $PG_READY; do
  sleep 2
done

echo "Database ready to accept connections."

# Install any missing gems.
bundle install

# Ensure gems are available.
BUNDLE="bundle check"
until $BUNDLE; do
  sleep 2
done

echo "Running database migrations..."
bundle exec rails db:chatwoot_prepare

mkdir -p /app/tmp/pids
# Finally, execute the main process (passed as CMD)
exec "$@"
