#!/usr/bin/env bash
# Deploy script for Chatwoot on server-framky
# Run as chatwoot user or via GH Actions
set -euo pipefail

APP_DIR="/srv/chatwoot/chatwoot"
BRANCH="framky/main"

# Load rbenv
export PATH="/srv/chatwoot/.rbenv/bin:${PATH}"
eval "$(rbenv init -)"

echo "=== Deploying Chatwoot (${BRANCH}) ==="

cd "${APP_DIR}"

# Pull latest code
echo "Pulling latest changes..."
git fetch origin "${BRANCH}"
git checkout "${BRANCH}"
git pull origin "${BRANCH}"

# Ruby dependencies
echo "Installing Ruby dependencies..."
bundle install --deployment --without development test

# Node dependencies
echo "Installing Node dependencies..."
pnpm install --frozen-lockfile

# Assets
echo "Precompiling assets..."
RAILS_ENV=production NODE_ENV=production bundle exec rails assets:precompile

# Database migrations
echo "Running database migrations..."
RAILS_ENV=production bundle exec rails db:chatwoot_prepare

# Restart services
echo "Restarting Chatwoot services..."
sudo systemctl restart chatwoot.target

echo "Waiting for services to start..."
sleep 5

# Verify
if sudo systemctl is-active --quiet chatwoot-web.service; then
  echo "=== Deploy complete! chatwoot-web is running ==="
else
  echo "!! WARNING: chatwoot-web failed to start. Check logs:"
  echo "   journalctl -u chatwoot-web -n 50 --no-pager"
  exit 1
fi
