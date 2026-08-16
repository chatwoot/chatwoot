#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repository_dir="$(cd "$deployment_dir/../.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
bundle_input="${1:?Usage: import-chat-history.sh BUNDLE_DIRECTORY}"
importer_dir="$repository_dir/integrations/myinvest-chat-import"

[[ -f "$env_path" ]] || {
  printf 'Missing deployment environment: %s\n' "$env_path" >&2
  exit 1
}
[[ -d "$bundle_input" && ! -L "$bundle_input" ]] || {
  printf 'Bundle must be a non-symlink directory.\n' >&2
  exit 1
}
bundle_dir="$(cd "$bundle_input" && pwd -P)"

set -a
# shellcheck disable=SC1090
source "$env_path"
set +a
[[ -n "${IMPORT_ID_HMAC_KEY:-}" ]] || {
  printf 'IMPORT_ID_HMAC_KEY is missing; run scripts/setup-env.sh.\n' >&2
  exit 1
}

ruby -I "$importer_dir/lib" -r myinvest_chat_import -e 'MyinvestChatImport::Bundle.load(ARGV.fetch(0))' "$bundle_dir"
tenant_key="$(jq -r '.tenant_key' "$bundle_dir/manifest.json")"
source_namespace="$(jq -r '.source_namespace' "$bundle_dir/manifest.json")"
expected_confirmation="import:${tenant_key}:${source_namespace}"
if [[ "${LOCAL_SMOKE:-false}" == true ]]; then
  expected_confirmation="local-${expected_confirmation}"
elif [[ "${CHAT_IMPORT_BACKUP_CONFIRMED:-}" != true ]]; then
  printf 'Production import requires a verified backup and CHAT_IMPORT_BACKUP_CONFIRMED=true.\n' >&2
  exit 1
fi
[[ "${CHAT_IMPORT_CONFIRMATION:-}" == "$expected_confirmation" ]] || {
  printf 'Set CHAT_IMPORT_CONFIRMATION=%s for this exact bundle.\n' "$expected_confirmation" >&2
  exit 1
}

export CHAT_IMPORT_HMAC_KEY="$IMPORT_ID_HMAC_KEY"
export PGPASSWORD="$POSTGRES_ADMIN_PASSWORD"
compose=(docker compose --project-directory "$deployment_dir" --env-file "$env_path" -f "$deployment_dir/compose.yaml")
runner=("${compose[@]}" run --rm --no-deps -e CHAT_IMPORT_HMAC_KEY
  -v "$importer_dir:/myinvest-chat-import:ro"
  -v "$bundle_dir:/history-bundle:ro"
  rails bundle exec rails runner)

knowledge_before="$("${compose[@]}" exec -T -e PGPASSWORD postgres psql -U "$POSTGRES_ADMIN_USER" -d "$CLAUDE_AGENT_DATABASE" -Atc \
  'SELECT count(*) FROM agent_knowledge_documents')"
first_result="$("${runner[@]}" /myinvest-chat-import/bin/import.rb /history-bundle | tail -n 1)"
second_result="$("${runner[@]}" /myinvest-chat-import/bin/import.rb /history-bundle | tail -n 1)"
verification="$("${runner[@]}" /myinvest-chat-import/bin/verify.rb /history-bundle | tail -n 1)"
knowledge_after="$("${compose[@]}" exec -T -e PGPASSWORD postgres psql -U "$POSTGRES_ADMIN_USER" -d "$CLAUDE_AGENT_DATABASE" -Atc \
  'SELECT count(*) FROM agent_knowledge_documents')"

jq -e '.event == "history_import_completed" and ([.counts[].created + .counts[].reused] | all(. >= 0))' <<<"$first_result" >/dev/null
jq -e '.event == "history_import_completed" and ([.counts[].created] | all(. == 0))' <<<"$second_result" >/dev/null
jq -e '.event == "history_import_verified" and .knowledge_import == false and .inbox_safe == true' <<<"$verification" >/dev/null
[[ "$knowledge_before" == "$knowledge_after" ]] || {
  printf 'Knowledge store changed during history import.\n' >&2
  exit 1
}

printf '%s\n' "$first_result" "$second_result" "$verification"
printf '{"event":"knowledge_store_unchanged","documents":%s}\n' "$knowledge_after"
