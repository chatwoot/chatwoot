#!/bin/sh
set -eu

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.production.yaml}"

docker compose -f "$COMPOSE_FILE" up -d --force-recreate
docker compose -f "$COMPOSE_FILE" exec rails bundle exec rails branding:update
docker compose -f "$COMPOSE_FILE" exec rails sh -lc 'rm -rf /app/public/vite/* /app/public/vite/.vite && bundle exec rails assets:precompile'
docker compose -f "$COMPOSE_FILE" restart rails sidekiq
