#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
compose=(docker compose --project-directory "$deployment_dir" --env-file "$env_path" -f "$deployment_dir/compose.yaml")

set -a
# shellcheck disable=SC1090
source "$env_path"
set +a

if [[ "${LOCAL_SMOKE:-false}" != true && -z "${BACKUP_OFFSITE_REMOTE:-}" ]]; then
  printf 'Production backup requires BACKUP_OFFSITE_REMOTE before plaintext staging begins.\n' >&2
  exit 1
fi

if [[ "$BACKUP_DIR" = /* ]]; then
  backup_root="$BACKUP_DIR"
else
  backup_root="$deployment_dir/${BACKUP_DIR#./}"
fi
mkdir -p "$backup_root"
backup_root="$(cd "$backup_root" && pwd)"
case "$backup_root" in
  /|"$HOME")
    printf 'Unsafe BACKUP_DIR: %s\n' "$backup_root" >&2
    exit 1
    ;;
esac

snapshot="$backup_root/$(date -u +%Y%m%dT%H%M%SZ)"
temporary="${snapshot}.partial"
mkdir -m 700 "$temporary"
backup_finished=false

finish_or_clean_up() {
  if [[ "$backup_finished" != true && -d "$temporary" ]]; then
    find "$temporary" -depth -delete || true
  fi
  "${compose[@]}" unpause rails sidekiq claude-agent redis minio >/dev/null 2>&1 || true
}
trap finish_or_clean_up EXIT

"${compose[@]}" pause rails sidekiq claude-agent >/dev/null
"${compose[@]}" run --rm --user "$(id -u):$(id -g)" rails \
  bundle exec rails runner /bootstrap/object_storage_manifest.rb >/dev/null
cp "$deployment_dir/runtime/object-storage-manifest.json" "$temporary/object-storage-manifest.json"
"${compose[@]}" pause minio >/dev/null
# Variables in these commands intentionally expand inside the database container.
# shellcheck disable=SC2016
"${compose[@]}" exec -T postgres sh -ec \
  'PGPASSWORD="$POSTGRES_PASSWORD" pg_dump --format=custom --no-owner --username "$POSTGRES_USER" "$CHATWOOT_DATABASE"' \
  > "$temporary/chatwoot.dump"
# shellcheck disable=SC2016
"${compose[@]}" exec -T postgres sh -ec \
  'PGPASSWORD="$POSTGRES_PASSWORD" pg_dump --format=custom --no-owner --username "$POSTGRES_USER" "$CLAUDE_AGENT_DATABASE"' \
  > "$temporary/claude-agent.dump"
# The password intentionally expands inside the Redis container.
# shellcheck disable=SC2016
"${compose[@]}" exec -T redis sh -ec \
  'REDISCLI_AUTH="$REDIS_PASSWORD" redis-cli --no-auth-warning SAVE >/dev/null'
"${compose[@]}" pause redis >/dev/null
docker run --rm \
  -v myinvest-chatwoot-storage:/source:ro \
  -v "$temporary:/backup" \
  alpine:3.21@sha256:48b0309ca019d89d40f670aa1bc06e426dc0931948452e8491e3d65087abc07d \
  sh -ec 'cd /source && tar -czf /backup/storage.tar.gz .'
docker run --rm \
  -v myinvest-chatwoot-redis:/source:ro \
  -v "$temporary:/backup" \
  alpine:3.21@sha256:48b0309ca019d89d40f670aa1bc06e426dc0931948452e8491e3d65087abc07d \
  sh -ec 'cd /source && tar -czf /backup/redis.tar.gz .'
docker run --rm \
  -v myinvest-chatwoot-minio:/source:ro \
  -v "$temporary:/backup" \
  alpine:3.21@sha256:48b0309ca019d89d40f670aa1bc06e426dc0931948452e8491e3d65087abc07d \
  sh -ec 'cd /source && tar -czf /backup/object-storage.tar.gz .'
"${compose[@]}" unpause redis >/dev/null
"${compose[@]}" unpause minio >/dev/null

[[ -n "${BACKUP_GPG_RECIPIENT:-}" ]] || {
  printf 'BACKUP_GPG_RECIPIENT is required for encrypted recovery metadata.\n' >&2
  exit 1
}
command -v gpg >/dev/null 2>&1 || {
  printf 'gpg is required for encrypted recovery metadata.\n' >&2
  exit 1
}
gpg --batch --yes --trust-model always --recipient "$BACKUP_GPG_RECIPIENT" \
  --output "$temporary/environment.env.gpg" --encrypt "$env_path"

(
  cd "$temporary"
  shasum -a 256 chatwoot.dump claude-agent.dump storage.tar.gz redis.tar.gz object-storage.tar.gz \
    object-storage-manifest.json environment.env.gpg > SHA256SUMS
)
mv "$temporary" "$snapshot"
backup_finished=true
finish_or_clean_up
trap - EXIT

remove_plaintext_snapshot() {
  if [[ -d "$snapshot" ]]; then
    case "$snapshot" in
      "$backup_root"/20??????T??????Z) find "$snapshot" -depth -delete ;;
      *)
        printf 'Refusing to remove unexpected plaintext staging path: %s\n' "$snapshot" >&2
        return 1
        ;;
    esac
  fi
}

if [[ -n "${BACKUP_OFFSITE_REMOTE:-}" ]]; then
  if [[ "${LOCAL_SMOKE:-false}" != true ]]; then
    trap remove_plaintext_snapshot EXIT
    "$deployment_dir/scripts/offsite-backup.sh" "$snapshot"
    remove_plaintext_snapshot
    trap - EXIT
  else
    "$deployment_dir/scripts/offsite-backup.sh" "$snapshot"
  fi
fi

retention_days="${BACKUP_RETENTION_DAYS:-14}"
[[ "$retention_days" =~ ^[0-9]+$ ]] || {
  printf 'BACKUP_RETENTION_DAYS must be numeric.\n' >&2
  exit 1
}
while IFS= read -r expired_snapshot; do
  find "$expired_snapshot" -depth -delete
done < <(find "$backup_root" -mindepth 1 -maxdepth 1 -type d -name '20??????T??????Z' -mtime "+$retention_days" -print)
find "$backup_root" -mindepth 1 -maxdepth 1 -type f \
  \( -name '20??????T??????Z.tar.gpg' -o -name '20??????T??????Z.offsite-receipt.json' \) \
  -mtime "+$retention_days" -delete
if [[ "${LOCAL_SMOKE:-false}" == true ]]; then
  printf 'Application-consistent local proof backup created: %s\n' "$snapshot"
else
  printf 'Application-consistent encrypted backup created; plaintext staging removed: %s.tar.gpg\n' "$snapshot"
fi
