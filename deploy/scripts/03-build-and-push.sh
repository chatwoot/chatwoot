#!/bin/bash
# Build e push da imagem do fork para o registry self-hosted.
# Roda LOCAL (no Mac), não na VPS.
#
# Pré-requisitos:
#   - Estar no commit/tag desejado (ex: v0.1.0-synapseos no main)
#   - docker buildx ativo (Docker Desktop ou colima)
#   - login no registry:
#       docker login registry.dexidigital.com.br -u synapseos
#
# Uso:
#   bash deploy/scripts/03-build-and-push.sh v0.1.0-synapseos

set -euo pipefail

TAG="${1:?uso: $0 <tag>}"
REGISTRY="registry.dexidigital.com.br"
IMAGE="$REGISTRY/synapseos-chatwoot"

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
  -t "$IMAGE:latest" \
  --push \
  .

echo ""
echo "==> Confirmando no registry"
curl -sS -u synapseos:"${REGISTRY_PASS:-}" "https://$REGISTRY/v2/synapseos-chatwoot/tags/list" | jq .

echo ""
echo "OK. Imagem disponível em $IMAGE:$TAG"
