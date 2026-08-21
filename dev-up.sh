#!/usr/bin/env bash
# Start Chatwoot dev (rails + sidekiq + vite) against the already-running
# chatwoot-tech Postgres/Redis. Usage: ./dev-up.sh   Stop: ./dev-down.sh
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
NET=chatwoot-tech_default
run() {
  docker run -d --name "$1" --network $NET \
    -v "$REPO":/app -v chatwoot-tech_bundle:/gems \
    --env-file "$REPO/.env" -w /app \
    -e GIT_CONFIG_COUNT=1 -e GIT_CONFIG_KEY_0=safe.directory -e GIT_CONFIG_VALUE_0=/app \
    "${@:2}"
}
docker rm -f cw-rails cw-sidekiq cw-vite >/dev/null 2>&1 || true
run cw-rails   -p 3000:3000 chatwoot-rails:development bundle exec rails s -p 3000 -b 0.0.0.0
run cw-sidekiq                chatwoot-rails:development bundle exec sidekiq -C config/sidekiq.yml
run cw-vite    -p 3036:3036 -e VITE_RUBY_HOST=0.0.0.0 chatwoot-vite:development bin/vite dev
echo "started: cw-rails(3000) cw-sidekiq cw-vite(3036)"
echo "logs: docker logs -f cw-rails"
