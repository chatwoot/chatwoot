#!/bin/sh
set -x

rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

pnpm store prune
pnpm install --force

# Install Ruby gems needed for bin/vite script
bundle install

BUNDLE="bundle check"

until $BUNDLE
do
  sleep 2;
done

echo "Ready to run Vite development server."

exec "$@"
