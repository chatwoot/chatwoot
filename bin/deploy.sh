#!/usr/bin/env bash
# ============================================================================
# AirysChat — Production Deploy Script
# ============================================================================
# Usage: ./bin/deploy.sh [--skip-pull] [--skip-migrate]
#
# Performs a zero-downtime rolling deploy:
#   1. Pull latest images
#   2. Run database migrations
#   3. Restart services one at a time (sidekiq first, then rails)
#   4. Verify health checks
# ============================================================================
set -euo pipefail

COMPOSE_FILE="docker-compose.production.yaml"
COMPOSE="docker compose -f $COMPOSE_FILE"

# ── Parse flags ──────────────────────────────────────────────────
SKIP_PULL=false
SKIP_MIGRATE=false
for arg in "$@"; do
  case $arg in
    --skip-pull)    SKIP_PULL=true ;;
    --skip-migrate) SKIP_MIGRATE=true ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

echo "═══════════════════════════════════════════════════════════"
echo " AirysChat Deploy — $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "═══════════════════════════════════════════════════════════"

# ── 1. Pull latest images ───────────────────────────────────────
if [ "$SKIP_PULL" = false ]; then
  echo "▶ Pulling latest images..."
  $COMPOSE pull
else
  echo "▶ Skipping image pull (--skip-pull)"
fi

# ── 2. Run database migrations ──────────────────────────────────
if [ "$SKIP_MIGRATE" = false ]; then
  echo "▶ Running database migrations..."
  $COMPOSE run --rm --no-deps rails bundle exec rails db:migrate
else
  echo "▶ Skipping migrations (--skip-migrate)"
fi

# ── 3. Restart services (rolling) ───────────────────────────────
echo "▶ Restarting sidekiq..."
$COMPOSE up -d --no-deps --force-recreate sidekiq

echo "▶ Restarting rails..."
$COMPOSE up -d --no-deps --force-recreate rails

echo "▶ Ensuring all services are up..."
$COMPOSE up -d

# ── 4. Health check ─────────────────────────────────────────────
echo "▶ Waiting for health checks..."
sleep 10

HEALTHY=true
for svc in rails postgres redis litellm; do
  STATUS=$($COMPOSE ps --format json "$svc" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('Health','unknown'))" 2>/dev/null || echo "unknown")
  if [ "$STATUS" = "healthy" ]; then
    echo "  ✓ $svc — healthy"
  else
    echo "  ✗ $svc — $STATUS"
    HEALTHY=false
  fi
done

if [ "$HEALTHY" = true ]; then
  echo ""
  echo "✅ Deploy complete — all services healthy"
else
  echo ""
  echo "⚠️  Deploy complete — some services not yet healthy (check logs)"
  echo "   $COMPOSE logs --tail=50 <service>"
fi

echo "═══════════════════════════════════════════════════════════"
