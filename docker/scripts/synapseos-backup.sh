#!/usr/bin/env bash
# CUSTOMIZAÇÃO_SYNAPSEOS — backup diário de Postgres + volume storage.
#
# Instalação (roda 1× por dia):
#   sudo ln -s /opt/synapseos-core/docker/scripts/synapseos-backup.sh \
#     /etc/cron.daily/synapseos-backup
#
# Off-site (recomendado): adicionar passo rclone sync ao final pra
# bucket externo (Backblaze B2, R2, S3). Ver devops_handoff.md §7.2.

set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/opt/synapseos-core}"
COMPOSE_FILE="${COMPOSE_FILE:-${PROJECT_DIR}/docker-compose.prod.yml}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/synapseos}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
DATE="$(date +%F)"

POSTGRES_DB="${POSTGRES_DB:-chatwoot_production}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"

# Nome do volume é prefixado pelo diretório do projeto.
# Ex: /opt/synapseos-core → volume vira `synapseos-core_storage`.
PROJECT_NAME="$(basename "${PROJECT_DIR}")"
STORAGE_VOLUME="${STORAGE_VOLUME:-${PROJECT_NAME}_storage}"

mkdir -p "${BACKUP_DIR}"

echo "→ Dump do Postgres (${POSTGRES_DB})"
docker compose -f "${COMPOSE_FILE}" exec -T postgres \
  pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB}" \
  | gzip > "${BACKUP_DIR}/pg_${DATE}.sql.gz"

echo "→ Tar do volume storage (${STORAGE_VOLUME})"
docker run --rm \
  -v "${STORAGE_VOLUME}":/data:ro \
  -v "${BACKUP_DIR}":/backup \
  alpine tar czf "/backup/storage_${DATE}.tar.gz" -C /data .

echo "→ Rotação (> ${RETENTION_DAYS} dias)"
find "${BACKUP_DIR}" -type f -mtime "+${RETENTION_DAYS}" -delete

echo "Backup concluído em ${BACKUP_DIR}"
ls -lh "${BACKUP_DIR}" | tail -5
