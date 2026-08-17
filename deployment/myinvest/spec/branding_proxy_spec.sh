#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
caddyfile="$deployment_dir/Caddyfile"
compose_file="$deployment_dir/compose.yaml"

grep -Eq '^[[:space:]]*@root[[:space:]]+path[[:space:]]+/[[:space:]]*(#.*)?$' "$caddyfile" || {
  printf 'Caddy must match only the exact root path with "@root path /".\n' >&2
  exit 1
}
grep -Eq '^[[:space:]]*redir[[:space:]]+@root[[:space:]]+/app/login[[:space:]]+302[[:space:]]*(#.*)?$' "$caddyfile" || {
  printf 'Caddy must temporarily redirect the exact root matcher to /app/login.\n' >&2
  exit 1
}

redirect_line="$(grep -En '^[[:space:]]*redir[[:space:]]+@root[[:space:]]+/app/login[[:space:]]+302[[:space:]]*(#.*)?$' "$caddyfile" | head -n 1 | cut -d: -f1)"
proxy_line="$(grep -En '^[[:space:]]*handle[[:space:]]*\{' "$caddyfile" | tail -n 1 | cut -d: -f1)"
if [[ -z "$proxy_line" || "$redirect_line" -ge "$proxy_line" ]]; then
  printf 'The root redirect must precede the catch-all proxy handler.\n' >&2
  exit 1
fi

chatwoot_compose="$(sed -n '/^x-chatwoot:/,/^services:/p' "$compose_file")"
grep -Fq -- '- ./chatwoot-config/premium_installation_config.yml:/app/enterprise/config/premium_installation_config.yml:ro' \
  <<<"$chatwoot_compose" || {
  printf 'Missing read-only Chatwoot premium configuration mount.\n' >&2
  exit 1
}

caddy_compose="$(sed -n '/^  caddy:/,/^networks:/p' "$compose_file")"
grep -Fq -- '- ./brand-assets:/srv/brand-assets:ro' <<<"$caddy_compose" || {
  printf 'Missing read-only Caddy branding asset mount.\n' >&2
  exit 1
}

for asset in logo.svg logo_dark.svg logo_thumbnail.png; do
  [[ -f "$deployment_dir/brand-assets/$asset" ]] || {
    printf 'Missing branding asset: %s\n' "$asset" >&2
    exit 1
  }
done

for wordmark in logo.svg logo_dark.svg; do
  asset_path="$deployment_dir/brand-assets/$wordmark"
  [[ "$(file --brief --mime-type "$asset_path")" == image/svg+xml ]] || {
    printf 'Unexpected MIME type for %s.\n' "$wordmark" >&2
    exit 1
  }
  grep -Eq '<svg([[:space:]>])' "$asset_path" || {
    printf 'Missing SVG root in %s.\n' "$wordmark" >&2
    exit 1
  }
  grep -Eq 'viewBox=' "$asset_path" || {
    printf 'Missing responsive viewBox in %s.\n' "$wordmark" >&2
    exit 1
  }
done

thumbnail="$deployment_dir/brand-assets/logo_thumbnail.png"
[[ "$(file --brief --mime-type "$thumbnail")" == image/png ]] || {
  printf 'Unexpected MIME type for logo_thumbnail.png.\n' >&2
  exit 1
}
file "$thumbnail" | grep -Eq 'PNG image data, 512 x 512,' || {
  printf 'logo_thumbnail.png must be a 512 x 512 PNG.\n' >&2
  exit 1
}

printf 'Branding proxy and asset contracts are valid.\n'
