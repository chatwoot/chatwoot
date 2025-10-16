#!/bin/bash
set -e

echo "=== Comprehensive Backend Deployment ==="
echo "This will deploy: models, controllers, services, routes, migrations"
echo ""

# Step 1: Sync all backend code to server
echo "Step 1: Syncing backend code to server..."
rsync -avz --delete \
    --exclude='node_modules' \
    --exclude='tmp' \
    --exclude='log' \
    --exclude='.git' \
    --exclude='storage' \
    --exclude='*.tar.gz' \
    --exclude='public/vite' \
    --exclude='.env' \
    --exclude='.env.*' \
    --include='app/***' \
    --include='config/***' \
    --include='db/migrate/***' \
    --include='lib/***' \
    ./ root@msp.rhaps.net:/opt/chatwoot/

# Step 2: Update running containers and run migrations
echo ""
echo "Step 2: Updating containers and running migrations..."
ssh root@msp.rhaps.net 'bash -s' << 'ENDSSH'
set -e
cd /opt/chatwoot

WEB_CONTAINER=$(docker compose -f docker-compose.production.yml ps -q web)
WORKER_CONTAINER=$(docker compose -f docker-compose.production.yml ps -q worker)

if [ -z "$WEB_CONTAINER" ]; then
    echo "❌ Web container not running!"
    exit 1
fi

echo "Copying backend code to web container..."
docker cp app/. $WEB_CONTAINER:/app/app/
docker cp config/. $WEB_CONTAINER:/app/config/
docker cp db/migrate/. $WEB_CONTAINER:/app/db/migrate/
docker cp lib/. $WEB_CONTAINER:/app/lib/ 2>/dev/null || true

if [ -n "$WORKER_CONTAINER" ]; then
    echo "Copying backend code to worker container..."
    docker cp app/. $WORKER_CONTAINER:/app/app/
    docker cp config/. $WORKER_CONTAINER:/app/config/
    docker cp lib/. $WORKER_CONTAINER:/app/lib/ 2>/dev/null || true
fi

echo ""
echo "Running database migrations..."
docker exec $WEB_CONTAINER bundle exec rails db:migrate RAILS_ENV=production

echo ""
echo "Checking migration status..."
docker exec $WEB_CONTAINER bundle exec rails db:migrate:status RAILS_ENV=production | tail -10

echo ""
echo "Restarting services..."
docker compose -f docker-compose.production.yml restart web worker

echo "Waiting for services to restart..."
sleep 8

echo ""
echo "Verifying services are running..."
docker compose -f docker-compose.production.yml ps

echo ""
echo "✅ Backend deployment complete!"
ENDSSH

echo ""
echo "=== Deployment Summary ==="
echo "✅ Models, controllers, services deployed"
echo "✅ Routes and configuration updated"
echo "✅ Database migrations executed"
echo "✅ Services restarted"
echo ""
echo "Application: https://msp.rhaps.net"
echo ""
echo "Monitor logs:"
echo "  ssh root@msp.rhaps.net \"cd /opt/chatwoot && docker compose -f docker-compose.production.yml logs web -f\""
