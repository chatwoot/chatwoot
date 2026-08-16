#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
output_dir="${1:?Usage: export-neon-support-history.sh OUTPUT_DIRECTORY}"

[[ -n "${SOURCE_DATABASE_URL:-}" ]] || {
  printf 'SOURCE_DATABASE_URL must be supplied through the process environment.\n' >&2
  exit 1
}
[[ -f "$env_path" ]] || {
  printf 'Missing deployment environment: %s\n' "$env_path" >&2
  exit 1
}
if [[ -e "$output_dir" ]]; then
  printf 'Refusing to overwrite export directory: %s\n' "$output_dir" >&2
  exit 1
fi

mkdir -m 700 "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
compose=(docker compose --project-directory "$deployment_dir" --env-file "$env_path" -f "$deployment_dir/compose.yaml")

"${compose[@]}" run --rm --no-deps \
  -e SOURCE_DATABASE_URL \
  -e TENANT_KEY=new_academy \
  -e EXPORT_OUTPUT_DIR=/history-export \
  -v "$output_dir:/history-export" \
  rails bundle exec ruby /bootstrap/export_neon_support_history.rb

[[ -f "$output_dir/manifest.json" ]] || {
  printf 'Container export did not reach the host output directory: %s\n' "$output_dir" >&2
  exit 1
}
find "$output_dir" -type f -exec chmod 600 {} +
printf 'Encrypt or delete the restricted export directory after importing: %s\n' "$output_dir"
