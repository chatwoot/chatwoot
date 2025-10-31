#!/bin/bash

# Chatwoot Development Environment Reset Script
# Completely resets the development environment (removes all data)

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$(dirname "$0")/.."

echo -e "${RED}⚠️  WARNING: This will delete all database data and Docker volumes!${NC}"
echo ""
read -p "Are you sure you want to reset the development environment? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Reset cancelled."
    exit 0
fi

echo -e "${YELLOW}Stopping containers...${NC}"
docker compose -f .devcontainer/docker-compose.yml down

echo -e "${YELLOW}Removing volumes...${NC}"
docker compose -f .devcontainer/docker-compose.yml down -v

echo -e "${YELLOW}Removing built images...${NC}"
docker rmi devcontainer-app:latest 2>/dev/null || true

echo ""
echo -e "${GREEN}✅ Environment reset complete!${NC}"
echo ""
echo "Run './devcontainer/setup-dev.sh' to set up again."

