#!/bin/bash

# Test CommMate locally with Docker Compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   CommMate Local Testing              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    echo -e "${YELLOW}⚠️  .env.production not found!${NC}"
    echo ""
    echo -e "${BLUE}Creating from template...${NC}"
    
    if [ -f "custom/config/env.production.template" ]; then
        cp custom/config/env.production.template .env.production
        echo -e "${GREEN}✅ Created .env.production${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  IMPORTANT: Edit .env.production and update:${NC}"
        echo -e "  • POSTGRES_PASSWORD"
        echo -e "  • REDIS_PASSWORD"
        echo -e "  • SECRET_KEY_BASE"
        echo -e "  • SMTP settings (if needed)"
        echo ""
        echo -e "${BLUE}Press Enter when ready to continue...${NC}"
        read
    else
        echo -e "${RED}❌ Template not found!${NC}"
        exit 1
    fi
fi

# Check if image exists
IMAGE_NAME="commmate/commmate:v4.7.0"
if ! docker image inspect ${IMAGE_NAME} > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  CommMate image not found locally${NC}"
    echo -e "${BLUE}Building image first...${NC}"
    echo ""
    ./script/build_commmate_image.sh
fi

# Start services
echo ""
echo -e "${BLUE}🚀 Starting CommMate services...${NC}"
echo ""

docker-compose -f docker-compose.commmate.yaml up -d

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ CommMate started successfully!${NC}"
    echo ""
    echo -e "${BLUE}📋 Service URLs:${NC}"
    echo -e "  • CommMate App: ${YELLOW}http://localhost:3000${NC}"
    echo -e "  • PostgreSQL:   ${YELLOW}localhost:5432${NC}"
    echo -e "  • Redis:        ${YELLOW}localhost:6379${NC}"
    echo ""
    echo -e "${BLUE}📊 View logs:${NC}"
    echo -e "  ${YELLOW}docker-compose -f docker-compose.commmate.yaml logs -f${NC}"
    echo ""
    echo -e "${BLUE}🛑 Stop services:${NC}"
    echo -e "  ${YELLOW}docker-compose -f docker-compose.commmate.yaml down${NC}"
    echo ""
    echo -e "${YELLOW}⏳ Waiting for services to be ready (30 seconds)...${NC}"
    sleep 30
    echo ""
    echo -e "${GREEN}✅ You can now access CommMate at http://localhost:3000${NC}"
else
    echo -e "${RED}❌ Failed to start CommMate!${NC}"
    exit 1
fi

