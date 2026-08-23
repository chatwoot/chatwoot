#!/bin/sh
set -x

rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache 2>/dev/null || true
mkdir -p /app/tmp/cache

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
if ! pnpm install --prefer-offline --no-frozen-lockfile; then
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

# Boot debugging is done; keep the long-running watchdog loop quiet.
set +x

# Supervise the dev server instead of exec'ing it directly. Vite can end up
# alive-but-deaf (process running, port 3036 unbound) after an internal
# restart or crash; Rails then answers every /vite-dev/ request with
# ActionController::RoutingError while the container still looks healthy.
# Probing the port lets us detect that state and force a fresh start.
VITE_HEALTHCHECK_URL="http://127.0.0.1:${VITE_DEV_SERVER_PORT:-3036}/vite-dev/@vite/client"
# The dev server is single-threaded: a cold global-SCSS compile over the slow
# Docker/WSL bind mount can block the event loop (and thus stop answering the
# probe) for well over a minute. Probing every 5s with a tiny miss budget used
# to SIGKILL a perfectly healthy-but-compiling server, which forced a fresh
# cold compile and left the dashboard stuck on a white page. Allow ~3 minutes
# of continuous silence before treating the server as truly dead, so a slow
# compile is never killed. A genuinely hung server still gets restarted, just
# less eagerly.
PROBE_INTERVAL_SECONDS=5
MAX_FAILED_PROBES=36
BOOT_TIMEOUT_SECONDS=300

dev_server_responding() {
  curl -sf --max-time 2 -o /dev/null "$VITE_HEALTHCHECK_URL"
}

stop_vite_process_tree() {
  [ -n "$vite_pid" ] || return 0
  # setsid makes Vite its own process group leader so esbuild/sass children
  # receive the signal too.
  kill -TERM "-$vite_pid" 2>/dev/null || kill -TERM "$vite_pid" 2>/dev/null

  waited=0
  while kill -0 "$vite_pid" 2>/dev/null && [ "$waited" -lt 10 ]; do
    sleep 1
    waited=$((waited + 1))
  done
  kill -KILL "-$vite_pid" 2>/dev/null
  wait "$vite_pid" 2>/dev/null
  vite_pid=""
}

trap 'stop_vite_process_tree; exit 0' INT TERM

while true; do
  setsid "$@" &
  vite_pid=$!
  echo "[vite-watchdog] started dev server (pid $vite_pid)"

  # Wait for the first successful response before entering steady-state
  # monitoring, otherwise slow cold boots would count as failures.
  boot_wait=0
  until dev_server_responding; do
    if ! kill -0 "$vite_pid" 2>/dev/null ||
      [ "$boot_wait" -ge "$BOOT_TIMEOUT_SECONDS" ]; then
      break
    fi
    sleep "$PROBE_INTERVAL_SECONDS"
    boot_wait=$((boot_wait + PROBE_INTERVAL_SECONDS))
  done

  failed_probes=0
  while kill -0 "$vite_pid" 2>/dev/null &&
    [ "$failed_probes" -lt "$MAX_FAILED_PROBES" ]; do
    sleep "$PROBE_INTERVAL_SECONDS"
    if dev_server_responding; then
      failed_probes=0
    else
      failed_probes=$((failed_probes + 1))
      echo "[vite-watchdog] no response from $VITE_HEALTHCHECK_URL ($failed_probes/$MAX_FAILED_PROBES)"
    fi
  done

  if [ -n "$vite_pid" ] && kill -0 "$vite_pid" 2>/dev/null; then
    echo "[vite-watchdog] dev server stopped responding; restarting it..."
  else
    echo "[vite-watchdog] dev server exited; restarting it..."
  fi
  stop_vite_process_tree
  sleep 1
done
