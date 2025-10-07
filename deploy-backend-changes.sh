#!/bin/bash
set -e

echo "=== Backend Code Deployment (Routes, Controllers, Models) ==="

# Sync backend code to server
echo "Step 1: Syncing backend code to server..."
rsync -avz --delete \
    --exclude='node_modules' \
    --exclude='tmp' \
    --exclude='log' \
    --exclude='.git' \
    --exclude='storage' \
    --exclude='*.tar.gz' \
    --exclude='public/vite' \
    --include='config/routes.rb' \
    --include='app/controllers/***' \
    --include='app/models/***' \
    --include='config/initializers/***' \
    --include='docs/***' \
    ./ root@msp.rhaps.net:/opt/chatwoot/

# Update running containers
echo "Step 2: Updating running containers with backend changes..."
ssh root@msp.rhaps.net 'bash -s' << 'ENDSSH'
set -e
cd /opt/chatwoot

# Get container IDs
WEB_CONTAINER=$(docker compose -f docker-compose.production.yml ps -q web)
WORKER_CONTAINER=$(docker compose -f docker-compose.production.yml ps -q worker)

if [ -z "$WEB_CONTAINER" ]; then
    echo "Web container not running, starting it..."
    docker compose -f docker-compose.production.yml up -d web
    sleep 5
    WEB_CONTAINER=$(docker compose -f docker-compose.production.yml ps -q web)
fi

echo "Copying backend code to web container ($WEB_CONTAINER)..."
docker cp config/routes.rb $WEB_CONTAINER:/app/config/routes.rb
docker cp app/controllers/webhooks/apple_messages_for_business_controller.rb $WEB_CONTAINER:/app/app/controllers/webhooks/apple_messages_for_business_controller.rb
docker cp app/models/channel/apple_messages_for_business.rb $WEB_CONTAINER:/app/app/models/channel/apple_messages_for_business.rb
docker cp config/initializers/apple_messages_for_business.rb $WEB_CONTAINER:/app/config/initializers/apple_messages_for_business.rb

if [ -n "$WORKER_CONTAINER" ]; then
    echo "Copying backend code to worker container ($WORKER_CONTAINER)..."
    docker cp config/routes.rb $WORKER_CONTAINER:/app/config/routes.rb
    docker cp app/controllers/webhooks/apple_messages_for_business_controller.rb $WORKER_CONTAINER:/app/app/controllers/webhooks/apple_messages_for_business_controller.rb
    docker cp app/models/channel/apple_messages_for_business.rb $WORKER_CONTAINER:/app/app/models/channel/apple_messages_for_business.rb
    docker cp config/initializers/apple_messages_for_business.rb $WORKER_CONTAINER:/app/config/initializers/apple_messages_for_business.rb
fi

echo "Restarting services to load new code..."
docker compose -f docker-compose.production.yml restart web worker

echo "Waiting for restart..."
sleep 10

echo "Service status:"
docker compose -f docker-compose.production.yml ps

echo "Checking routes..."
docker exec $WEB_CONTAINER bundle exec rails routes | grep "webhooks/apple_messages_for_business"

echo "Deployment complete!"
ENDSSH

echo "=== Deployment Complete ==="
echo "Application available at: https://msp.rhaps.net"
echo ""
echo "Verify the new webhook routes:"
echo "  - POST /webhooks/apple_messages_for_business/message"
echo "  - POST /webhooks/apple_messages_for_business"
echo ""
echo "Monitor logs with:"
echo "  ssh root@msp.rhaps.net \"cd /opt/chatwoot && docker compose -f docker-compose.production.yml logs web -f | grep 'AMB Webhook'\""