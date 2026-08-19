#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
compose=(docker compose --project-directory "$deployment_dir" --env-file "$env_path" -f "$deployment_dir/compose.yaml")
snapshot="${1:-}"

[[ -n "$snapshot" && -d "$snapshot" ]] || {
  printf 'Usage: RESTORE_CONFIRMATION=restore:<snapshot-name> %s <snapshot-directory>\n' "$0" >&2
  exit 1
}
snapshot="$(cd "$snapshot" && pwd)"
snapshot_name="$(basename "$snapshot")"
expected_confirmation="restore:$snapshot_name"
[[ "${RESTORE_CONFIRMATION:-}" == "$expected_confirmation" ]] || {
  printf 'Refusing destructive restore. Set RESTORE_CONFIRMATION=%s for this snapshot.\n' "$expected_confirmation" >&2
  exit 1
}

for file in chatwoot.dump claude-agent.dump storage.tar.gz redis.tar.gz object-storage.tar.gz object-storage-manifest.json environment.env.gpg SHA256SUMS; do
  [[ -f "$snapshot/$file" ]] || {
    printf 'Snapshot is incomplete: %s\n' "$file" >&2
    exit 1
  }
done
(cd "$snapshot" && shasum -a 256 -c SHA256SUMS)

command -v gpg >/dev/null 2>&1 || {
  printf 'gpg is required to verify recovery metadata.\n' >&2
  exit 1
}
recovery_env="$(mktemp)"
cleanup_recovery_env() { rm -f -- "$recovery_env"; }
trap cleanup_recovery_env EXIT
chmod 600 "$recovery_env"
gpg --batch --quiet --decrypt "$snapshot/environment.env.gpg" > "$recovery_env"
if ! cmp -s "$recovery_env" "$env_path"; then
  printf 'Current environment does not match the encrypted recovery metadata; refusing restore.\n' >&2
  exit 1
fi

"${compose[@]}" stop caddy rails sidekiq claude-agent minio
"${compose[@]}" up -d postgres redis

# `up -d` kehrt zurueck, sobald der Container laeuft — nicht, sobald Postgres
# Verbindungen annimmt. Ohne dieses Warten scheitert das erste dropdb mit
# "No such file or directory" auf dem Socket.
for _ in $(seq 1 60); do
  if "${compose[@]}" exec -T postgres sh -ec 'pg_isready -U "$POSTGRES_USER" -q'; then
    break
  fi
  sleep 2
done
"${compose[@]}" exec -T postgres sh -ec 'pg_isready -U "$POSTGRES_USER" -q' || {
  printf 'PostgreSQL wurde nicht rechtzeitig bereit.\n' >&2
  exit 1
}

restore_database() {
  local database="$1"
  local owner="$2"
  local dump_path="$3"
  "${compose[@]}" exec -T postgres sh -ec \
    "PGPASSWORD=\"\$POSTGRES_PASSWORD\" dropdb --if-exists --force --username \"\$POSTGRES_USER\" '$database' && PGPASSWORD=\"\$POSTGRES_PASSWORD\" createdb --username \"\$POSTGRES_USER\" --owner '$owner' '$database'"
  "${compose[@]}" exec -T postgres sh -ec \
    "PGPASSWORD=\"\$POSTGRES_PASSWORD\" psql --quiet --username \"\$POSTGRES_USER\" --dbname '$database' \
       --command 'CREATE EXTENSION IF NOT EXISTS pg_stat_statements' \
       --command 'CREATE EXTENSION IF NOT EXISTS vector' \
       --command 'CREATE EXTENSION IF NOT EXISTS pg_trgm'"
  "${compose[@]}" exec -T postgres sh -ec \
    "PGPASSWORD=\"\$POSTGRES_PASSWORD\" pg_restore --exit-on-error --no-owner --no-comments --role '$owner' --username \"\$POSTGRES_USER\" --dbname '$database'" \
    < "$dump_path"
}

set -a
# shellcheck disable=SC1090
source "$env_path"
set +a
restore_database "$POSTGRES_DATABASE" "$POSTGRES_USERNAME" "$snapshot/chatwoot.dump"
restore_database "$CLAUDE_AGENT_DATABASE" "$CLAUDE_AGENT_DATABASE_USER" "$snapshot/claude-agent.dump"

docker run --rm \
  -v myinvest-chatwoot-storage:/target \
  -v "$snapshot:/backup:ro" \
  alpine:3.21@sha256:48b0309ca019d89d40f670aa1bc06e426dc0931948452e8491e3d65087abc07d \
  sh -ec 'find /target -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +; tar -xzf /backup/storage.tar.gz -C /target'
"${compose[@]}" stop redis
docker run --rm \
  -v myinvest-chatwoot-redis:/target \
  -v "$snapshot:/backup:ro" \
  alpine:3.21@sha256:48b0309ca019d89d40f670aa1bc06e426dc0931948452e8491e3d65087abc07d \
  sh -ec 'find /target -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +; tar -xzf /backup/redis.tar.gz -C /target'
docker run --rm \
  -v myinvest-chatwoot-minio:/target \
  -v "$snapshot:/backup:ro" \
  alpine:3.21@sha256:48b0309ca019d89d40f670aa1bc06e426dc0931948452e8491e3d65087abc07d \
  sh -ec 'find /target -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +; tar -xzf /backup/object-storage.tar.gz -C /target'

"${compose[@]}" up -d minio
"${compose[@]}" run --rm minio-init
"${compose[@]}" run --rm rails bundle exec rails db:chatwoot_prepare
"${compose[@]}" run --rm -v "$snapshot:/restore:ro" rails \
  bundle exec rails runner /bootstrap/restore_object_storage.rb
"${compose[@]}" up -d rails
AGENT_STATE_RECONCILE_CONFIRMATION="reconcile:${CADDY_SITE_ADDRESS}" \
RECONCILE_ARCHIVE_AGENT_QUEUE=true \
  "$deployment_dir/scripts/reconcile-agent-state.sh"
"${compose[@]}" up -d --build
"${compose[@]}" exec -T postgres sh -ec \
  "PGPASSWORD=\"\$CHATWOOT_DATABASE_PASSWORD\" psql --username \"\$CHATWOOT_DATABASE_USER\" --dbname \"\$CHATWOOT_DATABASE\" --command 'SELECT 1' >/dev/null"
"${compose[@]}" exec -T postgres sh -ec \
  "PGPASSWORD=\"\$CLAUDE_AGENT_DATABASE_PASSWORD\" psql --username \"\$CLAUDE_AGENT_DATABASE_USER\" --dbname \"\$CLAUDE_AGENT_DATABASE\" --command 'SELECT 1' >/dev/null"
printf 'Restore and fail-closed agent state/queue reconciliation completed; run scripts/smoke.sh now.\n'
