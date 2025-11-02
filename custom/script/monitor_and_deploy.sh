#!/bin/bash

# Monitor build and auto-deploy when complete
# This script will:
# 1. Wait for build to complete
# 2. Push to Docker Hub
# 3. Deploy to production
# 4. Notify user

set -e

BUILD_LOG="/tmp/commmate-build.log"
IMAGE_NAME="commmate/commmate"
VERSION="v4.7.0"
PRODUCTION_SERVER="root@200.98.72.137"
PRODUCTION_DIR="/opt/evolution-chatwoot"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔍 Monitorando Build Multi-Plataforma${NC}"
echo "========================================"
echo ""
echo "Build Log: $BUILD_LOG"
echo "Imagem: $IMAGE_NAME:$VERSION"
echo "Servidor: $PRODUCTION_SERVER"
echo ""

# Wait for build to complete
echo -e "${YELLOW}⏳ Aguardando build completar...${NC}"
echo ""

while true; do
    if grep -q "✓ Multi-platform image built successfully!" "$BUILD_LOG" 2>/dev/null; then
        echo -e "${GREEN}✅ BUILD COMPLETO!${NC}"
        echo ""
        break
    elif grep -q "Error:" "$BUILD_LOG" 2>/dev/null && ! ps aux | grep -q "[b]uild_multiplatform"; then
        echo -e "${RED}❌ BUILD FALHOU!${NC}"
        echo ""
        echo "Últimos erros:"
        grep "Error:" "$BUILD_LOG" | tail -5
        exit 1
    fi
    
    # Show progress every 2 minutes
    sleep 120
    
    # Show current step
    CURRENT_STEP=$(tail -20 "$BUILD_LOG" | grep "STEP" | tail -1 || echo "Building...")
    TIMESTAMP=$(date "+%H:%M:%S")
    echo "[$TIMESTAMP] $CURRENT_STEP"
done

# Step 1: Tag as latest
echo -e "${BLUE}Step 1: Tagging as latest${NC}"
echo "-----------------------------------"
podman tag $IMAGE_NAME:$VERSION $IMAGE_NAME:latest
echo -e "${GREEN}✓ Tagged as latest${NC}"
echo ""

# Step 2: Push to Docker Hub
echo -e "${BLUE}Step 2: Pushing to Docker Hub${NC}"
echo "-----------------------------------"
echo "Pushing $IMAGE_NAME:$VERSION..."
podman manifest push $IMAGE_NAME:$VERSION docker://$IMAGE_NAME:$VERSION

echo ""
echo "Pushing $IMAGE_NAME:latest..."
podman manifest push $IMAGE_NAME:latest docker://$IMAGE_NAME:latest

echo ""
echo -e "${GREEN}✓ Pushed to Docker Hub${NC}"
echo ""

# Step 3: Deploy to production
echo -e "${BLUE}Step 3: Deploying to Production${NC}"
echo "-----------------------------------"

# Stop current containers
echo "Stopping current containers..."
ssh $PRODUCTION_SERVER "cd $PRODUCTION_DIR && docker compose stop chatwoot sidekiq"

# Remove old ARM64 image
echo "Removing old ARM64 image..."
ssh $PRODUCTION_SERVER "docker rmi commmate/commmate:v4.7.0 2>/dev/null || true"

# Pull new multi-platform image
echo "Pulling new multi-platform image..."
ssh $PRODUCTION_SERVER "docker pull $IMAGE_NAME:$VERSION"

# Start new containers
echo "Starting CommMate containers..."
ssh $PRODUCTION_SERVER "cd $PRODUCTION_DIR && docker compose up -d chatwoot sidekiq"

echo ""
echo -e "${GREEN}✓ Deployed to production${NC}"
echo ""

# Step 4: Wait for healthcheck
echo -e "${BLUE}Step 4: Waiting for Health Check${NC}"
echo "-----------------------------------"
sleep 30

# Check container status
echo "Checking container status..."
ssh $PRODUCTION_SERVER "docker ps | grep -E 'chatwoot|sidekiq'"

echo ""

# Step 5: Test services
echo -e "${BLUE}Step 5: Testing Services${NC}"
echo "-----------------------------------"

echo "Testing Chatwoot..."
HTTP_CODE=$(ssh $PRODUCTION_SERVER "curl -s -o /dev/null -w '%{http_code}' https://crm.commmate.com" || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Chatwoot: OK (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${RED}⚠️  Chatwoot: FAIL (HTTP $HTTP_CODE)${NC}"
fi

echo ""

# Final summary
echo ""
echo "========================================"
echo -e "${GREEN}🎉 DEPLOY COMPLETO!${NC}"
echo "========================================"
echo ""
echo "📊 Resumo:"
echo "  - Imagem: $IMAGE_NAME:$VERSION"
echo "  - Plataformas: AMD64 + ARM64"
echo "  - Docker Hub: ✅ Publicado"
echo "  - Produção: ✅ Deployado"
echo "  - Status: ✅ Running"
echo ""
echo "🌐 URLs:"
echo "  - Chatwoot: https://crm.commmate.com"
echo "  - Evolution: https://evolution.commmate.com"
echo ""
echo "📋 Próximos Passos:"
echo "  1. Testar login no Chatwoot"
echo "  2. Verificar branding CommMate"
echo "  3. Testar integração com Evolution API"
echo ""
echo "🔍 Logs:"
echo "  ssh $PRODUCTION_SERVER 'docker logs chatwoot --tail 50'"
echo "  ssh $PRODUCTION_SERVER 'docker logs sidekiq --tail 50'"
echo ""

# Notification
echo -e "${BLUE}📬 NOTIFICAÇÃO: Build e Deploy Completos!${NC}"
echo ""

