#!/usr/bin/env bash
# Daily backup of the ai-service database, verified by a restore drill.
# Issue: DEV-Johnstocker/chatwoot#1
#
# 1. Reads DATABASE_URL from the running production ai-service container and
#    removes the pgx-only pool_* options, which pg_dump rejects. The URL is
#    never printed and reaches the dump container only through a root-only
#    temp file.
# 2. pg_dump -Fc -n public (read-only) into BACKUP_DIR, mode 600, plus a
#    <dump>.sha256 checksum, checked straight away.
# 3. restore-drill.sh restores the new dump into a throwaway container and
#    runs restore-check. A dump that fails is renamed aisvc-failed-*.dump,
#    kept for inspection, and the script exits 1.
# 4. Only after a passing drill: keep the aisvc-full-*.dump files of the
#    newest BACKUP_KEEP_DAYS dates (with their checksums) and delete older
#    ones. No other file in BACKUP_DIR is touched.
#
# Settings (environment; deploy/backup/aisvc-backup.env.example):
#   BACKUP_SOURCE_CONTAINER  production ai-service container (required)
#   BACKUP_DIR               default /root/backups
#   BACKUP_KEEP_DAYS         days of verified dumps to keep, default 7
#   BACKUP_IMAGE             pg_dump image, default pgvector/pgvector:pg17
#                            (same Postgres major version as the database)
#   BACKUP_MIN_ROWS          restore-check minimums
#   RESTORE_CHECK            restore-check binary, default next to this script
#   R2_BACKUP_ENDPOINT, R2_BACKUP_BUCKET, R2_BACKUP_ACCESS_KEY_ID,
#   R2_BACKUP_SECRET_ACCESS_KEY
#                            offsite copy (Cloudflare R2 or any S3 API); when
#                            all four are set, a verified dump and its .sha256
#                            are uploaded to daily/ in the bucket
#
# Exit: 0 backed up and verified (and copied offsite when configured),
# 1 drill failed, 2 setup or dump failed, 3 verified locally but the offsite
# copy failed.
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

log() { printf '%s %s\n' "$(date '+%F %T %z')" "$*"; }

# strip_pool_params removes pgx pool options (pool_max_conns, ...) from a
# Postgres URL; libpq tools reject them. Other query options are kept.
strip_pool_params() {
  printf '%s' "$1" | sed -E 's/(^|[?&])pool_[a-z_]+=[^&]*//g; /\?/!s/&/?/; s/[?&]$//'
}

# prune_old keeps every aisvc-full-YYYYMMDD-HHMMSS.dump from the newest
# <days> dates present in <dir> and deletes older ones with their .sha256
# files, printing each deleted name. Counting dates, not files, means extra
# runs on one day never push an older day out.
prune_old() {
  local dir=$1 days=$2
  if ! [[ "$days" =~ ^[0-9]+$ ]] || (( days < 1 )); then
    log "BACKUP_KEEP_DAYS must be a whole number of at least 1, got '$days'" >&2
    return 2
  fi
  local files=() dates=() path name
  for path in "$dir"/aisvc-full-*.dump; do
    name=$(basename "$path")
    [[ -f "$path" && "$name" =~ ^aisvc-full-([0-9]{8})-[0-9]{6}\.dump$ ]] || continue
    files+=("$name")
    dates+=("${BASH_REMATCH[1]}")
  done
  (( ${#files[@]} > 0 )) || return 0
  local cutoff
  cutoff=$(printf '%s\n' "${dates[@]}" | sort -u | tail -n "$days" | head -1)
  local i
  for i in "${!files[@]}"; do
    if [[ "${dates[$i]}" < "$cutoff" ]]; then
      rm -f -- "${dir:?}/${files[$i]}" "${dir:?}/${files[$i]}.sha256"
      echo "${files[$i]}"
    fi
  done
}

# offsite_configured is true when every R2 setting is present.
offsite_configured() {
  [[ -n "${R2_BACKUP_ENDPOINT:-}" && -n "${R2_BACKUP_BUCKET:-}" &&
     -n "${R2_BACKUP_ACCESS_KEY_ID:-}" && -n "${R2_BACKUP_SECRET_ACCESS_KEY:-}" ]]
}

# offsite_url <endpoint> <bucket> <key> prints the object's path-style URL.
offsite_url() { printf '%s/%s/%s' "${1%/}" "$2" "$3"; }

# upload_offsite <file> <key> uploads one file with S3 SigV4 (curl, no extra
# tools). The request carries the file's SHA-256, which R2 checks, and a HEAD
# afterwards must report the local size. The keys reach curl through a
# root-only config file, never the command line.
upload_offsite() {
  local file=$1 key=$2 url cfg sha size remote ok=1
  url=$(offsite_url "$R2_BACKUP_ENDPOINT" "$R2_BACKUP_BUCKET" "$key")
  cfg=$(mktemp)
  printf 'user = "%s:%s"\n' "$R2_BACKUP_ACCESS_KEY_ID" "$R2_BACKUP_SECRET_ACCESS_KEY" >"$cfg"
  sha=$(sha256sum "$file" | cut -d' ' -f1)
  size=$(stat -c %s "$file")
  if curl --fail --silent --show-error --retry 3 --retry-all-errors -o /dev/null \
       -K "$cfg" --aws-sigv4 "aws:amz:auto:s3" -H "x-amz-content-sha256: $sha" -T "$file" "$url"; then
    remote=$(curl --fail --silent --show-error -I -K "$cfg" --aws-sigv4 "aws:amz:auto:s3" "$url" |
      tr -d '\r' | awk -F': ' 'tolower($1) == "content-length" { print $2 }')
    [[ "$remote" == "$size" ]] && ok=0
  fi
  rm -f "$cfg"
  return "$ok"
}

# source_url prints DATABASE_URL from a container's environment (to a pipe or
# variable only; callers must never echo it).
source_url() {
  docker inspect "$1" --format '{{range .Config.Env}}{{println .}}{{end}}' |
    sed -n 's/^DATABASE_URL=//p' | head -1
}

main() {
  local container=${BACKUP_SOURCE_CONTAINER:-}
  local dir=${BACKUP_DIR:-/root/backups}
  local keep=${BACKUP_KEEP_DAYS:-7}
  local image=${BACKUP_IMAGE:-pgvector/pgvector:pg17}
  local min_rows=${BACKUP_MIN_ROWS:-kb_documents=1,kb_chunks=1,business_profiles=1}
  local check_bin=${RESTORE_CHECK:-$script_dir/restore-check}
  local drill=$script_dir/restore-drill.sh

  [[ -n "$container" ]] || { log "set BACKUP_SOURCE_CONTAINER to the production ai-service container" >&2; exit 2; }
  [[ -d "$dir" ]] || { log "no backup directory $dir" >&2; exit 2; }
  [[ -x "$drill" && -x "$check_bin" ]] || { log "missing $drill or $check_bin" >&2; exit 2; }
  # Fail on bad settings before dumping, not after. Never prune here: old
  # backups go only after a new one has passed the drill.
  if ! [[ "$keep" =~ ^[0-9]+$ ]] || (( keep < 1 )); then
    log "BACKUP_KEEP_DAYS must be a whole number of at least 1" >&2
    exit 2
  fi

  umask 077
  exec 9>"$dir/.aisvc-backup.lock"
  flock -n 9 || { log "another backup is running" >&2; exit 2; }

  # Global, not local: the EXIT trap runs after main has returned.
  env_file=$(mktemp)
  trap 'rm -f "${env_file:-}"' EXIT
  local url
  url=$(source_url "$container")
  [[ -n "$url" ]] || { log "no DATABASE_URL in container $container" >&2; exit 2; }
  printf 'PGURL=%s\n' "$(strip_pool_params "$url")" >"$env_file"
  unset url

  local name
  name="aisvc-full-$(date +%Y%m%d-%H%M%S).dump"
  log "dump $name from $container"
  local started=$SECONDS
  if ! docker run --rm --env-file "$env_file" -v "$dir":/out "$image" \
       sh -c "umask 077; pg_dump \"\$PGURL\" -Fc -n public -f /out/.$name.partial"; then
    rm -f "$env_file" "$dir/.$name.partial"
    log "DUMP FAILED" >&2
    exit 2
  fi
  rm -f "$env_file"
  mv "$dir/.$name.partial" "$dir/$name"
  chmod 600 "$dir/$name"
  (cd "$dir" && sha256sum "$name" >"$name.sha256" && sha256sum -c --quiet "$name.sha256")
  log "dumped $(stat -c %s "$dir/$name") bytes in $((SECONDS - started))s, sha256 $(cut -d' ' -f1 "$dir/$name.sha256")"

  if ! "$drill" "$dir/$name" "$check_bin" -min-rows "$min_rows"; then
    local failed=${name/aisvc-full-/aisvc-failed-}
    mv "$dir/$name" "$dir/$failed"
    mv "$dir/$name.sha256" "$dir/$failed.sha256"
    log "DRILL FAILED: kept as $failed; older backups left untouched" >&2
    exit 1
  fi

  local offsite_failed=0
  if offsite_configured; then
    if upload_offsite "$dir/$name" "daily/$name" && upload_offsite "$dir/$name.sha256" "daily/$name.sha256"; then
      log "offsite: copied to $R2_BACKUP_BUCKET/daily/$name"
    else
      log "OFFSITE COPY FAILED for $name; the local backup is verified and kept" >&2
      offsite_failed=1
    fi
  else
    log "offsite: not configured (R2_BACKUP_* unset); local copy only"
  fi

  local deleted
  deleted=$(prune_old "$dir" "$keep")
  [[ -z "$deleted" ]] || log "pruned: $(echo "$deleted" | tr '\n' ' ')"
  log "OK $name verified; keeping $keep days"
  if (( offsite_failed )); then
    exit 3
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
