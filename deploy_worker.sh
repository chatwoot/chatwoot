#!/bin/bash
# Real deploy steps — run AFTER repo is updated (git pull/reset). Do not `git pull`
# from this file: replacing deploy.sh while `bash deploy.sh` runs leaves bash executing
# the old script from memory, so rbenv/PATH never apply.

set -e
export RACK_TIMEOUT_SERVICE_TIMEOUT=120

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

# Non-interactive SSH: mimic login PATH (rbenv, nvm, etc.)
if [[ -f "$HOME/.bash_profile" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.bash_profile"
elif [[ -f "$HOME/.profile" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.profile"
fi

if [[ -x "$HOME/.rbenv/bin/rbenv" ]]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init - bash)"
elif command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - bash)"
fi

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck source=/dev/null
  source "$NVM_DIR/nvm.sh"
fi

if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.asdf/asdf.sh"
fi

if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.rvm/scripts/rvm"
fi

if ! command -v bundle >/dev/null 2>&1; then
  echo "ERROR: bundle not found after loading shell env. PATH=$PATH" >&2
  exit 127
fi

echo "📦 Installing dependencies..."
bundle install
pnpm install

echo "🔨 Precompiling assets..."
bundle exec rake assets:precompile

if pm2 list | grep -q "chatwoot"; then
  echo "🛑 Stopping existing PM2 process..."
  pm2 stop chatwoot
  pm2 delete chatwoot
else
  echo "ℹ️  No existing PM2 process found, skipping stop/delete..."
fi

echo "▶️  Starting server with PM2..."
pm2 start pnpm --name chatwoot --interpreter bash -- start:production

echo "💾 Saving PM2 configuration..."
pm2 save

echo "✅ Deployment complete!"
echo "📊 Check status with: pm2 status"
echo "📝 View logs with: pm2 logs chatwoot"
