#!/usr/bin/env sh
set -eu

deployment_dir="$(cd "$(dirname "$0")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"

if [ ! -r "$env_path" ]; then
  printf 'Channel readiness environment is unavailable.\n' >&2
  exit 1
fi

docker compose \
  --project-directory "$deployment_dir" \
  --env-file "$env_path" \
  -f "$deployment_dir/compose.yaml" \
  run --rm --no-deps --env-from-file "$env_path" \
  --volume "$deployment_dir/scripts/cutover-whatsapp.rb:/scripts/cutover-whatsapp.rb:ro" rails \
  ruby -I/bootstrap -rjson -rlib/channel_readiness -e '
    report = Myinvest::ChannelReadiness::Builder.new(ENV).call
    $stdout.puts JSON.generate(report)
    Kernel.exit(report["status"] == "ready" ? 0 : 1)
  '
