#!/bin/bash

# Chatwoot Development Environment Setup Script
# This script sets up and runs Chatwoot for the first time

set -e  # Exit on error

echo "🚀 Chatwoot Development Environment Setup"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to project root
cd "$(dirname "$0")/.."

echo -e "${BLUE}Step 1/6:${NC} Stopping any existing containers..."
docker compose -f .devcontainer/docker-compose.yml down 2>/dev/null || true

echo -e "${BLUE}Step 2/6:${NC} Building Docker images..."
docker compose -f .devcontainer/docker-compose.yml build --no-cache

echo -e "${BLUE}Step 3/6:${NC} Starting services (PostgreSQL, Redis, Mailhog)..."
docker compose -f .devcontainer/docker-compose.yml up -d

echo -e "${BLUE}Step 4/6:${NC} Waiting for database to be ready..."
sleep 10

echo -e "${BLUE}Step 5/6:${NC} Running database setup..."
docker compose -f .devcontainer/docker-compose.yml exec -T app bash -lc "cd /workspace && ./bin/setup"

echo -e "${BLUE}Step 6/6:${NC} Seeding database with demo data..."
docker compose -f .devcontainer/docker-compose.yml exec -T app bash -lc "cd /workspace && bin/rails db:seed"

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "=========================================="
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Start the application:"
echo "   ./devcontainer/start-dev.sh"
echo ""
echo "2. Access Chatwoot at:"
echo "   🌐 http://localhost:3000/app"
echo ""
echo "3. Login credentials:"
echo "   📧 Email: john@acme.inc"
echo "   🔑 Password: Password1!"
echo ""
echo "4. View test emails at:"
echo "   📮 http://localhost:8025"
echo ""
echo "=========================================="

