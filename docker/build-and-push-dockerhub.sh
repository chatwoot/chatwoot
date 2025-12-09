#!/bin/bash
# BlazeChat - Build and push to Docker Hub
# Repository: papalocord/blazechat-v1

set -e

# Configuration
REGISTRY="docker.io"
IMAGE_NAME="papalocord/blazechat-v1"
VERSION="${1:-latest}"

echo "Building BlazeChat Docker image for Docker Hub..."
echo "Image: $IMAGE_NAME:$VERSION"

# Build the image
docker build -t "$IMAGE_NAME:$VERSION" -f docker/Dockerfile .

# Tag as latest if version is specified
if [ "$VERSION" != "latest" ]; then
    docker tag "$IMAGE_NAME:$VERSION" "$IMAGE_NAME:latest"
fi

echo "Pushing to Docker Hub..."
docker push "$IMAGE_NAME:$VERSION"

if [ "$VERSION" != "latest" ]; then
    docker push "$IMAGE_NAME:latest"
fi

echo "Done! Image pushed successfully to Docker Hub."
echo "  - $IMAGE_NAME:$VERSION"
if [ "$VERSION" != "latest" ]; then
    echo "  - $IMAGE_NAME:latest"
fi
