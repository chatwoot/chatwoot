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

# Usa o compose de produção como base (evita o dev compose, que monta código)
BASE="docker-compose.production.yaml"
[ -f "$BASE" ] || BASE="docker-compose.yaml"

# Ajustes específicos do servidor (não commitados): senha do Postgres e porta pública
sed -i 's|      - POSTGRES_PASSWORD=.*|      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}|' "$BASE"
sed -i "s|      - '127.0.0.1:3000:3000'|      - '3000:3000'|" "$BASE"

COMPOSE="docker compose -f $BASE -f docker-compose.premium.yml"

$COMPOSE build rails
$COMPOSE up -d --force-recreate
sleep 25
$COMPOSE exec -T redis redis-cli -a "$REDIS_PASSWORD" --no-auth-warning FLUSHALL

PLAN=$($COMPOSE exec -T rails bundle exec rails runner 'puts "PREMIUM_CANARY_PLAN=#{ChatwootHub.pricing_plan}"' 2>/dev/null | grep -o 'PREMIUM_CANARY_PLAN=[^[:space:]]*' | head -n1 | cut -d= -f2)
QTY=$($COMPOSE exec -T rails bundle exec rails runner 'puts "PREMIUM_CANARY_QTY=#{ChatwootHub.pricing_plan_quantity}"' 2>/dev/null | grep -o 'PREMIUM_CANARY_QTY=[^[:space:]]*' | head -n1 | cut -d= -f2)
echo "canário: plano=$PLAN qtd=$QTY"

[ "$PLAN" = "enterprise" ] || { echo "FALHOU: plano voltou para $PLAN"; exit 1; }
echo "OK"