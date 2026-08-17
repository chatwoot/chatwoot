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

assignment_state() {
  key="$1"
  awk -v key="$key" '
    index($0, key "=") == 1 {
      count++
      value = substr($0, length(key) + 2)
      sub(/\r$/, "", value)
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      quote = sprintf("%c", 39)
      if ((substr(value, 1, 1) == "\"" && substr(value, length(value), 1) == "\"") ||
          (substr(value, 1, 1) == quote && substr(value, length(value), 1) == quote)) {
        value = substr(value, 2, length(value) - 2)
        sub(/^[[:space:]]+/, "", value)
        sub(/[[:space:]]+$/, "", value)
      } else {
        sub(/[[:space:]]+#.*$/, "", value)
      }
      configured = length(value) > 0
    }
    END {
      if (count > 1) exit 2
      if (count == 1 && configured) exit 0
      exit 1
    }
  ' "$env_path"
}

append_presence_marker() {
  key="$1"
  destination="$2"
  state=0
  assignment_state "$key" || state=$?
  if [ "$state" -eq 0 ]; then
    printf '%s=true\n' "$key" >> "$destination"
  elif [ "$state" -eq 2 ]; then
    return 1
  fi
}

invalid_environment() {
  printf 'Channel readiness environment is invalid.\n' >&2
  exit 1
}

copy_env_assignment TENANTS_JSON true "$fixed_env" || {
  invalid_environment
}
copy_env_assignment CHANNEL_READINESS_CONFIG_JSON true "$fixed_env" || {
  invalid_environment
}

cp "$fixed_env" "$readiness_env"
for encryption_name in \
  ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY \
  ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY \
  ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT; do
  encryption_state=0
  assignment_state "$encryption_name" || encryption_state=$?
  [ "$encryption_state" -eq 0 ] || invalid_environment
done
printf '%s=true\n' CHANNEL_READINESS_ENCRYPTION_CONFIGURED >> "$readiness_env"

google_client_state=0
google_secret_state=0
assignment_state GOOGLE_OAUTH_CLIENT_ID || google_client_state=$?
assignment_state GOOGLE_OAUTH_CLIENT_SECRET || google_secret_state=$?
case "$google_client_state:$google_secret_state" in
  0:0) printf '%s=true\n' GOOGLE_OAUTH_CONFIGURED >> "$readiness_env" ;;
  1:1) ;;
  *) invalid_environment ;;
esac

copy_env_assignment HUBSPOT_CUTOVER_CONFIRMED false "$readiness_env" || {
  invalid_environment
}

if ! docker compose \
  --project-directory "$deployment_dir" \
  --env-file "$env_path" \
  -f "$deployment_dir/compose.yaml" \
  run --rm --no-deps --user "$(id -u):$(id -g)" --env-from-file "$fixed_env" \
  --volume "$work_dir:/readiness-work" \
  channel-readiness \
  ruby -I/bootstrap -rlib/channel_readiness -e '
    names = Myinvest::ChannelReadiness::Builder.new(ENV).credential_env_names
    File.open("/readiness-work/credential-env-names", File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
      names.each { |name| file.puts(name) }
    end
  ' >/dev/null 2>&1; then
  printf 'Channel readiness manifest is invalid.\n' >&2
  exit 1
fi

while IFS= read -r credential_name; do
  append_presence_marker "$credential_name" "$readiness_env" || {
    invalid_environment
  }
done < "$credential_names"
chmod 600 "$readiness_env"

docker compose \
  --project-directory "$deployment_dir" \
  --env-file "$env_path" \
  -f "$deployment_dir/compose.yaml" \
  run --rm --no-deps --user "$(id -u):$(id -g)" --env-from-file "$readiness_env" \
  channel-readiness \
  ruby -I/bootstrap -rjson -rlib/channel_readiness -e '
    report = Myinvest::ChannelReadiness::Builder.new(ENV).call
    $stdout.puts JSON.generate(report)
    Kernel.exit(report["status"] == "ready" ? 0 : 1)
  '
