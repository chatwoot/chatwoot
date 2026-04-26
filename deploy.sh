#!/usr/bin/env bash
# CUSTOMIZAÇÃO_SYNAPSEOS — deploy idempotente em VPS de cliente.
#
# Uso (na VPS, dentro de /opt/synapseos-core):
#   ./deploy.sh               # pull da tag definida em .env (default: latest)
#   SYNAPSEOS_TAG=v0.3.0 ./deploy.sh   # deploy de tag específica
#
# O serviço `release` do compose roda db:chatwoot_prepare automaticamente
# antes do web/worker subirem, então esse script não precisa chamar nada
# de migration manualmente.

set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
BRANCH="${DEPLOY_BRANCH:-custom/initial-cleanup}"

cd "$(dirname "$0")"

echo "→ Pull do compose atualizado (branch: ${BRANCH})"
git pull --ff-only origin "${BRANCH}"

echo "→ Pull da imagem (tag: ${SYNAPSEOS_TAG:-do .env})"
docker compose -f "${COMPOSE_FILE}" pull

echo "→ Restart dos serviços (release roda migrations antes)"
docker compose -f "${COMPOSE_FILE}" up -d

echo "→ Prune de imagens antigas"
docker image prune -f

echo "→ Status final"
docker compose -f "${COMPOSE_FILE}" ps

echo ""
echo "Deploy concluído. Pra acompanhar logs:"
echo "  docker compose -f ${COMPOSE_FILE} logs -f --tail=100 web worker"
