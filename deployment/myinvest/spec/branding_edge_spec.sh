#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
assets_dir="$deployment_dir/brand-assets"
caddy_image='caddy:2.10.2-alpine@sha256:4c6e91c6ed0e2fa03efd5b44747b625fec79bc9cd06ac5235a779726618e530d'
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/myinvest-branding-edge.XXXXXX")"
network_name="myinvest-branding-$RANDOM-$$"
backend_name="$network_name-backend"
edge_name="$network_name-edge"

cleanup() {
  timeout 10s docker rm -f "$edge_name" "$backend_name" >/dev/null 2>&1 || true
  timeout 10s docker network rm "$network_name" >/dev/null 2>&1 || true
  rm -rf "$work_dir"
}
trap cleanup EXIT

for asset in logo.svg logo_dark.svg logo_thumbnail.png myinvest-pro-icon.png; do
  test -s "$assets_dir/$asset"
done
cmp "$assets_dir/myinvest-pro-icon.png" "$assets_dir/logo_thumbnail.png"
grep -Eq '<title([^>]*)>MyInvest Support</title>' "$assets_dir/logo.svg"
grep -Fq '>MyInvest Support</text>' "$assets_dir/logo.svg"
grep -Eq '<title([^>]*)>MyInvest Support</title>' "$assets_dir/logo_dark.svg"
grep -Fq '>MyInvest Support</text>' "$assets_dir/logo_dark.svg"
for wordmark in logo.svg logo_dark.svg; do
  sed -n 's/.*href="data:image\/png;base64,\([^"]*\)".*/\1/p' "$assets_dir/$wordmark" | base64 -d >"$work_dir/$wordmark.icon.png"
  cmp "$assets_dir/myinvest-pro-icon.png" "$work_dir/$wordmark.icon.png"
done

timeout 20s docker network create "$network_name" >/dev/null
timeout 20s docker run --detach --name "$backend_name" --network "$network_name" \
  --network-alias rails --network-alias claude-agent --entrypoint sh "$caddy_image" -c \
  'caddy respond --listen :3000 --status 204 & exec caddy respond --listen :8080 --status 202' >/dev/null
for port in 3000 8080; do
  for _ in $(seq 1 20); do
    timeout 3s docker exec "$backend_name" wget -q -T 2 -t 1 -O /dev/null "http://127.0.0.1:$port/" && break
    sleep 0.1
  done
  timeout 3s docker exec "$backend_name" wget -q -T 2 -t 1 -O /dev/null "http://127.0.0.1:$port/"
done
timeout 20s docker run --detach --name "$edge_name" --network "$network_name" \
  -e CADDY_SITE_ADDRESS=:80 \
  -e CADDY_SITE_SCHEME=http \
  -e INGRESS_MODE=direct \
  -e ACME_EMAIL=ops@example.invalid \
  -v "$deployment_dir/Caddyfile:/etc/caddy/Caddyfile:ro" \
  -v "$assets_dir:/srv/brand-assets:ro" \
  "$caddy_image" >/dev/null

for _ in $(seq 1 30); do
  timeout 3s docker exec "$edge_name" wget -q -T 2 -t 1 -O /dev/null http://127.0.0.1:2019/config/ && break
  sleep 0.2
done

timeout 5s docker exec "$edge_name" sh -c \
  "printf 'GET / HTTP/1.0\r\nHost: localhost\r\nConnection: close\r\n\r\n' | nc -w 2 127.0.0.1 80" \
  >"$work_dir/root.headers"
grep -Eq 'HTTP/1\.[01] 302' "$work_dir/root.headers"
grep -Eiq 'Location: /app/login' "$work_dir/root.headers"

for asset in logo.svg logo_dark.svg logo_thumbnail.png myinvest-pro-icon.png; do
  timeout 5s docker exec "$edge_name" wget -q -T 2 -t 1 -O - "http://127.0.0.1/brand-assets/$asset" >"$work_dir/$asset"
  cmp "$assets_dir/$asset" "$work_dir/$asset"
done

for path in health api/v1/accounts widget _agent/webhooks/chatwoot-other; do
  status="$(timeout 5s docker exec "$edge_name" wget -S -T 2 -t 1 -O /dev/null "http://127.0.0.1/$path" 2>&1 | sed -n 's/.*HTTP\/1\.[01] \([0-9][0-9][0-9]\).*/\1/p' | tail -n 1)"
  test "$status" = 204
done
webhook_status="$(timeout 5s docker exec "$edge_name" wget -S -T 2 -t 1 -O /dev/null \
  http://127.0.0.1/_agent/webhooks/chatwoot 2>&1 | sed -n 's/.*HTTP\/1\.[01] \([0-9][0-9][0-9]\).*/\1/p' | tail -n 1)"
test "$webhook_status" = 202

for ingress_mode in direct cloudflare_tunnel; do
  timeout 20s docker run --rm \
    -e CADDY_SITE_ADDRESS=localhost \
    -e CADDY_SITE_SCHEME=http \
    -e "INGRESS_MODE=$ingress_mode" \
    -e ACME_EMAIL=ops@example.invalid \
    -v "$deployment_dir/Caddyfile:/etc/caddy/Caddyfile:ro" \
    -v "$assets_dir:/srv/brand-assets:ro" \
    "$caddy_image" caddy validate --config /etc/caddy/Caddyfile >/dev/null
done

printf 'Branding edge behavior and assets are valid.\n'
