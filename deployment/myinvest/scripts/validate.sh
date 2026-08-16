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
CADDY_SITE_SCHEME="${CADDY_SITE_SCHEME:-https}"
INGRESS_MODE="${INGRESS_MODE:-direct}"
STORAGE_LOCAL_MINIO="${STORAGE_LOCAL_MINIO:-false}"
DIRECT_UPLOADS_ENABLED="${DIRECT_UPLOADS_ENABLED:-false}"

required=(
  CADDY_SITE_ADDRESS ACME_EMAIL BIND_ADDRESS FRONTEND_URL FORCE_SSL ENABLE_ACCOUNT_SIGNUP
  SAFE_FETCH_ALLOW_PRIVATE_NETWORK DISABLE_TELEMETRY ENABLE_PUSH_RELAY_SERVER
  ENABLE_RACK_ATTACK ENABLE_RACK_ATTACK_WIDGET_API RACK_ATTACK_LIMIT
  VIPS_BLOCK_UNTRUSTED LOCAL_SMOKE DIRECT_UPLOADS_ENABLED IMPORT_ID_HMAC_KEY SECRET_KEY_BASE
  ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
  ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT POSTGRES_ADMIN_USER
  POSTGRES_ADMIN_PASSWORD POSTGRES_DATABASE POSTGRES_USERNAME POSTGRES_PASSWORD
  REDIS_PASSWORD REDIS_URL CLAUDE_AGENT_DATABASE CLAUDE_AGENT_DATABASE_USER
  CLAUDE_AGENT_DATABASE_PASSWORD CLAUDE_AGENT_DATABASE_URL CLAUDE_AGENT_REDIS_URL
  TENANTS_JSON ANTHROPIC_PROVIDER ANTHROPIC_MODEL AWS_REGION BEDROCK_MODEL
  ALLOW_DIRECT_ANTHROPIC STORAGE_LOCAL_MINIO
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
  case "$INGRESS_MODE" in
    direct)
      [[ "$BIND_ADDRESS" == 0.0.0.0 && "$CADDY_SITE_SCHEME" == https ]] || {
        printf 'Direct production ingress requires BIND_ADDRESS=0.0.0.0 and CADDY_SITE_SCHEME=https.\n' >&2
        exit 1
      }
      ;;
    cloudflare_tunnel)
      if [[ "$CADDY_SITE_SCHEME" != http || "$BIND_ADDRESS" != 127.0.0.1 ]]; then
        printf 'Cloudflare Tunnel ingress requires a co-located connector with CADDY_SITE_SCHEME=http and BIND_ADDRESS=127.0.0.1.\n' >&2
        exit 1
      fi
      ;;
    *)
      printf 'Unsupported INGRESS_MODE: %s\n' "$INGRESS_MODE" >&2
      exit 1
      ;;
  esac
  [[ -z "${LOCAL_FAKE_CLAUDE_ANSWER:-}" ]] || {
    printf 'LOCAL_FAKE_CLAUDE_ANSWER is forbidden in production.\n' >&2
    exit 1
  }
  production_required=(
    SMTP_ADDRESS SMTP_USERNAME SMTP_PASSWORD MAILER_SENDER_EMAIL
    STORAGE_BUCKET_NAME STORAGE_ACCESS_KEY_ID STORAGE_SECRET_ACCESS_KEY
    STORAGE_REGION STORAGE_ENDPOINT BACKUP_GPG_RECIPIENT BACKUP_OFFSITE_REMOTE
  )
  for variable in "${production_required[@]}"; do
    if [[ -z "${!variable:-}" ]]; then
      printf 'Production variable is empty: %s\n' "$variable" >&2
      exit 1
    fi
  done
  [[ "$BACKUP_OFFSITE_REMOTE" =~ ^[A-Za-z0-9._-]+:.+ ]] || {
    printf 'BACKUP_OFFSITE_REMOTE must be an explicit rclone remote path.\n' >&2
    exit 1
  }
  [[ "$ACTIVE_STORAGE_SERVICE" == s3_compatible ]] || {
    printf 'Production requires ACTIVE_STORAGE_SERVICE=s3_compatible.\n' >&2
    exit 1
  }
  [[ "$STORAGE_LOCAL_MINIO" == true ]] || {
    printf 'The DGX production profile requires its versioned internal MinIO service.\n' >&2
    exit 1
  }
  [[ -n "${MINIO_ROOT_USER:-}" && -n "${MINIO_ROOT_PASSWORD:-}" ]] || {
    printf 'Local MinIO requires separate root credentials.\n' >&2
    exit 1
  }
  [[ "$STORAGE_ENDPOINT" == http://minio:9000 && "$STORAGE_FORCE_PATH_STYLE" == true &&
     "$DIRECT_UPLOADS_ENABLED" == false ]] || {
    printf 'Local MinIO requires the internal endpoint, path-style addressing, and proxied uploads.\n' >&2
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
  elif [[ "$ANTHROPIC_PROVIDER" == local ]]; then
    [[ "$ALLOW_DIRECT_ANTHROPIC" == false ]] || {
      printf 'Local provider must not enable direct Anthropic processing.\n' >&2
      exit 1
    }
    [[ "${LOCAL_LLM_BASE_URL:-}" == http://172.30.240.1:11434/v1 &&
       "${LOCAL_LLM_ALLOWED_HOSTS:-}" == 172.30.240.1 &&
       "${LOCAL_LLM_MODEL:-}" == qwen3:8b ]] || {
      printf 'Local provider must use the allowlisted Chatwoot Docker-bridge Ollama endpoint and pinned model.\n' >&2
      exit 1
    }
    if [[ ! "${LOCAL_LLM_TIMEOUT_MS:-}" =~ ^[0-9]+$ ]] ||
       (( LOCAL_LLM_TIMEOUT_MS < 1000 || LOCAL_LLM_TIMEOUT_MS > 120000 )); then
      printf 'LOCAL_LLM_TIMEOUT_MS must be between 1000 and 120000.\n' >&2
      exit 1
    fi
  else
    printf 'Unsupported ANTHROPIC_PROVIDER: %s\n' "$ANTHROPIC_PROVIDER" >&2
    exit 1
  fi
  [[ "$LOG_LEVEL" == error ]] || {
    printf 'Production requires LOG_LEVEL=error to keep customer payloads out of upstream retry logs.\n' >&2
    exit 1
  }
else
  [[ "$INGRESS_MODE" == direct && "$CADDY_SITE_SCHEME" == https ]] || {
    printf 'LOCAL_SMOKE requires direct HTTPS ingress.\n' >&2
    exit 1
  }
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
if [[ "$LOCAL_SMOKE" != true && ${#STORAGE_SECRET_ACCESS_KEY} -lt 32 ]]; then
  printf 'Secret is too short: STORAGE_SECRET_ACCESS_KEY\n' >&2
  exit 1
fi
if [[ "$LOCAL_SMOKE" != true && "$STORAGE_LOCAL_MINIO" == true && ${#MINIO_ROOT_PASSWORD} -lt 32 ]]; then
  printf 'Secret is too short: MINIO_ROOT_PASSWORD\n' >&2
  exit 1
fi

if [[ "$FRONTEND_URL" != https://* && "$FRONTEND_URL" != http://localhost* && "$FRONTEND_URL" != http://127.0.0.1* ]]; then
  printf 'FRONTEND_URL must use HTTPS outside local smoke tests.\n' >&2
  exit 1
fi

"${compose[@]}" config --quiet

rendered="$("${compose[@]}" config --format json)"
if command -v jq >/dev/null 2>&1; then
  if jq -e '.services.postgres.ports or .services.redis.ports or .services.minio.ports' <<<"$rendered" >/dev/null; then
    printf 'PostgreSQL, Redis, or MinIO unexpectedly exposes a host port.\n' >&2
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
    'rails|MINIO_ROOT_PASSWORD' \
    'rails|TENANTS_JSON' \
    'rails|ANTHROPIC_API_KEY' \
    'rails|LOCAL_LLM_BASE_URL' \
    'caddy|LOCAL_LLM_BASE_URL' \
    'caddy|STORAGE_SECRET_ACCESS_KEY' \
    'claude-agent|SECRET_KEY_BASE' \
    'claude-agent|POSTGRES_ADMIN_PASSWORD' \
    'claude-agent|MINIO_ROOT_PASSWORD' \
    'minio|STORAGE_SECRET_ACCESS_KEY'; do
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
minio|minio/minio:RELEASE.2025-09-07T16-13-09Z@sha256:9966a92a734f9411e32f4f41d7d9d826fcdc0f68c4e20b70295bd4e7c11f8a2f
minio-init|minio/mc:RELEASE.2025-08-13T08-35-41Z@sha256:37d109dddbbb2c95873f5fc81ac93f37023264770fc580a7564148892087b1b7
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
