#!/bin/sh
set -x

rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

# Install dependencies, preferring already-cached tarballs in the pnpm store
# (mounted as the `pnpm_store` volume) so cold boots are a fast link pass
# instead of an 8000+ package re-download. `--prefer-offline` still fetches
# anything genuinely missing, and fails loudly if a required package can't be
# resolved at all (rather than silently producing a broken install).
#
# `CI=true` is required: with no TTY attached to the container, pnpm otherwise
# blocks on an interactive "reinstall from scratch? (Y/n)" prompt when it
# considers node_modules content stale/corrupt, which hangs `bin/vite dev`
# forever and leaves the dashboard with a missing Vite manifest
# (MissingEntrypointError). In CI mode pnpm answers the prompt automatically.
export CI=true
if ! pnpm install --prefer-offline; then
  echo "pnpm install failed; refusing to start Vite with a broken dependency tree." >&2
  exit 1
fi

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
