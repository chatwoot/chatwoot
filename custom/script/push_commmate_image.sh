#!/bin/bash

# Push CommMate images to Docker Hub

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
echo -e "${BLUE}║   CommMate Docker Image Pusher        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker is not running!${NC}"
    exit 1
fi

# Check if image exists
if ! docker image inspect ${TAG} > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Image ${TAG} not found!${NC}"
    echo -e "${YELLOW}Please build the image first:${NC}"
    echo -e "  ./script/build_commmate_image.sh"
    exit 1
fi

# Login to Docker Hub
echo -e "${BLUE}🔐 Logging in to Docker Hub...${NC}"
echo -e "${YELLOW}Please enter your Docker Hub credentials:${NC}"
echo ""

if ! docker login; then
    echo -e "${RED}❌ Docker login failed!${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🚀 Pushing CommMate images to Docker Hub...${NC}"
echo ""

# Push versioned tag
echo -e "${YELLOW}📤 Pushing ${TAG}...${NC}"
docker push ${TAG}

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to push ${TAG}${NC}"
    exit 1
fi

# Push latest tag
echo -e "${YELLOW}📤 Pushing ${LATEST_TAG}...${NC}"
docker push ${LATEST_TAG}

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to push ${LATEST_TAG}${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Push Successful!                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Images available at Docker Hub:${NC}"
echo -e "  • ${TAG}"
echo -e "  • ${LATEST_TAG}"
echo ""
echo -e "${BLUE}📋 Usage:${NC}"
echo -e "  Pull the image:"
echo -e "    ${YELLOW}docker pull ${TAG}${NC}"
echo ""
echo -e "  Use in docker-compose:"
echo -e "    ${YELLOW}image: ${TAG}${NC}"
echo ""
echo -e "  Deploy to Portainer:"
echo -e "    1. Go to Containers → Add Container"
echo -e "    2. Image: ${YELLOW}${TAG}${NC}"
echo -e "    3. Configure volumes and environment"
echo -e "    4. Deploy!"
echo ""

