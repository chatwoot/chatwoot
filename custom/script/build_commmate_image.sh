#!/bin/bash

# CommMate Docker Image Build Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="commmate/commmate"
VERSION="v4.7.0"
TAG="${IMAGE_NAME}:${VERSION}"
LATEST_TAG="${IMAGE_NAME}:latest"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   CommMate Docker Image Builder       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Version:${NC} ${VERSION}"
echo -e "${YELLOW}Tag:${NC} ${TAG}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker is not running!${NC}"
    exit 1
fi

# Ensure assets are copied
echo -e "${BLUE}📦 Copying CommMate assets...${NC}"
if [ -f "script/copy_commmate_assets.sh" ]; then
    chmod +x script/copy_commmate_assets.sh
    ./script/copy_commmate_assets.sh
else
    echo -e "${YELLOW}⚠️  Warning: asset copy script not found${NC}"
fi

# Build the image
echo ""
echo -e "${BLUE}🔨 Building Docker image...${NC}"
echo -e "${YELLOW}This may take several minutes...${NC}"
echo ""

docker build \
  -f docker/Dockerfile.commmate \
  -t ${TAG} \
  -t ${LATEST_TAG} \
  --build-arg RAILS_ENV=production \
  --build-arg NODE_ENV=production \
  .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ Build Successful!                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Tags created:${NC}"
    echo -e "  • ${TAG}"
    echo -e "  • ${LATEST_TAG}"
    echo ""
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo -e "  1. Test locally:"
    echo -e "     ${YELLOW}docker-compose -f docker-compose.commmate.yaml up${NC}"
    echo ""
    echo -e "  2. Push to Docker Hub:"
    echo -e "     ${YELLOW}./script/push_commmate_image.sh${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ Build Failed!                     ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    exit 1
fi

