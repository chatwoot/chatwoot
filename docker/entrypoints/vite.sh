#!/bin/sh
set -e

rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

pnpm install --frozen-lockfile

echo "Waiting for pnpm and bundle integrity to match lockfiles...."
PNPM="pnpm list --json | grep -q 'Missing dependencies'"
BUNDLE="bundle check"

until ! $PNPM && $BUNDLE
do
  sleep 2;
done

echo "Ready to run Vite development server."

exec "$@"
