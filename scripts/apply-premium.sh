#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

TAG="${1:?uso: scripts/apply-premium.sh v4.19.1}"
set -a; source .env; set +a
export CHATWOOT_TAG="$TAG"

if grep -q '^CHATWOOT_TAG=' .env; then
  sed -i "s|^CHATWOOT_TAG=.*|CHATWOOT_TAG=$TAG|" .env
else
  echo "CHATWOOT_TAG=$TAG" >> .env
fi

COMPOSE="docker compose -f docker-compose.yaml -f docker-compose.premium.yml"

$COMPOSE build rails
$COMPOSE up -d --force-recreate
sleep 25
docker compose exec -T redis redis-cli -a "$REDIS_PASSWORD" --no-auth-warning FLUSHALL

PLAN=$(docker compose exec -T rails bundle exec rails runner 'print ChatwootHub.pricing_plan')
QTY=$(docker compose exec -T rails bundle exec rails runner 'print ChatwootHub.pricing_plan_quantity')
echo "canário: plano=$PLAN qtd=$QTY"

[ "$PLAN" = "enterprise" ] || { echo "FALHOU: plano voltou para $PLAN"; exit 1; }
echo "OK"