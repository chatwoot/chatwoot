#!/bin/bash
# BlazeChat - Build and push to private registry
# Registry: registry.blaze.do

set -e

# Configuration
REGISTRY="registry.blaze.do"
IMAGE_NAME="blazechat"
VERSION="${1:-latest}"

echo "Building BlazeChat Docker image..."
echo "Registry: $REGISTRY"
echo "Image: $IMAGE_NAME:$VERSION"

# Build the image
docker build -t "$REGISTRY/$IMAGE_NAME:$VERSION" -f docker/Dockerfile .

# Tag as latest if version is specified
if [ "$VERSION" != "latest" ]; then
    docker tag "$REGISTRY/$IMAGE_NAME:$VERSION" "$REGISTRY/$IMAGE_NAME:latest"
fi

echo "Pushing to registry..."
docker push "$REGISTRY/$IMAGE_NAME:$VERSION"

if [ "$VERSION" != "latest" ]; then
    docker push "$REGISTRY/$IMAGE_NAME:latest"
fi

echo "Done! Image pushed successfully."
echo "  - $REGISTRY/$IMAGE_NAME:$VERSION"
if [ "$VERSION" != "latest" ]; then
    echo "  - $REGISTRY/$IMAGE_NAME:latest"
fi
