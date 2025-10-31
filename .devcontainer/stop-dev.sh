#!/bin/bash

# Chatwoot Development Server Stop Script
# Stops all running containers

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

cd "$(dirname "$0")/.."

echo -e "${BLUE}Stopping Chatwoot Development Environment...${NC}"

docker compose -f .devcontainer/docker-compose.yml down

echo ""
echo -e "${GREEN}✅ All services stopped!${NC}"

