#!/usr/bin/env bash
# CUSTOMIZAÇÃO_SYNAPSEOS — Backup off-site via rclone.
#
# Dumps Postgres + tars ActiveStorage, then pushes to a remote
# configured in rclone (B2, R2, S3, etc).
#
# Prerequisites:
#   1. Install rclone:  curl https://rclone.org/install.sh | sudo bash
#   2. Configure remote: rclone config  (create a remote named "offsite")
#   3. Set env vars or edit defaults below.
#
# Usage:
#   ./scripts/backup_offsite.sh
#
# Cron example (daily at 03:00):
#   0 3 * * * /opt/synapseos-core/scripts/backup_offsite.sh >> /var/log/synapseos-backup.log 2>&1
#
# Environment variables:
#   RCLONE_REMOTE    — rclone remote name (default: offsite)
#   RCLONE_BUCKET    — bucket/container path  (default: synapseos-backups)
#   COMPOSE_FILE     — docker-compose file    (default: docker-compose.prod.yml)
#   BACKUP_RETENTION — days to keep remote backups (default: 30)
#   ALERT_EMAIL      — email for failure alerts (optional)
#   ALERT_SLACK_WEBHOOK — Slack webhook URL for failure alerts (optional)

set -euo pipefail

RCLONE_REMOTE="${RCLONE_REMOTE:-offsite}"
RCLONE_BUCKET="${RCLONE_BUCKET:-synapseos-backups}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
BACKUP_RETENTION="${BACKUP_RETENTION:-30}"
ALERT_EMAIL="${ALERT_EMAIL:-}"
ALERT_SLACK_WEBHOOK="${ALERT_SLACK_WEBHOOK:-}"

DATESTAMP="$(date +%F_%H%M)"
STAGING_DIR="$(mktemp -d /tmp/synapseos-backup-XXXX)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cleanup() { rm -rf "$STAGING_DIR"; }
trap cleanup EXIT

send_alert() {
  local msg="$1"
  local hostname
  hostname="$(hostname -f 2>/dev/null || hostname)"

  if [[ -n "$ALERT_EMAIL" ]]; then
    echo "$msg" | mail -s "[Synapse OS] Backup FAILED on $hostname" "$ALERT_EMAIL" 2>/dev/null || true
  fi

  if [[ -n "$ALERT_SLACK_WEBHOOK" ]]; then
    local payload
    payload=$(jq -n --arg text ":rotating_light: *Backup FAILED* on \`$hostname\`\n$msg" '{text: $text}')
    curl -s -X POST "$ALERT_SLACK_WEBHOOK" \
      -H 'Content-Type: application/json' \
      -d "$payload" \
      >/dev/null 2>&1 || true
  fi
}

echo "=== Synapse OS backup started at $(date -Iseconds) ==="

cd "$PROJECT_DIR"

# 1. Postgres dump
PG_FILE="$STAGING_DIR/pg_${DATESTAMP}.sql.gz"
echo "[1/4] Dumping Postgres..."
if ! docker compose -f "$COMPOSE_FILE" exec -T postgres \
  pg_dump -U "${POSTGRES_USERNAME:-postgres}" "${POSTGRES_DB:-chatwoot_production}" \
  | gzip > "$PG_FILE"; then
  send_alert "Postgres dump failed."
  exit 1
fi
echo "  -> $(du -h "$PG_FILE" | cut -f1)"

# 2. ActiveStorage tar
STORAGE_FILE="$STAGING_DIR/storage_${DATESTAMP}.tar.gz"
echo "[2/4] Archiving ActiveStorage volume..."
VOLUME_NAME="$(docker volume ls --format '{{.Name}}' | grep -E 'storage$' | head -1)"
if [[ -z "$VOLUME_NAME" ]]; then
  echo "  WARNING: storage volume not found, skipping."
else
  if ! docker run --rm -v "${VOLUME_NAME}:/data:ro" \
    -v "$STAGING_DIR:/backup" alpine \
    tar czf "/backup/storage_${DATESTAMP}.tar.gz" -C /data .; then
    send_alert "Storage archive failed."
    exit 1
  fi
  echo "  -> $(du -h "$STORAGE_FILE" | cut -f1)"
fi

# 3. Push to remote
REMOTE_PATH="${RCLONE_REMOTE}:${RCLONE_BUCKET}/${DATESTAMP}"
echo "[3/4] Uploading to ${REMOTE_PATH}..."
if ! rclone copy "$STAGING_DIR" "$REMOTE_PATH" --progress --transfers 4; then
  send_alert "rclone upload to ${REMOTE_PATH} failed."
  exit 1
fi

# 4. Prune old backups
echo "[4/4] Pruning backups older than ${BACKUP_RETENTION} days..."
rclone delete "${RCLONE_REMOTE}:${RCLONE_BUCKET}" \
  --min-age "${BACKUP_RETENTION}d" 2>/dev/null || true

echo "=== Backup completed at $(date -Iseconds) ==="
