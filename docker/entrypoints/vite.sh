#!/bin/sh
set -x

rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/bootsnap /app/tmp/cache/vite

pnpm store prune
pnpm install --force

# Install both bundler versions to handle any conflicts
gem install bundler -v '2.5.11'
gem install bundler -v '2.5.16'

# Run bundle install to ensure all gems are properly set up
bundle install

echo "Ready to run Vite development server."

exec "$@"