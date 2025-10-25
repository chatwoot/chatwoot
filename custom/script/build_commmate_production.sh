#!/bin/bash

# Build CommMate Production Image
# Creates complete branded image for deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IMAGE_NAME="commmate/commmate"
VERSION="v4.7.0"
TAG="${IMAGE_NAME}:${VERSION}"
LATEST_TAG="${IMAGE_NAME}:latest"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   CommMate Production Image Builder   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Version:${NC} ${VERSION}"
echo -e "${YELLOW}Tag:${NC} ${TAG}"
echo ""

# Detect container runtime
if command -v podman &> /dev/null; then
    BUILD_CMD="podman build"
    echo -e "${GREEN}✅ Usando Podman${NC}"
elif command -v docker &> /dev/null; then
    BUILD_CMD="docker build"
    echo -e "${GREEN}✅ Usando Docker${NC}"
else
    echo -e "${RED}❌ Erro: Nem Podman nem Docker encontrados!${NC}"
    exit 1
fi
echo ""

# Check if Dockerfile exists
if [ ! -f "docker/Dockerfile.commmate" ]; then
    echo -e "${RED}❌ Erro: docker/Dockerfile.commmate não encontrado!${NC}"
    exit 1
fi

# Copy assets
echo -e "${BLUE}📦 Preparando assets CommMate...${NC}"
mkdir -p public/images public/commmate

if [ -f "custom/assets/images/logo-full.png" ]; then
    cp custom/assets/images/*.png public/images/ 2>/dev/null || true
    echo -e "${GREEN}  ✅ Logos copiados${NC}"
else
    echo -e "${YELLOW}  ⚠️  Logos não encontrados em custom/assets/images/${NC}"
fi

if [ -f "custom/assets/favicons/favicon.ico" ]; then
    cp custom/assets/favicons/* public/ 2>/dev/null || true
    echo -e "${GREEN}  ✅ Favicons copiados${NC}"
else
    echo -e "${YELLOW}  ⚠️  Favicons não encontrados em custom/assets/favicons/${NC}"
fi
echo ""

# Build image
echo -e "${BLUE}🔨 Building imagem CommMate...${NC}"
echo -e "${YELLOW}Isso pode levar 10-15 minutos...${NC}"
echo ""

$BUILD_CMD \
  -f docker/Dockerfile.commmate \
  -t ${TAG} \
  -t ${LATEST_TAG} \
  --build-arg RAILS_ENV=production \
  --build-arg NODE_ENV=production \
  .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ Build Completo com Sucesso!      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Imagens criadas:${NC}"
    echo -e "  • ${TAG}"
    echo -e "  • ${LATEST_TAG}"
    echo ""
    echo -e "${BLUE}📋 Próximos passos:${NC}"
    echo ""
    echo -e "  1. Testar localmente:"
    echo -e "     ${YELLOW}podman-compose -f docker-compose.commmate.yaml up${NC}"
    echo ""
    echo -e "  2. Push para Docker Hub:"
    echo -e "     ${YELLOW}./scripts/push_commmate_production.sh${NC}"
    echo ""
    echo -e "  3. Deploy no Portainer:"
    echo -e "     Use imagem: ${YELLOW}${TAG}${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ Build Falhou!                    ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    exit 1
fi

