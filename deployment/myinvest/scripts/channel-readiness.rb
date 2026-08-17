#!/usr/bin/env sh
set -eu

deployment_dir="$(cd "$(dirname "$0")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"

if [ ! -r "$env_path" ]; then
  printf 'Channel readiness environment is unavailable.\n' >&2
  exit 1
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/channel-readiness.XXXXXX")"
chmod 700 "$work_dir"
fixed_env="$work_dir/fixed.env"
readiness_env="$work_dir/readiness.env"
credential_names="$work_dir/credential-env-names"
cleanup() {
  rm -f "$fixed_env" "$readiness_env" "$credential_names"
  rmdir "$work_dir" 2>/dev/null || true
}
trap cleanup EXIT
trap 'cleanup; exit 1' HUP INT TERM
: > "$fixed_env"
chmod 600 "$fixed_env"

copy_env_assignment() {
  key="$1"
  required="$2"
  destination="$3"
  awk -v key="$key" -v required="$required" '
    index($0, key "=") == 1 { lines[++count] = $0 }
    END {
      if (count > 1 || (required == "true" && count != 1)) exit 1
      if (count == 1) print lines[1]
    }
  ' "$env_path" >> "$destination"
}

copy_env_assignment TENANTS_JSON true "$fixed_env" || {
  printf 'Channel readiness environment is invalid.\n' >&2
  exit 1
}
copy_env_assignment CHANNEL_READINESS_CONFIG_JSON true "$fixed_env" || {
  printf 'Channel readiness environment is invalid.\n' >&2
  exit 1
}

if ! docker compose \
  --project-directory "$deployment_dir" \
  --env-file "$env_path" \
  -f "$deployment_dir/compose.yaml" \
  run --rm --no-deps --env-from-file "$fixed_env" \
  --volume "$work_dir:/readiness-work" \
  --volume "$deployment_dir/scripts/cutover-whatsapp.rb:/scripts/cutover-whatsapp.rb:ro" rails \
  ruby -I/bootstrap -rlib/channel_readiness -e '
    names = Myinvest::ChannelReadiness::Builder.new(ENV).credential_env_names
    File.open("/readiness-work/credential-env-names", File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
      names.each { |name| file.puts(name) }
    end
  ' >/dev/null 2>&1; then
  printf 'Channel readiness manifest is invalid.\n' >&2
  exit 1
fi

cp "$fixed_env" "$readiness_env"
copy_env_assignment HUBSPOT_CUTOVER_CONFIRMED false "$readiness_env" || {
  printf 'Channel readiness environment is invalid.\n' >&2
  exit 1
}
while IFS= read -r credential_name; do
  copy_env_assignment "$credential_name" false "$readiness_env" || {
    printf 'Channel readiness environment is invalid.\n' >&2
    exit 1
  }
done < "$credential_names"
chmod 600 "$readiness_env"

docker compose \
  --project-directory "$deployment_dir" \
  --env-file "$env_path" \
  -f "$deployment_dir/compose.yaml" \
  run --rm --no-deps --env-from-file "$readiness_env" \
  --volume "$deployment_dir/scripts/cutover-whatsapp.rb:/scripts/cutover-whatsapp.rb:ro" rails \
  ruby -I/bootstrap -rjson -rlib/channel_readiness -e '
    report = Myinvest::ChannelReadiness::Builder.new(ENV).call
    $stdout.puts JSON.generate(report)
    Kernel.exit(report["status"] == "ready" ? 0 : 1)
  '
