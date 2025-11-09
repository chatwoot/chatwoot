#!/bin/bash

# Monitor build and publish to Docker Hub when complete
# This script will:
# 1. Wait for build to complete
# 2. Push to Docker Hub
# Usage: ./monitor_and_publish.sh <version> [--tag-latest]

set -e

BUILD_LOG="/tmp/chatwoot-build-${1:-v4.7.0}.log"
IMAGE_NAME="commmate/commmate"
VERSION="${1:-v4.7.0}"
TAG_LATEST=false

# Check if --tag-latest flag is provided
if [[ "$*" == *"--tag-latest"* ]]; then
    TAG_LATEST=true
fi

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
echo "Tag Latest: $TAG_LATEST"
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

# Step 1: Tag as latest (if requested)
if [ "$TAG_LATEST" = true ]; then
    echo -e "${BLUE}Step 1: Tagging as latest${NC}"
    echo "-----------------------------------"
    podman tag $IMAGE_NAME:$VERSION $IMAGE_NAME:latest
    echo -e "${GREEN}✓ Tagged as latest${NC}"
    echo ""
fi

# Step 2: Push to Docker Hub
echo -e "${BLUE}Step 2: Pushing to Docker Hub${NC}"
echo "-----------------------------------"
echo "Pushing $IMAGE_NAME:$VERSION..."
podman manifest push $IMAGE_NAME:$VERSION docker://$IMAGE_NAME:$VERSION
echo -e "${GREEN}✓ Pushed $IMAGE_NAME:$VERSION${NC}"
echo ""

if [ "$TAG_LATEST" = true ]; then
    echo "Pushing $IMAGE_NAME:latest..."
    podman manifest push $IMAGE_NAME:latest docker://$IMAGE_NAME:latest
    echo -e "${GREEN}✓ Pushed $IMAGE_NAME:latest${NC}"
    echo ""
fi

# Final summary
echo ""
echo "========================================"
echo -e "${GREEN}🎉 PUBLICAÇÃO COMPLETA!${NC}"
echo "========================================"
echo ""
echo "📊 Resumo:"
echo "  - Imagem: $IMAGE_NAME:$VERSION"
echo "  - Plataformas: AMD64 + ARM64"
echo "  - Docker Hub: ✅ Publicado"
if [ "$TAG_LATEST" = true ]; then
    echo "  - Latest Tag: ✅ Atualizado"
else
    echo "  - Latest Tag: ⏭️  Não modificado"
fi
echo ""
echo "🐳 Docker Hub:"
echo "  - https://hub.docker.com/r/$IMAGE_NAME/tags"
echo ""
echo "📋 Para fazer deploy em produção:"
echo "  ssh root@200.98.72.137"
echo "  cd /opt/evolution-chatwoot"
echo "  # Edite docker-compose.yaml com a nova versão: $VERSION"
echo "  docker compose pull"
echo "  docker compose up -d chatwoot sidekiq"
echo ""

