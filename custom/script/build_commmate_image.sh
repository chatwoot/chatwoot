#!/bin/bash

# CommMate Image Builder
# Builds Docker image with full CommMate branding
# Usage: ./custom/script/build_commmate_image.sh [version]

set -e

VERSION=${1:-"latest"}
IMAGE_NAME="commmate/commmate"
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Detect if using docker or podman
if command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
elif command -v docker &> /dev/null; then
    CONTAINER_CMD="docker"
else
    echo "Error: Neither docker nor podman found!"
    exit 1
fi

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🐳 Building CommMate Image${NC}"
echo "===================================="
echo ""
echo "Container Tool: $CONTAINER_CMD"
echo "Version: $VERSION"
echo "Image: $IMAGE_NAME:$VERSION"
echo "Build Date: $BUILD_DATE"
echo ""

# Check if in correct directory
if [ ! -f "package.json" ]; then
    echo -e "${YELLOW}⚠ Error: Must run from chatwoot project root!${NC}"
    exit 1
fi

# Detect current branch/tag
CURRENT_BRANCH=$(git branch --show-current)
CURRENT_COMMIT=$(git rev-parse --short HEAD)

echo -e "${GREEN}Current branch: $CURRENT_BRANCH${NC}"
echo -e "${GREEN}Current commit: $CURRENT_COMMIT${NC}"
echo ""

# Pre-build checks
echo "Step 1: Pre-build Checks"
echo "-----------------------------------"

if [ ! -d "custom/assets" ]; then
    echo -e "${YELLOW}⚠ Warning: custom/assets not found!${NC}"
    exit 1
fi

if [ ! -f "custom/config/branding.yml" ]; then
    echo -e "${YELLOW}⚠ Warning: custom/config/branding.yml not found!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Custom assets found${NC}"
echo -e "${GREEN}✓ Branding config found${NC}"
echo ""

# Build with full Dockerfile
echo "Step 2: Building Image with $CONTAINER_CMD"
echo "-----------------------------------"
echo ""

$CONTAINER_CMD build \
    -f docker/Dockerfile.commmate \
    -t $IMAGE_NAME:$VERSION \
    -t $IMAGE_NAME:latest \
    --build-arg RAILS_ENV=production \
    --build-arg NODE_OPTIONS="--max-old-space-size=4096" \
    --label "version=$VERSION" \
    --label "build-date=$BUILD_DATE" \
    --label "vcs-ref=$CURRENT_COMMIT" \
    --label "branch=$CURRENT_BRANCH" \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Image built successfully!${NC}"
    echo ""
    echo "Image Details:"
    echo "-----------------------------------"
    $CONTAINER_CMD images $IMAGE_NAME:$VERSION
    echo ""
    echo "Next Steps:"
    echo "-----------------------------------"
    echo "1. Test locally:"
    echo "   $CONTAINER_CMD run -it --rm -p 3000:3000 $IMAGE_NAME:$VERSION"
    echo ""
    echo "2. Push to Docker Hub:"
    echo "   $CONTAINER_CMD push $IMAGE_NAME:$VERSION"
    echo "   $CONTAINER_CMD push $IMAGE_NAME:latest"
    echo ""
    echo "3. Deploy to production"
    echo ""
else
    echo -e "${YELLOW}⚠ Build failed! Check errors above${NC}"
    exit 1
fi

