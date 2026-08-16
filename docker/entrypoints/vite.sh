#!/bin/sh
set -x

rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

pnpm store prune
pnpm install --force

# The widget embed serves the SDK at /packs/js/sdk.js, but the dev pipeline
# (Vite dev server) never produces it. It's built only by `build:sdk` (the
# production assets:precompile path). Rebuild it on boot whenever it's missing
# (e.g. a fresh `up` where the packs volume doesn't yet contain it) so the live
# chat widget keeps working without a manual build step.
if [ ! -s public/packs/js/sdk.js ]; then
  echo "SDK bundle missing; running build:sdk..."
  pnpm build:sdk
fi

echo "Ready to run Vite development server."

exec "$@"
