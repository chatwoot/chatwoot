#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
compose=(docker compose --project-directory "$deployment_dir" --env-file "$env_path" -f "$deployment_dir/compose.yaml")

"$deployment_dir/scripts/validate.sh"
set -a
# shellcheck disable=SC1090
source "$env_path"
set +a
bootstrap_environment=(
  -e ADMIN_NAME -e ADMIN_EMAIL -e ADMIN_PASSWORD
  -e MYINVEST_ACCOUNT_NAME -e ACADEMY_NEW_ACCOUNT_NAME -e ACADEMY_LEGACY_ACCOUNT_NAME
  -e MYINVEST_WEBSITE_URL -e ACADEMY_NEW_WEBSITE_URL -e ACADEMY_LEGACY_WEBSITE_URL
)
"${compose[@]}" run --rm "${bootstrap_environment[@]}" rails bundle exec rails runner /bootstrap/seed.rb
"$deployment_dir/scripts/render-tenants-env.rb" "$deployment_dir/runtime/tenants.json" "$env_path"
"${compose[@]}" up -d --build --force-recreate claude-agent
printf 'Three account boundaries, website inboxes, scoped Agent Bots, and the Claude agent are present.\n'
