#!/usr/bin/env bash
set -euo pipefail

# Build and push djc-chat Docker image to Docker Hub.
# Cross-platform: builds linux/amd64 (DigitalOcean) by default, even on Apple Silicon Macs.
#
# Usage: ./scripts/docker-build-push.sh <tag> [<tag> ...]
# Example: ./scripts/docker-build-push.sh 1 2 3
#
# Env overrides:
#   DOCKER_USER   Docker Hub username (default: daveckw)
#   IMAGE_NAME    image name (default: djc-chat)
#   PLATFORMS     target platforms (default: linux/amd64)
#                 use "linux/amd64,linux/arm64" for multi-arch
#   NO_PUSH=1     build only, don't push

DOCKER_USER="${DOCKER_USER:-daveckw}"
IMAGE_NAME="${IMAGE_NAME:-djc-chat}"
PLATFORMS="${PLATFORMS:-linux/amd64}"
REPO="${DOCKER_USER}/${IMAGE_NAME}"

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <tag> [<tag> ...]"
  exit 1
fi

# Ensure a buildx builder exists that supports multi-platform builds.
BUILDER_NAME="djc-builder"
if ! docker buildx inspect "${BUILDER_NAME}" >/dev/null 2>&1; then
  echo ">>> Creating buildx builder: ${BUILDER_NAME}"
  docker buildx create --name "${BUILDER_NAME}" --driver docker-container --use
else
  docker buildx use "${BUILDER_NAME}"
fi
docker buildx inspect --bootstrap >/dev/null

TAG_ARGS=()
for tag in "$@"; do
  TAG_ARGS+=("-t" "${REPO}:${tag}")
done

if [ "${NO_PUSH:-0}" = "1" ]; then
  OUTPUT_FLAG="--load"
  # --load only supports a single platform
  if [[ "${PLATFORMS}" == *","* ]]; then
    echo "ERROR: NO_PUSH=1 requires a single platform (got: ${PLATFORMS})" >&2
    exit 1
  fi
  echo ">>> Building (no push) ${REPO} for ${PLATFORMS} with tags: $*"
else
  echo ">>> Logging in to Docker Hub (user: ${DOCKER_USER})"
  docker login -u "${DOCKER_USER}"
  OUTPUT_FLAG="--push"
  echo ">>> Building & pushing ${REPO} for ${PLATFORMS} with tags: $*"
fi

docker buildx build \
  --platform "${PLATFORMS}" \
  -f docker/Dockerfile \
  "${TAG_ARGS[@]}" \
  ${OUTPUT_FLAG} \
  .

echo ">>> Done. Tags: $*"
