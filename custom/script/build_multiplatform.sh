#!/bin/bash

# CommMate Multi-Platform Image Builder
# Builds for both ARM64 (Mac M1/M2) and AMD64 (Production servers)
# Usage: ./custom/script/build_multiplatform.sh [version]

set -e

VERSION=${1:-"v4.7.0"}
IMAGE_NAME="commmate/commmate"
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🐳 Building CommMate Multi-Platform Image${NC}"
echo "=============================================="
echo ""
echo "Version: $VERSION"
echo "Image: $IMAGE_NAME:$VERSION"
echo "Build Date: $BUILD_DATE"
echo "Platforms: linux/amd64, linux/arm64"
echo ""

# Check if in correct directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}⚠ Error: Must run from chatwoot project root!${NC}"
    exit 1
fi

# Detect current branch/tag
CURRENT_BRANCH=$(git branch --show-current)
CURRENT_COMMIT=$(git rev-parse --short HEAD)
CURRENT_COMMIT_FULL=$(git rev-parse HEAD)

echo -e "${GREEN}Current branch: $CURRENT_BRANCH${NC}"
echo -e "${GREEN}Current commit: $CURRENT_COMMIT${NC}"
echo -e "${GREEN}CommMate SHA: $CURRENT_COMMIT_FULL${NC}"
echo ""

# Create manifest
echo "Step 1: Creating manifest"
echo "-----------------------------------"
podman manifest create $IMAGE_NAME:$VERSION || podman manifest create $IMAGE_NAME:$VERSION --amend
echo -e "${GREEN}✓ Manifest created${NC}"
echo ""

# Build for AMD64 (production servers)
echo "Step 2: Building for AMD64 (x86_64) - Production Servers"
echo "-----------------------------------"
echo ""
podman build \
    --platform linux/amd64 \
    --manifest $IMAGE_NAME:$VERSION \
    -f docker/Dockerfile.commmate \
    --build-arg RAILS_ENV=production \
    --build-arg NODE_OPTIONS="--max-old-space-size=4096" \
    --build-arg CACHE_BUST=$(date +%s) \
    --label "version=$VERSION" \
    --label "build-date=$BUILD_DATE" \
    --label "vcs-ref=$CURRENT_COMMIT" \
    --label "commmate-sha=$CURRENT_COMMIT_FULL" \
    --label "branch=$CURRENT_BRANCH" \
    --label "platform=amd64" \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ AMD64 build completed${NC}"
    echo ""
else
    echo -e "${RED}⚠ AMD64 build failed!${NC}"
    exit 1
fi

# Build for ARM64 (Mac M1/M2)
echo "Step 3: Building for ARM64 (Apple Silicon) - Local Development"
echo "-----------------------------------"
echo ""
podman build \
    --platform linux/arm64 \
    --manifest $IMAGE_NAME:$VERSION \
    -f docker/Dockerfile.commmate \
    --build-arg RAILS_ENV=production \
    --build-arg NODE_OPTIONS="--max-old-space-size=4096" \
    --label "version=$VERSION" \
    --label "build-date=$BUILD_DATE" \
    --label "vcs-ref=$CURRENT_COMMIT" \
    --label "commmate-sha=$CURRENT_COMMIT_FULL" \
    --label "branch=$CURRENT_BRANCH" \
    --label "platform=arm64" \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ ARM64 build completed${NC}"
    echo ""
else
    echo -e "${RED}⚠ ARM64 build failed!${NC}"
    exit 1
fi

# Inspect manifest
echo "Step 4: Manifest Details"
echo "-----------------------------------"
podman manifest inspect $IMAGE_NAME:$VERSION

echo ""
echo -e "${GREEN}✓ Multi-platform image built successfully!${NC}"
echo ""
echo "Manifest Details:"
echo "-----------------------------------"
podman manifest inspect $IMAGE_NAME:$VERSION | grep -E "platform|architecture"
echo ""
echo "Next Steps:"
echo "-----------------------------------"
echo "1. Tag as latest:"
echo "   podman tag $IMAGE_NAME:$VERSION $IMAGE_NAME:latest"
echo ""
echo "2. Push to Docker Hub:"
echo "   podman manifest push $IMAGE_NAME:$VERSION docker://$IMAGE_NAME:$VERSION"
echo "   podman manifest push $IMAGE_NAME:$VERSION docker://$IMAGE_NAME:latest"
echo ""
echo "3. Deploy to production"
echo ""

