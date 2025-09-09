#!/bin/sh
set -e

# Container initialization script for Chatwoot Rails application
echo "Starting Chatwoot Rails container initialization..."

# Set default environment if not specified
export RAILS_ENV=${RAILS_ENV:-production}

# Change to app directory
cd /app

# Ensure proper permissions for tmp and log directories
mkdir -p tmp/pids tmp/cache tmp/sockets log
chmod -R 755 tmp log

# Database preparation
echo "Preparing database..."
if [ "$RAILS_ENV" = "production" ]; then
  # In production, run migrations and seed if needed
  bundle exec rails db:prepare
else
  # In staging/development, create and migrate
  bundle exec rails db:create db:migrate
fi

# Precompile assets if needed (for production)
if [ "$RAILS_ENV" = "production" ] && [ ! -d "public/assets" ]; then
  echo "Precompiling assets..."
  bundle exec rails assets:precompile
fi

# Clear any existing PID files
rm -f tmp/pids/server.pid

# Start the Rails server
echo "Starting Chatwoot Rails server on port 3001..."
exec bundle exec rails server -b 0.0.0.0 -p 3001