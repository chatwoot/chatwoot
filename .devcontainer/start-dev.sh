#!/bin/bash

# Chatwoot Development Server Start Script
# Starts all Chatwoot services (Rails, Vite, Sidekiq)

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$(dirname "$0")/.."

echo -e "${BLUE}Starting Chatwoot Development Server...${NC}"
echo ""

# Check if containers are running
if ! docker compose -f .devcontainer/docker-compose.yml ps | grep -q "Up"; then
    echo -e "${YELLOW}Containers not running. Starting them...${NC}"
    docker compose -f .devcontainer/docker-compose.yml up -d
    echo "Waiting for services to be ready..."
    sleep 5
fi

echo -e "${GREEN}✅ Services are ready!${NC}"
echo ""
echo "=========================================="
echo -e "${YELLOW}Chatwoot is starting...${NC}"
echo ""
echo "Access points:"
echo "  🌐 App:      http://localhost:3000/app"
echo "  📮 Mailhog:  http://localhost:8025"
echo ""
echo "Login:"
echo "  📧 Email:    john@acme.inc"
echo "  🔑 Password: Password1!"
echo ""
echo "Press Ctrl+C to stop all services"
echo "=========================================="
echo ""

# Run the development server
rm ./.overmind.sock
docker compose -f .devcontainer/docker-compose.yml exec app bash -lc "cd /workspace && pnpm dev"

