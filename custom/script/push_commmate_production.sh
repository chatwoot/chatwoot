#!/bin/bash

# Push CommMate Production Image to Docker Hub

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
echo -e "${BLUE}║   CommMate Image Push                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Detect container runtime
if command -v podman &> /dev/null; then
    PUSH_CMD="podman push"
    LOGIN_CMD="podman login"
    INSPECT_CMD="podman image inspect"
    echo -e "${GREEN}✅ Usando Podman${NC}"
elif command -v docker &> /dev/null; then
    PUSH_CMD="docker push"
    LOGIN_CMD="docker login"
    INSPECT_CMD="docker image inspect"
    echo -e "${GREEN}✅ Usando Docker${NC}"
else
    echo -e "${RED}❌ Erro: Nem Podman nem Docker encontrados!${NC}"
    exit 1
fi
echo ""

# Check if image exists
if ! $INSPECT_CMD ${TAG} > /dev/null 2>&1; then
    echo -e "${RED}❌ Erro: Imagem ${TAG} não encontrada!${NC}"
    echo ""
    echo -e "${YELLOW}Execute primeiro:${NC}"
    echo -e "  ./scripts/build_commmate_production.sh"
    exit 1
fi

# Login to Docker Hub
echo -e "${BLUE}🔐 Login no Docker Hub...${NC}"
echo -e "${YELLOW}Entre com suas credenciais Docker Hub:${NC}"
echo ""

if ! $LOGIN_CMD docker.io; then
    echo -e "${RED}❌ Login falhou!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🚀 Pushing imagens para Docker Hub...${NC}"
echo ""

# Push versioned tag
echo -e "${YELLOW}📤 Pushing ${TAG}...${NC}"
$PUSH_CMD ${TAG}

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Falha ao fazer push de ${TAG}${NC}"
    exit 1
fi

# Push latest tag
echo -e "${YELLOW}📤 Pushing ${LATEST_TAG}...${NC}"
$PUSH_CMD ${LATEST_TAG}

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Falha ao fazer push de ${LATEST_TAG}${NC}"
    exit 1
fi

# Success
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Push Completo com Sucesso!       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Imagens disponíveis no Docker Hub:${NC}"
echo -e "  • ${TAG}"
echo -e "  • ${LATEST_TAG}"
echo ""
echo -e "${BLUE}📋 Para usar:${NC}"
echo ""
echo -e "  Pull:"
echo -e "    ${YELLOW}docker pull ${TAG}${NC}"
echo ""
echo -e "  Portainer:"
echo -e "    Image: ${YELLOW}${TAG}${NC}"
echo ""

