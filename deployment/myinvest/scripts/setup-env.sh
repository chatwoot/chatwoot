#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_path="$deployment_dir/.env.example"
env_path="${1:-$deployment_dir/.env}"

command -v openssl >/dev/null 2>&1 || {
  printf 'openssl is required\n' >&2
  exit 1
}

if [[ -e "$env_path" ]]; then
  if grep '__GENERATE' "$env_path" |
    grep -Ev '^(MINIO_ROOT_USER=__GENERATE_MINIO_ROOT_USER__|MINIO_ROOT_PASSWORD=__GENERATE_MINIO_ROOT_PASSWORD__|STORAGE_ACCESS_KEY_ID=__GENERATE_STORAGE_ACCESS_KEY_ID__|STORAGE_SECRET_ACCESS_KEY=__GENERATE_STORAGE_SECRET_ACCESS_KEY__)$' |
    grep -q .; then
    printf 'Refusing to use environment file with unknown unresolved placeholders: %s\n' "$env_path" >&2
    exit 1
  fi
  if ! grep -Eq '^IMPORT_ID_HMAC_KEY=.+$' "$env_path" ||
     ! grep -Eq '^MINIO_ROOT_USER=.+$' "$env_path" ||
     ! grep -Eq '^MINIO_ROOT_PASSWORD=.+$' "$env_path" ||
     ! grep -Eq '^STORAGE_ACCESS_KEY_ID=.+$' "$env_path" ||
     ! grep -Eq '^STORAGE_SECRET_ACCESS_KEY=.+$' "$env_path" ||
     grep -Eq '^(MINIO_ROOT_USER=__GENERATE_MINIO_ROOT_USER__|MINIO_ROOT_PASSWORD=__GENERATE_MINIO_ROOT_PASSWORD__|STORAGE_ACCESS_KEY_ID=__GENERATE_STORAGE_ACCESS_KEY_ID__|STORAGE_SECRET_ACCESS_KEY=__GENERATE_STORAGE_SECRET_ACCESS_KEY__)$' "$env_path"; then
    umask 077
    temporary_path="${env_path}.tmp.$$"
    trap 'rm -f -- "$temporary_path"' EXIT
    cp "$env_path" "$temporary_path"
    import_id_hmac_key="$(openssl rand -hex 32)"
    minio_root_user="root-$(openssl rand -hex 12)"
    minio_root_password="$(openssl rand -hex 32)"
    storage_access_key_id="app-$(openssl rand -hex 12)"
    storage_secret_access_key="$(openssl rand -hex 32)"
    sed -i.bak \
      -e "s|^IMPORT_ID_HMAC_KEY=$|IMPORT_ID_HMAC_KEY=$import_id_hmac_key|" \
      -e "s|^MINIO_ROOT_USER=__GENERATE_MINIO_ROOT_USER__$|MINIO_ROOT_USER=$minio_root_user|" \
      -e "s|^MINIO_ROOT_USER=$|MINIO_ROOT_USER=$minio_root_user|" \
      -e "s|^MINIO_ROOT_PASSWORD=__GENERATE_MINIO_ROOT_PASSWORD__$|MINIO_ROOT_PASSWORD=$minio_root_password|" \
      -e "s|^MINIO_ROOT_PASSWORD=$|MINIO_ROOT_PASSWORD=$minio_root_password|" \
      -e "s|^STORAGE_ACCESS_KEY_ID=__GENERATE_STORAGE_ACCESS_KEY_ID__$|STORAGE_ACCESS_KEY_ID=$storage_access_key_id|" \
      -e "s|^STORAGE_ACCESS_KEY_ID=$|STORAGE_ACCESS_KEY_ID=$storage_access_key_id|" \
      -e "s|^STORAGE_SECRET_ACCESS_KEY=__GENERATE_STORAGE_SECRET_ACCESS_KEY__$|STORAGE_SECRET_ACCESS_KEY=$storage_secret_access_key|" \
      -e "s|^STORAGE_SECRET_ACCESS_KEY=$|STORAGE_SECRET_ACCESS_KEY=$storage_secret_access_key|" \
      "$temporary_path"
    rm -f -- "${temporary_path}.bak"
    grep -Eq '^IMPORT_ID_HMAC_KEY=.+$' "$temporary_path" ||
      printf 'IMPORT_ID_HMAC_KEY=%s\n' "$import_id_hmac_key" >> "$temporary_path"
    grep -Eq '^MINIO_ROOT_USER=.+$' "$temporary_path" ||
      printf 'MINIO_ROOT_USER=%s\n' "$minio_root_user" >> "$temporary_path"
    grep -Eq '^MINIO_ROOT_PASSWORD=.+$' "$temporary_path" ||
      printf 'MINIO_ROOT_PASSWORD=%s\n' "$minio_root_password" >> "$temporary_path"
    grep -Eq '^STORAGE_ACCESS_KEY_ID=.+$' "$temporary_path" ||
      printf 'STORAGE_ACCESS_KEY_ID=%s\n' "$storage_access_key_id" >> "$temporary_path"
    grep -Eq '^STORAGE_SECRET_ACCESS_KEY=.+$' "$temporary_path" ||
      printf 'STORAGE_SECRET_ACCESS_KEY=%s\n' "$storage_secret_access_key" >> "$temporary_path"
    if grep -q '__GENERATE' "$temporary_path"; then
      printf 'Secret generation left unresolved placeholders\n' >&2
      exit 1
    fi
    mv "$temporary_path" "$env_path"
    chmod 600 "$env_path"
    trap - EXIT
    printf 'Added missing durable secrets without printing them: %s\n' "$env_path"
    exit 0
  fi
  printf 'Environment already exists; left unchanged: %s\n' "$env_path"
  exit 0
fi

umask 077
secret_key_base="$(openssl rand -hex 64)"
encryption_primary="$(openssl rand -hex 32)"
encryption_deterministic="$(openssl rand -hex 32)"
encryption_salt="$(openssl rand -hex 32)"
postgres_admin_password="$(openssl rand -hex 32)"
postgres_password="$(openssl rand -hex 32)"
redis_password="$(openssl rand -hex 32)"
claude_database_password="$(openssl rand -hex 32)"
admin_password="Mw-$(openssl rand -hex 18)!A7"
import_id_hmac_key="$(openssl rand -hex 32)"
minio_root_user="root-$(openssl rand -hex 12)"
minio_root_password="$(openssl rand -hex 32)"
storage_access_key_id="app-$(openssl rand -hex 12)"
storage_secret_access_key="$(openssl rand -hex 32)"
temporary_path="${env_path}.tmp.$$"
trap 'rm -f -- "$temporary_path"' EXIT

while IFS= read -r line || [[ -n "$line" ]]; do
  case "$line" in
    IMPORT_ID_HMAC_KEY=__GENERATE_IMPORT_ID_HMAC_KEY__) line="IMPORT_ID_HMAC_KEY=$import_id_hmac_key" ;;
    SECRET_KEY_BASE=__GENERATE__) line="SECRET_KEY_BASE=$secret_key_base" ;;
    ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=__GENERATE__) line="ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=$encryption_primary" ;;
    ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=__GENERATE__) line="ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=$encryption_deterministic" ;;
    ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=__GENERATE__) line="ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=$encryption_salt" ;;
    POSTGRES_ADMIN_PASSWORD=__GENERATE__) line="POSTGRES_ADMIN_PASSWORD=$postgres_admin_password" ;;
    POSTGRES_PASSWORD=__GENERATE__) line="POSTGRES_PASSWORD=$postgres_password" ;;
    REDIS_PASSWORD=__GENERATE__) line="REDIS_PASSWORD=$redis_password" ;;
    REDIS_URL=__GENERATE_REDIS_URL__) line="REDIS_URL=redis://:${redis_password}@redis:6379/0" ;;
    CLAUDE_AGENT_DATABASE_PASSWORD=__GENERATE__) line="CLAUDE_AGENT_DATABASE_PASSWORD=$claude_database_password" ;;
    CLAUDE_AGENT_DATABASE_URL=__GENERATE_CLAUDE_DATABASE_URL__) line="CLAUDE_AGENT_DATABASE_URL=postgresql://claude_agent:${claude_database_password}@postgres:5432/claude_agent" ;;
    CLAUDE_AGENT_REDIS_URL=__GENERATE_CLAUDE_REDIS_URL__) line="CLAUDE_AGENT_REDIS_URL=redis://:${redis_password}@redis:6379/1" ;;
    ADMIN_PASSWORD=__GENERATE_ADMIN_PASSWORD__) line="ADMIN_PASSWORD=$admin_password" ;;
    MINIO_ROOT_USER=__GENERATE_MINIO_ROOT_USER__) line="MINIO_ROOT_USER=$minio_root_user" ;;
    MINIO_ROOT_PASSWORD=__GENERATE_MINIO_ROOT_PASSWORD__) line="MINIO_ROOT_PASSWORD=$minio_root_password" ;;
    STORAGE_ACCESS_KEY_ID=__GENERATE_STORAGE_ACCESS_KEY_ID__) line="STORAGE_ACCESS_KEY_ID=$storage_access_key_id" ;;
    STORAGE_SECRET_ACCESS_KEY=__GENERATE_STORAGE_SECRET_ACCESS_KEY__) line="STORAGE_SECRET_ACCESS_KEY=$storage_secret_access_key" ;;
  esac
  printf '%s\n' "$line" >> "$temporary_path"
done < "$template_path"

if grep -q '__GENERATE' "$temporary_path"; then
  printf 'Secret generation left unresolved placeholders\n' >&2
  exit 1
fi

mv "$temporary_path" "$env_path"
chmod 600 "$env_path"
trap - EXIT
printf 'Created %s with mode 600; secret values were not printed.\n' "$env_path"
