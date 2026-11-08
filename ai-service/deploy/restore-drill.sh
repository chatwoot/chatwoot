#!/usr/bin/env bash
# Restore drill for ai-service backups. Issue: DEV-Johnstocker/chatwoot#1
#
# Restores a pg_dump custom-format backup of the ai-service database into a
# throwaway pgvector container, then runs restore-check (Migrate, vector
# extension, schema version, required tables, row counts, one vector query).
# Run it on the host that keeps the backups, so customer data never leaves it.
#
#   restore-drill.sh <backup.dump> <restore-check binary> [restore-check flags]
#   restore-drill.sh /root/backups/aisvc-full-....dump ./restore-check -min-rows kb_documents=1
#
# Safety: the container keeps its data in RAM (tmpfs), publishes its port on
# 127.0.0.1 only, gets a random password that is never printed, and is removed
# on exit, success or failure. Production containers and Supabase are never
# touched. Exit code: 0 pass, 1 check failed, 2 restore or setup failed.
set -euo pipefail

if [[ $# -lt 2 ]]; then
  sed -n '2,15p' "$0" >&2
  exit 2
fi
dump=$(realpath "$1")
check_bin=$(realpath "$2")
shift 2
image=${RESTORE_DRILL_IMAGE:-pgvector/pgvector:pg17} # match the backup's Postgres major version
name="aisvc-restore-drill-$(date +%Y%m%d-%H%M%S)"
password=$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')

cleanup() { docker rm -f "$name" >/dev/null 2>&1 || true; }
trap cleanup EXIT

[[ -r "$dump" ]] || { echo "cannot read $dump" >&2; exit 2; }
[[ -x "$check_bin" ]] || { echo "not executable: $check_bin" >&2; exit 2; }
if [[ "$(head -c 5 "$dump")" != "PGDMP" ]]; then
  echo "$dump is not a pg_dump custom-format file" >&2
  exit 2
fi

echo "backup:  $(basename "$dump")"
echo "size:    $(stat -c %s "$dump") bytes"
echo "sha256:  $(sha256sum "$dump" | cut -d' ' -f1)"
echo "image:   $image"

docker run -d --name "$name" \
  -e POSTGRES_PASSWORD="$password" \
  -p 127.0.0.1::5432 \
  --tmpfs /var/lib/postgresql/data:rw,size=2g \
  -v "$dump":/backup.dump:ro \
  "$image" >/dev/null

for _ in $(seq 1 60); do
  docker exec "$name" pg_isready -U postgres -q 2>/dev/null && break
  sleep 1
done
# The entrypoint restarts Postgres once after init; wait until it answers queries.
for _ in $(seq 1 30); do
  docker exec "$name" psql -U postgres -tAc 'SELECT 1' >/dev/null 2>&1 && break
  sleep 1
done

# Supabase keeps the vector extension in its own schema and the dump refers to
# extensions.vector, so recreate that layout and search path first. The dump
# also creates schema public itself, so drop the empty default one.
docker exec "$name" psql -U postgres -v ON_ERROR_STOP=1 -q -c \
  "DROP SCHEMA public; CREATE SCHEMA extensions; CREATE EXTENSION vector SCHEMA extensions;
   ALTER DATABASE postgres SET search_path = \"\$user\", public, extensions;"

started=$(date +%s)
# Owners and grants name Supabase-only roles (anon, authenticated, service_role).
if ! docker exec "$name" pg_restore -U postgres -d postgres \
     --no-owner --no-privileges --exit-on-error /backup.dump; then
  echo "RESTORE FAILED" >&2
  exit 2
fi
echo "restore: $(( $(date +%s) - started ))s"

port=$(docker port "$name" 5432/tcp | head -1 | sed 's/.*://')
set +e
RESTORE_DATABASE_URL="postgres://postgres:${password}@127.0.0.1:${port}/postgres?sslmode=disable" \
  "$check_bin" "$@"
status=$?
set -e
if [[ $status -eq 0 ]]; then echo "RESULT: PASS"; else echo "RESULT: FAIL (restore-check exit $status)"; fi
exit "$status"
