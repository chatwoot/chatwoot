#!/bin/bash

set -e  # Exit on any error
export RACK_TIMEOUT_SERVICE_TIMEOUT=120

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
