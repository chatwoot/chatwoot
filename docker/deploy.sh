#!/usr/bin/env bash
# Zero-downtime rolling deploy for the Docker Compose setup on a single host.
#
#   1. Run the one-shot `migrate` service. If it fails, the release stops here and no
#      running container is touched.
#   2. For each web and worker replica: start a replacement next to the old one (surge),
#      wait until its healthcheck passes, then stop the old one with SIGTERM so it drains
#      (Puma finishes in-flight requests, Sidekiq finishes running jobs) before exiting.
#      If the replacement never becomes healthy, it is removed and the deploy fails while
#      the old replicas keep serving.
#
# Usage: docker/deploy.sh
# Set COMPOSE_FILE to use a different compose file (defaults to docker-compose.production.yaml).
set -euo pipefail

export COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.production.yaml}"

log() { echo "==> $*"; }

# Container IDs (running or not) for a compose service.
container_ids() { docker compose ps -aq "$1"; }

# Replace every container of $1 one at a time, keeping the service serving throughout.
roll_service() {
  local service="$1"
  local old_ids
  old_ids=$(docker compose ps -q --status running "$service")

  if [ -z "$old_ids" ]; then
    log "$service: nothing running, starting it"
    docker compose up -d --no-deps --wait "$service"
    return
  fi

  for old in $old_ids; do
    local before count
    before=$(container_ids "$service")
    count=$(docker compose ps -q --status running "$service" | wc -l | tr -d ' ')

    log "$service: surging to $((count + 1)) replicas, then draining $old"
    if ! docker compose up -d --no-deps --no-recreate --wait --scale "$service=$((count + 1))" "$service"; then
      log "$service: replacement did not become healthy; removing it and keeping the old replicas"
      for id in $(container_ids "$service"); do
        grep -q "$id" <<<"$before" || docker rm -f "$id" >/dev/null
      done
      return 1
    fi

    # SIGTERM, then wait up to the service's stop_grace_period for a clean exit.
    docker stop "$old" >/dev/null
    local exit_code
    exit_code=$(docker inspect -f '{{.State.ExitCode}}' "$old")
    if [ "$exit_code" != "0" ]; then
      log "WARNING: $service replica $old exited with code $exit_code (expected 0 after a clean drain)"
    fi
    docker rm "$old" >/dev/null
  done
}

if [ -z "$(container_ids rails)" ]; then
  log "First start: bringing up the full stack"
  docker compose up -d --wait
  exit 0
fi

if [ "${DEPLOY_PULL:-1}" = "1" ]; then
  log "Pulling images"
  docker compose pull
fi

log "Running migrations"
docker compose run --rm migrate

roll_service rails
roll_service sidekiq

log "Applying proxy configuration"
docker compose up -d --no-deps --wait proxy

log "Deploy complete"
