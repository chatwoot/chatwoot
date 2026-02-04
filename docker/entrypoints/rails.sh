#!/bin/sh

set -x

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

if [ "$RAILS_ENV" = "production" ]; then
  if [ -z "$NODE_OPTIONS" ]; then
    export NODE_OPTIONS="--max-old-space-size=4096"
  fi

  if ! command -v npm >/dev/null 2>&1; then
    if [ -f /usr/local/lib/node_modules/npm/bin/npm-cli.js ]; then
      ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm
      ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx
    fi
  fi

  if ! command -v pnpm >/dev/null 2>&1; then
    if command -v npm >/dev/null 2>&1; then
      echo "pnpm missing, installing with npm..."
      npm install -g pnpm@10.2.0
    fi
  fi

  if [ ! -f /app/public/vite/manifest.json ]; then
    echo "Vite manifest missing, precompiling assets..."
    bundle exec rails assets:precompile
  fi

  if [ -f /app/public/vite/.vite/manifest.json ]; then
    if [ ! -f /app/public/vite/manifest.json ]; then
      cp /app/public/vite/.vite/manifest.json /app/public/vite/manifest.json
    fi
  fi
fi

# Execute the main process of the container
exec "$@"
