#!/bin/bash
# Thin entrypoint: update repo, then run steps in a NEW shell so the worker script
# is read from disk after pull (avoids bash continuing an outdated in-memory copy).

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "🚀 Starting deployment..."
echo "📥 Pulling latest code from develop branch..."
git pull origin develop

exec bash "$REPO_ROOT/deploy_worker.sh"
