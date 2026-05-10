#!/bin/bash
# Build e push da imagem do fork Synapseos para o GitHub Container Registry.
# Roda LOCAL (no Mac), não na VPS.
#
# Pré-requisitos:
#   - Estar no commit/tag desejado (ex: v0.1.3-synapseos no custom/initial-cleanup)
#   - docker buildx ativo (Docker Desktop ou colima)
#   - login no GHCR:
#       echo $GHCR_TOKEN | docker login ghcr.io -u paraisolorrayne --password-stdin
#     (token precisa ter scopes: write:packages, read:packages)
#
# Uso:
#   bash deploy/scripts/03-build-and-push.sh v0.1.3-synapseos

set -euo pipefail

TAG="${1:?uso: $0 <tag>}"
REGISTRY="ghcr.io"
IMAGE_OWNER="paraisolorrayne"
IMAGE="$REGISTRY/$IMAGE_OWNER/synapseos-chatwoot"

# Confirmar que o git está limpo e na referência certa
git diff --quiet || { echo "ERRO: working tree sujo. Commit ou stash antes."; exit 1; }
echo "==> HEAD: $(git rev-parse HEAD) ($(git rev-parse --abbrev-ref HEAD))"
echo "==> Tag de imagem: $IMAGE:$TAG"
echo ""
read -p "Continuar? [y/N] " ok
[[ "$ok" == "y" || "$ok" == "Y" ]] || exit 1

echo ""
echo "==> Build (linux/amd64 — VPS é x86)"
docker buildx build \
  --platform=linux/amd64 \
  -f docker/Dockerfile \
  -t "$IMAGE:$TAG" \
  --build-arg "GIT_SHA=$(git rev-parse HEAD)" \
  --push \
  .

echo ""
echo "OK. Imagem disponível em $IMAGE:$TAG"
echo "==> Próximo passo na VPS:"
echo "    bash 05-rolling-update.sh $TAG"
