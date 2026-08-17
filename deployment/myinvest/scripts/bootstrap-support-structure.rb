#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
mode="${1:-dry-run}"

if (( $# > 1 )) || [[ "$mode" != "dry-run" && "$mode" != "--apply" ]]; then
  printf 'Usage: bootstrap-support-structure.rb [--apply]\n' >&2
  exit 1
fi

apply=false
runner_mode=dry-run
if [[ "$mode" == "--apply" ]]; then
  apply=true
  runner_mode=apply
fi

export SUPPORT_ROSTERS_JSON="${SUPPORT_ROSTERS_JSON:-}"
export SUPPORT_STRUCTURE_CONFIRMATION="${SUPPORT_STRUCTURE_CONFIRMATION:-}"

command=(
  docker compose
  --project-directory "$deployment_dir"
  --env-file "$env_path"
  -f "$deployment_dir/compose.yaml"
  run --rm
  -e SUPPORT_STRUCTURE_RUN=true
  -e "SUPPORT_STRUCTURE_MODE=$runner_mode"
  -e SUPPORT_ROSTERS_JSON
)
if [[ "$apply" == true ]]; then
  command+=(-e SUPPORT_STRUCTURE_CONFIRMATION)
fi
command+=(rails bundle exec rails runner /bootstrap/support_structure.rb)

if ! "${command[@]}"; then
  printf '{"command":"support-structure","mode":"%s","status":"failed"}\n' "$runner_mode" >&2
  exit 1
fi
