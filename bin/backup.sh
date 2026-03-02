#!/usr/bin/env bash
# ============================================================================
# AirysChat — Database & Redis Backup Script
# ============================================================================
# Usage: ./bin/backup.sh [--s3 BUCKET_NAME]
#
# Creates timestamped backups in ./backups/:
#   - PostgreSQL pg_dump (compressed custom format)
#   - Redis RDB snapshot
#
# Optional: upload to S3-compatible storage with --s3 flag
# ============================================================================
set -euo pipefail

COMPOSE_FILE="docker-compose.production.yaml"
COMPOSE="docker compose -f $COMPOSE_FILE"
TIMESTAMP=$(date -u '+%Y%m%d_%H%M%S')
BACKUP_DIR="./backups/${TIMESTAMP}"
S3_BUCKET=""

# ── Parse flags ──────────────────────────────────────────────────
for arg in "$@"; do
  case $arg in
    --s3)     shift; S3_BUCKET="${1:-}" ;;
    *)        ;;
  esac
  shift 2>/dev/null || true
done

mkdir -p "$BACKUP_DIR"

echo "═══════════════════════════════════════════════════════════"
echo " AirysChat Backup — ${TIMESTAMP}"
echo " Output: ${BACKUP_DIR}"
echo "═══════════════════════════════════════════════════════════"

# ── 1. PostgreSQL dump ──────────────────────────────────────────
PG_FILE="${BACKUP_DIR}/postgres_${TIMESTAMP}.dump"
echo "▶ Backing up PostgreSQL..."
$COMPOSE exec -T postgres pg_dump \
  -U "${POSTGRES_USERNAME:-postgres}" \
  -d "${POSTGRES_DATABASE:-chatwoot_production}" \
  -Fc --no-owner --no-acl \
  > "$PG_FILE"

PG_SIZE=$(du -h "$PG_FILE" | cut -f1)
echo "  ✓ PostgreSQL — ${PG_SIZE} → ${PG_FILE}"

# ── 2. Redis RDB snapshot ──────────────────────────────────────
REDIS_FILE="${BACKUP_DIR}/redis_${TIMESTAMP}.rdb"
echo "▶ Backing up Redis..."
$COMPOSE exec -T redis redis-cli -a "${REDIS_PASSWORD}" --no-auth-warning BGSAVE >/dev/null 2>&1
sleep 3
$COMPOSE cp redis:/data/dump.rdb "$REDIS_FILE"

REDIS_SIZE=$(du -h "$REDIS_FILE" | cut -f1)
echo "  ✓ Redis — ${REDIS_SIZE} → ${REDIS_FILE}"

# ── 3. Upload to S3 (optional) ─────────────────────────────────
if [ -n "$S3_BUCKET" ]; then
  echo "▶ Uploading to s3://${S3_BUCKET}/backups/${TIMESTAMP}/..."
  aws s3 cp "$BACKUP_DIR/" "s3://${S3_BUCKET}/backups/${TIMESTAMP}/" --recursive --quiet
  echo "  ✓ Uploaded to S3"
fi

# ── 4. Cleanup old local backups (keep last 7) ──────────────────
BACKUP_COUNT=$(ls -d ./backups/*/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$BACKUP_COUNT" -gt 7 ]; then
  REMOVE_COUNT=$((BACKUP_COUNT - 7))
  echo "▶ Removing ${REMOVE_COUNT} old backup(s)..."
  ls -dt ./backups/*/ | tail -n "$REMOVE_COUNT" | xargs rm -rf
  echo "  ✓ Cleaned up"
fi

echo ""
echo "✅ Backup complete"
echo "═══════════════════════════════════════════════════════════"
