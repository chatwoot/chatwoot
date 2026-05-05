#!/bin/bash
# Backup pré-execução dos bancos Postgres + pgvector da VPS.
# Roda na VPS (não local). Salva em ~/backups/<timestamp>/.
#
# Uso:
#   ssh ubuntu@158.69.63.140
#   bash 00-backup-postgres.sh

set -euo pipefail

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$HOME/backups/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo "==> Backup destino: $BACKUP_DIR"

# Encontra os containers ativos (Swarm tasks)
POSTGRES_CID=$(sudo docker ps -q -f name=postgres_postgres | head -1)
PGVECTOR_CID=$(sudo docker ps -q -f name=pgvector_pgvector | head -1)

if [ -z "$POSTGRES_CID" ]; then
  echo "ERRO: container postgres_postgres não encontrado"
  exit 1
fi

if [ -z "$PGVECTOR_CID" ]; then
  echo "ERRO: container pgvector_pgvector não encontrado"
  exit 1
fi

echo "==> Postgres principal ($POSTGRES_CID)"
sudo docker exec "$POSTGRES_CID" pg_dumpall -U postgres \
  > "$BACKUP_DIR/postgres-all.sql"
echo "    $(wc -l < "$BACKUP_DIR/postgres-all.sql") linhas"

echo "==> pgvector ($PGVECTOR_CID)"
sudo docker exec "$PGVECTOR_CID" pg_dumpall -U postgres \
  > "$BACKUP_DIR/pgvector-all.sql"
echo "    $(wc -l < "$BACKUP_DIR/pgvector-all.sql") linhas"

echo "==> Comprimindo"
gzip "$BACKUP_DIR/postgres-all.sql" "$BACKUP_DIR/pgvector-all.sql"

echo "==> Listando volumes do swarm (para registro)"
sudo docker volume ls > "$BACKUP_DIR/volumes-list.txt"

echo "==> Snapshot dos services (para registro)"
sudo docker service ls > "$BACKUP_DIR/services-list.txt"
sudo docker stack ls > "$BACKUP_DIR/stacks-list.txt"

echo ""
echo "OK. Backup em: $BACKUP_DIR"
ls -lah "$BACKUP_DIR"
