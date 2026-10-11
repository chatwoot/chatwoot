#!/bin/sh
set -x

rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

if [ -f /app/node_modules/.pnpm/lock.yaml ] && cmp -s pnpm-lock.yaml /app/node_modules/.pnpm/lock.yaml; then
  echo 'JavaScript dependencies match pnpm-lock.yaml; skipping install.'
else
  pnpm store prune
  pnpm install --force
fi

echo "Ready to run Vite development server."

exec "$@"
