#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
compose=(docker compose --project-directory "$deployment_dir" --env-file "$env_path" -f "$deployment_dir/compose.yaml")

[[ -f "$env_path" ]] || {
  printf 'Missing %s; run scripts/setup-env.sh first.\n' "$env_path" >&2
  exit 1
}

if grep -q '__GENERATE' "$env_path"; then
  printf 'Environment contains unresolved placeholders.\n' >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$env_path"
set +a

required=(
  CADDY_SITE_ADDRESS ACME_EMAIL BIND_ADDRESS FRONTEND_URL FORCE_SSL ENABLE_ACCOUNT_SIGNUP
  SAFE_FETCH_ALLOW_PRIVATE_NETWORK DISABLE_TELEMETRY ENABLE_PUSH_RELAY_SERVER
  ENABLE_RACK_ATTACK ENABLE_RACK_ATTACK_WIDGET_API RACK_ATTACK_LIMIT
  VIPS_BLOCK_UNTRUSTED LOCAL_SMOKE IMPORT_ID_HMAC_KEY SECRET_KEY_BASE
  ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
  ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT POSTGRES_ADMIN_USER
  POSTGRES_ADMIN_PASSWORD POSTGRES_DATABASE POSTGRES_USERNAME POSTGRES_PASSWORD
  REDIS_PASSWORD REDIS_URL CLAUDE_AGENT_DATABASE CLAUDE_AGENT_DATABASE_USER
  CLAUDE_AGENT_DATABASE_PASSWORD CLAUDE_AGENT_DATABASE_URL CLAUDE_AGENT_REDIS_URL
  TENANTS_JSON ANTHROPIC_PROVIDER ANTHROPIC_MODEL AWS_REGION BEDROCK_MODEL
  ALLOW_DIRECT_ANTHROPIC
  WEBHOOK_REPLAY_WINDOW_SECONDS DELIVERY_RETENTION_SECONDS MAX_BODY_BYTES
  KNOWLEDGE_MIN_SCORE KNOWLEDGE_MAX_SOURCES
  ADMIN_NAME ADMIN_EMAIL MYINVEST_ACCOUNT_NAME
  ACADEMY_NEW_ACCOUNT_NAME ACADEMY_LEGACY_ACCOUNT_NAME MYINVEST_WEBSITE_URL
  ACADEMY_NEW_WEBSITE_URL ACADEMY_LEGACY_WEBSITE_URL
)
for variable in "${required[@]}"; do
  if [[ -z "${!variable:-}" ]]; then
    printf 'Required variable is empty: %s\n' "$variable" >&2
    exit 1
  fi
done

while IFS='|' read -r variable expected; do
  if [[ "${!variable}" != "$expected" ]]; then
    printf 'Unsafe policy value for %s: expected %s\n' "$variable" "$expected" >&2
    exit 1
  fi
done <<'POLICIES'
FORCE_SSL|true
ENABLE_ACCOUNT_SIGNUP|false
SAFE_FETCH_ALLOW_PRIVATE_NETWORK|false
DISABLE_TELEMETRY|true
ENABLE_PUSH_RELAY_SERVER|false
ENABLE_RACK_ATTACK|true
ENABLE_RACK_ATTACK_WIDGET_API|true
VIPS_BLOCK_UNTRUSTED|1
POLICIES

if [[ "$LOCAL_SMOKE" != true ]]; then
  [[ "$BIND_ADDRESS" == 0.0.0.0 ]] || {
    printf 'Production requires BIND_ADDRESS=0.0.0.0.\n' >&2
    exit 1
  }
  [[ -z "${LOCAL_FAKE_CLAUDE_ANSWER:-}" ]] || {
    printf 'LOCAL_FAKE_CLAUDE_ANSWER is forbidden in production.\n' >&2
    exit 1
  }
  production_required=(
    SMTP_ADDRESS SMTP_USERNAME SMTP_PASSWORD MAILER_SENDER_EMAIL
    STORAGE_BUCKET_NAME STORAGE_ACCESS_KEY_ID STORAGE_SECRET_ACCESS_KEY
    STORAGE_REGION STORAGE_ENDPOINT BACKUP_GPG_RECIPIENT
  )
  for variable in "${production_required[@]}"; do
    if [[ -z "${!variable:-}" ]]; then
      printf 'Production variable is empty: %s\n' "$variable" >&2
      exit 1
    fi
  done
  [[ "$ACTIVE_STORAGE_SERVICE" == s3_compatible ]] || {
    printf 'Production requires ACTIVE_STORAGE_SERVICE=s3_compatible.\n' >&2
    exit 1
  }
  [[ "$STORAGE_ENDPOINT" == https://* ]] || {
    printf 'Production object storage endpoint must use HTTPS.\n' >&2
    exit 1
  }
  [[ "$FRONTEND_URL" == "https://$CADDY_SITE_ADDRESS" ]] || {
    printf 'Production FRONTEND_URL must match CADDY_SITE_ADDRESS.\n' >&2
    exit 1
  }
  if [[ "$ANTHROPIC_PROVIDER" == bedrock ]]; then
    [[ -n "${AWS_ACCESS_KEY_ID:-}" && -n "${AWS_SECRET_ACCESS_KEY:-}" ]] || {
      printf 'Bedrock requires least-privilege AWS credentials.\n' >&2
      exit 1
    }
    [[ "$AWS_REGION" == eu-* && "$BEDROCK_MODEL" == eu.* ]] || {
      printf 'Bedrock production requires an EU region and EU inference profile.\n' >&2
      exit 1
    }
  elif [[ "$ANTHROPIC_PROVIDER" == direct ]]; then
    [[ -n "${ANTHROPIC_API_KEY:-}" ]] || {
      printf 'Direct Anthropic requires ANTHROPIC_API_KEY.\n' >&2
      exit 1
    }
    [[ "$ALLOW_DIRECT_ANTHROPIC" == true ]] || {
      printf 'Direct Anthropic requires an explicit completed processing-region review.\n' >&2
      exit 1
    }
  else
    printf 'Unsupported ANTHROPIC_PROVIDER: %s\n' "$ANTHROPIC_PROVIDER" >&2
    exit 1
  fi
  [[ "$LOG_LEVEL" == error ]] || {
    printf 'Production requires LOG_LEVEL=error to keep customer payloads out of upstream retry logs.\n' >&2
    exit 1
  }
else
  [[ -n "${LOCAL_FAKE_CLAUDE_ANSWER:-}" ]] || {
    printf 'LOCAL_SMOKE requires a deterministic local Claude answer for E2E.\n' >&2
    exit 1
  }
  [[ "$CADDY_SITE_ADDRESS" == localhost ]] || {
    printf 'LOCAL_SMOKE requires CADDY_SITE_ADDRESS=localhost.\n' >&2
    exit 1
  }
  [[ "$BIND_ADDRESS" == 127.0.0.1 ]] || {
    printf 'LOCAL_SMOKE must bind published ports to 127.0.0.1.\n' >&2
    exit 1
  }
  [[ "$FRONTEND_URL" == "https://localhost:$HTTPS_PORT" ]] || {
    printf 'LOCAL_SMOKE requires the configured localhost HTTPS port.\n' >&2
    exit 1
  }
  for port in "$HTTP_PORT" "$HTTPS_PORT"; do
    if [[ ! "$port" =~ ^[0-9]+$ ]] || (( port < 1024 || port > 65535 )); then
      printf 'LOCAL_SMOKE requires non-privileged local ports.\n' >&2
      exit 1
    fi
  done
fi

if command -v jq >/dev/null 2>&1 && ! jq -e 'type == "array"' >/dev/null <<<"$TENANTS_JSON"; then
  printf 'TENANTS_JSON must be a JSON array.\n' >&2
  exit 1
fi

for variable in POSTGRES_ADMIN_USER POSTGRES_DATABASE POSTGRES_USERNAME CLAUDE_AGENT_DATABASE CLAUDE_AGENT_DATABASE_USER; do
  if [[ ! "${!variable}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    printf 'Invalid PostgreSQL identifier: %s\n' "$variable" >&2
    exit 1
  fi
done

for variable in IMPORT_ID_HMAC_KEY SECRET_KEY_BASE POSTGRES_ADMIN_PASSWORD POSTGRES_PASSWORD REDIS_PASSWORD CLAUDE_AGENT_DATABASE_PASSWORD; do
  value="${!variable}"
  if (( ${#value} < 32 )); then
    printf 'Secret is too short: %s\n' "$variable" >&2
    exit 1
  fi
done

if [[ "$FRONTEND_URL" != https://* && "$FRONTEND_URL" != http://localhost* && "$FRONTEND_URL" != http://127.0.0.1* ]]; then
  printf 'FRONTEND_URL must use HTTPS outside local smoke tests.\n' >&2
  exit 1
fi

"${compose[@]}" config --quiet

rendered="$("${compose[@]}" config --format json)"
if command -v jq >/dev/null 2>&1; then
  if jq -e '.services.postgres.ports or .services.redis.ports' <<<"$rendered" >/dev/null; then
    printf 'PostgreSQL or Redis unexpectedly exposes a host port.\n' >&2
    exit 1
  fi
  if ! jq -e --arg bind "$BIND_ADDRESS" '.services.caddy.ports | all(.host_ip == $bind)' <<<"$rendered" >/dev/null; then
    printf 'Caddy published-port binding does not match BIND_ADDRESS.\n' >&2
    exit 1
  fi
  for assertion in \
    'caddy|SECRET_KEY_BASE' \
    'redis|SECRET_KEY_BASE' \
    'postgres|SECRET_KEY_BASE' \
    'rails|POSTGRES_ADMIN_PASSWORD' \
    'rails|TENANTS_JSON' \
    'rails|ANTHROPIC_API_KEY' \
    'claude-agent|SECRET_KEY_BASE' \
    'claude-agent|POSTGRES_ADMIN_PASSWORD'; do
    service="${assertion%%|*}"
    forbidden="${assertion#*|}"
    if jq -e --arg service "$service" --arg forbidden "$forbidden" '.services[$service].environment[$forbidden] != null' <<<"$rendered" >/dev/null; then
      printf 'Secret boundary violation: %s received %s\n' "$service" "$forbidden" >&2
      exit 1
    fi
  done
  while IFS='|' read -r service expected_image; do
    pinned_image="$(jq -r --arg service "$service" '.services[$service].image' <<<"$rendered")"
    [[ "$pinned_image" == "$expected_image" ]] || {
      printf 'Unexpected image for %s: %s\n' "$service" "$pinned_image" >&2
      exit 1
    }
  done <<'IMAGES'
rails|chatwoot/chatwoot:v4.16.2@sha256:f9b071ffe678031ee6d51bf591ddd4336b80c3edfb3105e38e46afd32b8211b2
postgres|pgvector/pgvector:pg16@sha256:ccc6e83d6e35e931dc7c5def2022729d5a6c370318d099181995567ff1fb4d6b
redis|redis:7.4-alpine@sha256:e7723ff73d963f5cc6d9c4643ea3d989527a402a319239054e9472a7fb9219a2
caddy|caddy:2.10.2-alpine@sha256:4c6e91c6ed0e2fa03efd5b44747b625fec79bc9cd06ac5235a779726618e530d
IMAGES
  for service in rails sidekiq; do
    initializer_source="$(jq -r --arg service "$service" '.services[$service].volumes[] | select(.target == "/app/config/initializers/myinvest_security.rb") | .source' <<<"$rendered")"
    [[ "$initializer_source" == "$deployment_dir/chatwoot-initializers/myinvest_security.rb" ]] || {
      printf 'Security initializer is not mounted into %s.\n' "$service" >&2
      exit 1
    }
  done
fi

docker run --rm \
  -e CADDY_SITE_ADDRESS=localhost \
  -e ACME_EMAIL=ops@example.invalid \
  -v "$deployment_dir/Caddyfile:/etc/caddy/Caddyfile:ro" \
  caddy:2.10.2-alpine@sha256:4c6e91c6ed0e2fa03efd5b44747b625fec79bc9cd06ac5235a779726618e530d \
  caddy validate --config /etc/caddy/Caddyfile >/dev/null

for helper in "$deployment_dir/scripts/backup.sh" "$deployment_dir/scripts/restore.sh"; do
  grep -q 'alpine:3.21@sha256:48b0309ca019d89d40f670aa1bc06e426dc0931948452e8491e3d65087abc07d' "$helper" || {
    printf 'Unpinned Alpine helper image in %s\n' "$helper" >&2
    exit 1
  }
done
grep -q 'node:22.19.0-alpine3.22@sha256:d2166de198f26e17e5a442f537754dd616ab069c47cc57b889310a717e0abbf9' \
  "$deployment_dir/../../integrations/myinvest-claude-agent/Dockerfile" || {
    printf 'Claude agent base image is not digest-pinned.\n' >&2
    exit 1
  }

printf 'Deployment configuration is valid.\n'
