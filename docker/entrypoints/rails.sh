#!/bin/sh

set -x

# Chatwit: DISABLE_ENTERPRISE com QUALQUER string (inclusive "false") é TRUTHY em
# Ruby e desliga a edição Enterprise inteira (lib/chatwoot_app.rb#enterprise?).
# Removemos a env quando o valor é "falsey", para o Ruby cair no fallback que
# detecta a pasta enterprise/ e manter o Enterprise ligado.
case "$(printf '%s' "${DISABLE_ENTERPRISE:-}" | tr '[:upper:]' '[:lower:]')" in
  ""|false|0|no|off) unset DISABLE_ENTERPRISE ;;
esac

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

git config --global --add safe.directory /app || true

#install missing gems for local dev as we are using base image compiled for production
bundle install

BUNDLE="bundle check"

until $BUNDLE
do
  sleep 2;
done

# Execute the main process of the container
exec "$@"
