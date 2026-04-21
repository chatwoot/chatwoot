#!/bin/sh
# CUSTOMIZAÇÃO_SYNAPSEOS
# Entrypoint do serviço Sidekiq no Railway. Mesma imagem do web, start command
# diferente (override na UI Railway: "/app/docker/entrypoints/railway_worker.sh").
set -e

if [ -n "$DATABASE_URL" ] && [ -z "$POSTGRES_HOST" ]; then
  proto_removed="${DATABASE_URL#*://}"
  creds_host="${proto_removed%%/*}"
  path="${proto_removed#*/}"
  creds="${creds_host%@*}"
  host_port="${creds_host#*@}"
  export POSTGRES_USERNAME="${creds%%:*}"
  export POSTGRES_PASSWORD="${creds#*:}"
  export POSTGRES_HOST="${host_port%%:*}"
  export POSTGRES_PORT="${host_port#*:}"
  export POSTGRES_DATABASE="${path%%\?*}"
fi

echo "[railway_worker] starting sidekiq"
exec bundle exec sidekiq -C config/sidekiq.yml
