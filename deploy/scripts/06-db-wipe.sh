#!/bin/bash
# Reset zero-state dos DBs (chatwoot + synapseos_<client>).
# Roda na VPS. Usa SQLs em /opt/synapseos/sql/wipe/.
#
# Uso:
#   bash 06-db-wipe.sh <client>            # ex: audi
#   DRY_RUN=1 bash 06-db-wipe.sh <client>  # mostra o que rodaria sem executar

set -euo pipefail

CLIENT="${1:?uso: $0 <client>  (ex: audi)}"
ROOT=/opt/synapseos
SQL_DIR="${ROOT}/sql/wipe"

CHATWOOT_DB="${CHATWOOT_DB:-chatwoot_production}"
CLIENT_DB="synapseos_${CLIENT}"
PG_CONTAINER=$(sudo docker ps -q -f name=postgres_postgres | head -1)

if [ -z "${PG_CONTAINER}" ]; then
  echo "ERRO: container postgres_postgres não encontrado"
  exit 1
fi

echo "==> Wipe target:"
echo "    container: ${PG_CONTAINER}"
echo "    chatwoot DB: ${CHATWOOT_DB}"
echo "    client DB:   ${CLIENT_DB}"
echo "    SQLs em:     ${SQL_DIR}"

if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "==> DRY_RUN — não executando."
  exit 0
fi

read -p "Confirma wipe (DESTRUTIVO, irreversível sem backup)? [y/N] " ok
[[ "$ok" == "y" || "$ok" == "Y" ]] || exit 1

echo ""
echo "==> Wipe chatwoot DB"
sudo docker exec -i "${PG_CONTAINER}" \
  psql -U postgres -d "${CHATWOOT_DB}" < "${SQL_DIR}/wipe_chatwoot.sql"

echo ""
echo "==> Wipe ${CLIENT_DB}"
sudo docker exec -i "${PG_CONTAINER}" \
  psql -U "${CLIENT_DB}" -d "${CLIENT_DB}" < "${SQL_DIR}/wipe_synapseos_${CLIENT}.sql"

echo ""
echo "==> Wipe completo. Pode disparar n8n agora."
