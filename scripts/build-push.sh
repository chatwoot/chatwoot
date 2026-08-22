#!/usr/bin/env bash
#
# build-push.sh — multi-architecture build & push for the KiraID chatwoot image.
#
# Builds for linux/amd64 AND linux/arm64 and pushes a single multi-arch manifest
# (`:latest` + `:<version>`) to ghcr.io/kira-id/chatwoot. The production stack
# (docker-compose.production.yaml) pulls that image — no local build needed on
# the host.
#
# The image recipe lives at docker/Dockerfile and already targets Rails in
# production mode by default (RAILS_ENV=production, assets precompiled), so the
# same recipe works for both architectures without edits.
#
# Prerequisites:
#   - docker (with buildx + the docker-container driver)
#   - logged in to ghcr.io, OR $GITHUB_TOKEN (+ optional $GHCR_USER) set
#   - network access (pulls base images, gems, pnpm deps, qemu)
#
# Usage:
#   ./scripts/build-push.sh                       # build amd64+arm64 and push
#   ./scripts/build-push.sh --no-push             # build single-arch locally (--load), no push
#   ./scripts/build-push.sh --no-cache            # force a clean rebuild
#   ./scripts/build-push.sh --version 4.16.2      # override the tag version
#   ./scripts/build-push.sh --dry-run             # print commands, do nothing
#   ./scripts/build-push.sh --help
#
# Exit codes: 0 ok, 1 usage/abort, 2 build failed.

set -euo pipefail

# ----------------------------------------------------------------------------- config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE="ghcr.io/kira-id/chatwoot"
DOCKERFILE="$REPO_ROOT/docker/Dockerfile"
BUILDER="kiraid-multiarch"
PLATFORMS="linux/amd64,linux/arm64"
LOCAL_PLATFORM="linux/amd64"   # used only for --no-push local builds
BUILD_CACHE="${IMAGE}:buildcache"   # registry-backed layer cache (D)

PUSH=1            # default: build + push
NO_CACHE=0
DRY_RUN=0
VERSION=""

# ----------------------------------------------------------------------------- helpers
log()  { printf '\033[1;34m[build-push]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[build-push]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[build-push]\033[0m %s\n' "$*" >&2; exit "${2:-1}"; }

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '\033[2m+ %s\033[0m\n' "$*"
  else
    eval "$@"
  fi
}

usage() {
  grep '^#' "$0" | sed 's/^#\{1,2\} //' | sed '/^---/q' | sed '$d'
}

# ----------------------------------------------------------------------------- args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-push)  PUSH=0 ;;
    --no-cache) NO_CACHE=1 ;;
    --dry-run)  DRY_RUN=1 ;;
    --version)  [[ $# -ge 2 ]] || die "--version needs an argument" 1
                VERSION="$2"; shift ;;
    --help|-h)  usage; exit 0 ;;
    *) die "unknown arg: $1 (try --help)" 1 ;;
  esac
  shift
done

cd "$REPO_ROOT"

# ----------------------------------------------------------------------------- version
# Chatwoot has no pyproject.toml; the app version lives in package.json.
if [[ -z "$VERSION" ]]; then
  VERSION="$(grep -m1 '"version"' package.json | sed -E 's/.*"version"\s*:\s*"([0-9][0-9.]*[0-9])".*/\1/')"
  [[ -n "$VERSION" ]] || die "could not parse version from package.json" 1
fi
log "image: $IMAGE  version: $VERSION  push: $([[ $PUSH -eq 1 ]] && echo yes || echo no)"

# ----------------------------------------------------------------------------- prereqs
command -v docker >/dev/null 2>&1 || die "docker not found in PATH" 1
docker buildx version >/dev/null 2>&1 || die "docker buildx not available (upgrade Docker)" 1

# GHCR auth: reuse an existing login, else try $GITHUB_TOKEN.
ensure_ghcr_login() {
  if grep -q '"ghcr.io"' "${DOCKER_CONFIG:-$HOME/.docker}/config.json" 2>/dev/null; then
    log "already authenticated to ghcr.io"
    return 0
  fi
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    local user="${GHCR_USER:-kira-id}"
    log "logging in to ghcr.io as '$user' via GITHUB_TOKEN"
    printf '%s' "$GITHUB_TOKEN" | docker login ghcr.io -u "$user" --password-stdin
    return 0
  fi
  die "not logged in to ghcr.io. Run: docker login ghcr.io -u <user>\n  (or set GITHUB_TOKEN [+ GHCR_USER] for CI)" 1
}

if [[ "$PUSH" -eq 1 ]]; then
  ensure_ghcr_login
fi

# ----------------------------------------------------------------------------- builder + qemu
# The default 'docker' driver can only build the native arch. We need a
# docker-container driver builder plus QEMU user-emulation to cross-build arm64.
if ! docker buildx inspect "$BUILDER" >/dev/null 2>&1; then
  log "creating buildx builder '$BUILDER'"
  run "docker buildx create --name '$BUILDER' --driver docker-container --bootstrap"
fi
run "docker buildx use '$BUILDER'"

if [[ "$DRY_RUN" -eq 0 ]]; then
  log "installing/refreshing QEMU binfmt for cross-arch builds"
  docker run --privileged --rm tonistiigi/binfmt:latest --install all
fi

# ----------------------------------------------------------------------------- build
TAGS=( "$IMAGE:latest" "$IMAGE:$VERSION" )
TAG_ARGS=()
for t in "${TAGS[@]}"; do TAG_ARGS+=( --tag "$t" ); done

CACHE_ARG=""
[[ "$NO_CACHE" -eq 1 ]] && CACHE_ARG="--no-cache"

# Registry-backed layer cache (D). On every build we pull reusable layers from
# the cache image and push newly-built ones back. After the first successful
# push, only CHANGED layers upload — turning a full rebuild into a few minutes.
# Skipped entirely with --no-cache. --no-push local builds can't use a registry
# cache (no push target) so they fall back to inline.
if [[ "$NO_CACHE" -eq 0 && "$PUSH" -eq 1 ]]; then
  CACHE_FROM="--cache-from=type=registry,ref=${BUILD_CACHE}"
  CACHE_TO="--cache-to=type=registry,ref=${BUILD_CACHE},mode=max"
fi

if [[ "$PUSH" -eq 1 ]]; then
  log "building ${PLATFORMS} and pushing multi-arch manifest (Dockerfile: docker/Dockerfile)"
  run "docker buildx build \
    --platform '${PLATFORMS}' \
    --builder '${BUILDER}' \
    -f '${DOCKERFILE}' \
    ${CACHE_FROM:-} ${CACHE_TO:-} \
    ${CACHE_ARG} \
    ${TAG_ARGS[*]} \
    --push \
    ."
else
  log "building single-arch (${LOCAL_PLATFORM}) locally with --load (multi-arch needs --push)"
  run "docker buildx build \
    --platform '${LOCAL_PLATFORM}' \
    --builder '${BUILDER}' \
    -f '${DOCKERFILE}' \
    ${CACHE_ARG} \
    --tag '${IMAGE}:latest' \
    --load \
    ."
fi

# ----------------------------------------------------------------------------- verify
if [[ "$DRY_RUN" -eq 0 && "$PUSH" -eq 1 ]]; then
  log "manifest for ${IMAGE}:latest:"
  docker buildx imagetools inspect "${IMAGE}:latest" || warn "could not inspect manifest (image may still be pushing)"
  echo
  log "done. Pull/deploy with:  docker compose -f docker-compose.production.yaml up -d"
fi
