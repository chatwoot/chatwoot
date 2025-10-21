#!/bin/sh
set -x

rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

pnpm store prune
pnpm install --force

echo "Ready to run Vite development server."

# Change to app directory and start Vite dev server
cd /app
exec pnpm exec vite --host 0.0.0.0 --port 3036
