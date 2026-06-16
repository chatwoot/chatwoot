#!/usr/bin/env bash
# Omni-Chat-AI one-line installer for a fresh Ubuntu/Debian server.
#
#   curl -fsSL <raw-url>/install.sh | bash
#   curl -fsSL <raw-url>/install.sh | DOMAIN=example.com ACME_EMAIL=you@example.com bash
#
# Installs Docker, clones the repo, and runs deploy.sh (generates secrets + brings the stack up).
# Re-running updates to the latest code and redeploys. Override REPO_URL / BRANCH / TARGET as env.
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/alekseevconsult-coder/chatwoot.git}"
BRANCH="${BRANCH:-claude/omni-chat-ai-stack-7ydEC}"
TARGET="${TARGET:-/opt/omni-chat-ai}"
SUDO=""; [[ "$(id -u)" -ne 0 ]] && SUDO="sudo"

echo "▶ Installing prerequisites (git, curl, openssl)…"
if command -v apt-get >/dev/null 2>&1; then
  $SUDO apt-get update -y -qq
  $SUDO apt-get install -y -qq git curl openssl ca-certificates
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "▶ Installing Docker…"
  curl -fsSL https://get.docker.com | $SUDO sh
fi

# Ensure the Compose v2 plugin is available.
if ! docker compose version >/dev/null 2>&1; then
  echo "✗ Docker Compose v2 plugin not found. Install Docker Engine ≥ 20.10 with the compose plugin." >&2
  exit 1
fi

echo "▶ Fetching the project ($BRANCH)…"
if [[ -d "$TARGET/.git" ]]; then
  $SUDO git -C "$TARGET" fetch --depth 1 origin "$BRANCH"
  $SUDO git -C "$TARGET" checkout -B "$BRANCH" "origin/$BRANCH"
else
  $SUDO git clone --branch "$BRANCH" --depth 1 "$REPO_URL" "$TARGET"
fi

echo "▶ Deploying…"
cd "$TARGET/omni-chat-ai"
$SUDO env DOMAIN="${DOMAIN:-}" ACME_EMAIL="${ACME_EMAIL:-}" bash ./deploy.sh
