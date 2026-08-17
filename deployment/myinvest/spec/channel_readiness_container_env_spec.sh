#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/channel-readiness-container-env.XXXXXX")"
compose_env="$work_dir/compose.env"
manifest_env="$work_dir/manifest.env"
readiness_env="$work_dir/readiness.env"

cleanup() {
  rm -f "$compose_env" "$manifest_env" "$readiness_env"
  rmdir "$work_dir" 2>/dev/null || true
}
trap cleanup EXIT
trap 'cleanup; exit 1' HUP INT TERM

cp "$deployment_dir/.env.example" "$compose_env"
cat >"$manifest_env" <<'ENV'
TENANTS_JSON=[]
CHANNEL_READINESS_CONFIG_JSON=[]
ENV
cat >"$readiness_env" <<'ENV'
TENANTS_JSON=[]
CHANNEL_READINESS_CONFIG_JSON=[]
CHANNEL_READINESS_ENCRYPTION_CONFIGURED=true
GOOGLE_OAUTH_CONFIGURED=true
HUBSPOT_CUTOVER_CONFIRMED=true
CHANNEL_READINESS_RUNTIME_CREDENTIAL=true
ENV
chmod 600 "$compose_env" "$manifest_env" "$readiness_env"

compose=(
  docker compose
  --project-directory "$deployment_dir"
  --env-file "$compose_env"
  -f "$deployment_dir/compose.yaml"
)

forbidden_env='forbidden = %w[
  ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
  ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT GOOGLE_OAUTH_CLIENT_ID GOOGLE_OAUTH_CLIENT_SECRET
  ADMIN_PASSWORD ANTHROPIC_API_KEY AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
  BACKUP_GPG_RECIPIENT CLAUDE_AGENT_DATABASE_PASSWORD CLAUDE_AGENT_DATABASE_URL CLAUDE_AGENT_REDIS_URL
  DATABASE_URL MINIO_ROOT_PASSWORD POSTGRES_ADMIN_PASSWORD POSTGRES_PASSWORD REDIS_PASSWORD REDIS_URL
  SECRET_KEY_BASE SMTP_PASSWORD SMTP_USERNAME STORAGE_ACCESS_KEY_ID STORAGE_SECRET_ACCESS_KEY
]
abort "Forbidden environment reached channel readiness container." if forbidden.any? { |name| ENV.key?(name) }'

"${compose[@]}" run --rm --no-deps --env-from-file "$manifest_env" channel-readiness \
  ruby -e "$forbidden_env
    readiness = ENV.keys.grep(/\ACHANNEL_READINESS_/).sort
    expected = %w[CHANNEL_READINESS_CONFIG_JSON]
    abort \"Unexpected readiness environment reached manifest container.\" unless readiness == expected
    abort \"Tenant mapping is unavailable.\" unless ENV.key?(\"TENANTS_JSON\")
    credentials = %w[
      ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
      ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT GOOGLE_OAUTH_CLIENT_ID GOOGLE_OAUTH_CLIENT_SECRET
      CHANNEL_READINESS_ENCRYPTION_CONFIGURED GOOGLE_OAUTH_CONFIGURED HUBSPOT_CUTOVER_CONFIRMED
    ]
    abort \"Credentials reached manifest container.\" if credentials.any? { |name| ENV.key?(name) }
  " >/dev/null

"${compose[@]}" run --rm --no-deps --env-from-file "$readiness_env" channel-readiness \
  ruby -e "$forbidden_env
    readiness = ENV.keys.grep(/\ACHANNEL_READINESS_/).sort
    expected = %w[
      CHANNEL_READINESS_CONFIG_JSON CHANNEL_READINESS_ENCRYPTION_CONFIGURED CHANNEL_READINESS_RUNTIME_CREDENTIAL
    ]
    abort \"Unexpected readiness environment reached assessment container.\" unless readiness == expected
    markers = %w[
      CHANNEL_READINESS_ENCRYPTION_CONFIGURED CHANNEL_READINESS_RUNTIME_CREDENTIAL GOOGLE_OAUTH_CONFIGURED
      HUBSPOT_CUTOVER_CONFIRMED
    ]
    abort \"Required readiness markers are unavailable.\" unless markers.all? { |name| ENV[name] == \"true\" }
    abort \"Tenant mapping is unavailable.\" unless ENV.key?(\"TENANTS_JSON\")
  " >/dev/null

printf 'Channel readiness container environment is isolated.\n'
