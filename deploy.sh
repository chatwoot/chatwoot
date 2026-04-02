#!/bin/bash

set -e  # Exit on any error
export RACK_TIMEOUT_SERVICE_TIMEOUT=120

# Non-interactive SSH (e.g. GitHub Actions appleboy/ssh-action) does not source
# ~/.bash_profile — rbenv/nvm are missing from PATH, so `bundle`/`pnpm` fail.
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

echo "🚀 Starting deployment..."

# Step 1: Pull latest code from develop branch
echo "📥 Pulling latest code from develop branch..."
git pull origin develop

# Step 2: Install dependencies (if needed)
echo "📦 Installing dependencies..."
bundle install
pnpm install

# Step 3: Precompile assets
echo "🔨 Precompiling assets..."
bundle exec rake assets:precompile

# Step 4: Stop existing PM2 process if running
if pm2 list | grep -q "chatwoot"; then
  echo "🛑 Stopping existing PM2 process..."
  pm2 stop chatwoot
  pm2 delete chatwoot
else
  echo "ℹ️  No existing PM2 process found, skipping stop/delete..."
fi


# Step 5: Start server with PM2
echo "▶️  Starting server with PM2..."
pm2 start pnpm --name chatwoot --interpreter bash -- start:production

# Step 6: Save PM2 configuration
echo "💾 Saving PM2 configuration..."
pm2 save

echo "✅ Deployment complete!"
echo "📊 Check status with: pm2 status"
echo "📝 View logs with: pm2 logs chatwoot"
