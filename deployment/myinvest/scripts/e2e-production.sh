#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
compose=(docker compose --project-directory "$deployment_dir" --env-file "$env_path" -f "$deployment_dir/compose.yaml")

set -a
# shellcheck disable=SC1090
source "$env_path"
set +a

[[ "$LOCAL_SMOKE" != true ]] || {
  printf 'Production E2E refuses LOCAL_SMOKE=true.\n' >&2
  exit 1
}
[[ "${PRODUCTION_E2E_CONFIRMATION:-}" == "test:${CADDY_SITE_ADDRESS}" ]] || {
  printf 'Set PRODUCTION_E2E_CONFIRMATION=test:%s for this exact host.\n' "$CADDY_SITE_ADDRESS" >&2
  exit 1
}

context_path="$deployment_dir/runtime/e2e-production.json"
test_run_marker="production-e2e-$(date -u +%Y%m%dT%H%M%SZ)-$(openssl rand -hex 16)"
[[ "$test_run_marker" =~ ^production-e2e-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}$ ]] || {
  printf 'Could not create a valid Production E2E run marker.\n' >&2
  exit 1
}
test_source_id="$test_run_marker"
expected_account_id="$(jq -er '.[] | select(.key == "saas") | .accountId | select(type == "number")' "$deployment_dir/runtime/tenants.json")"
test_content='Die Produktionspfadprüfung beginnt im Testbereich unter Einstellungen.'
test_content_hash="$(printf '%s' "$test_content" | shasum -a 256 | awk '{print $1}')"
test_document_inserted=false
created_display_ids=()
retire_test_knowledge() {
  if [[ "$test_document_inserted" == true ]]; then
    # Variables intentionally expand inside the PostgreSQL container.
    # shellcheck disable=SC2016
    "${compose[@]}" exec -T -e E2E_SOURCE_ID="$test_source_id" postgres sh -ec \
      'PGPASSWORD="$CLAUDE_AGENT_DATABASE_PASSWORD" psql --quiet --set=ON_ERROR_STOP=1 --username "$CLAUDE_AGENT_DATABASE_USER" --dbname "$CLAUDE_AGENT_DATABASE" --set=source_id="$E2E_SOURCE_ID" <<SQL
UPDATE agent_knowledge_documents
SET active = false, publication_status = '\''retired'\'', updated_at = now()
WHERE tenant_key = '\''saas'\'' AND source_namespace = '\''production-e2e'\'' AND source_id = :'\''source_id'\'';
SQL' \
      >/dev/null
  fi
}
resolve_registered_recovery_conversations() {
  local registry_markers="$1"
  [[ "$registry_markers" =~ ^production-e2e-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}(,production-e2e-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32})*$ ]] || {
    printf 'Production E2E registry contains an invalid recovery marker.\n' >&2
    return 1
  }
  "${compose[@]}" exec -T -e E2E_ACCOUNT_ID="$expected_account_id" -e E2E_REGISTRY_MARKERS="$registry_markers" \
    rails bundle exec rails runner '
      account_id = Integer(ENV.fetch("E2E_ACCOUNT_ID"))
      markers = ENV.fetch("E2E_REGISTRY_MARKERS").split(",").uniq
      valid = /\Aproduction-e2e-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}\z/
      raise "invalid Production E2E registry marker" unless markers.any? && markers.all? { |marker| marker.match?(valid) }
      base = Conversation.where(account_id: account_id)
      recovery = base.where("custom_attributes ->> '\''myinvest_production_e2e_recovery'\'' IN (?)", markers)
      marked = base.where("additional_attributes ->> '\''myinvest_production_e2e_run'\'' IN (?)", markers)
      Conversation.where(id: recovery.select(:id)).or(Conversation.where(id: marked.select(:id))).distinct.find_each do |conversation|
        conversation.update!(status: :resolved, custom_attributes: conversation.custom_attributes.merge("myinvest_e2e_retired" => true))
      end
    ' >/dev/null
}
resolve_test_conversations() {
  local display_ids='' registry_count
  if (( ${#created_display_ids[@]} > 0 )); then
    display_ids="$(IFS=,; printf '%s' "${created_display_ids[*]}")"
    [[ "$display_ids" =~ ^[0-9]+(,[0-9]+)*$ ]] || {
      printf 'Production E2E recorded invalid display IDs.\n' >&2
      return 1
    }
  fi
  # The public recovery marker is trusted only when the same unpredictable
  # marker exists in the internal, tenant-bound Production E2E registry.
  # Variables intentionally expand inside the PostgreSQL container.
  # shellcheck disable=SC2016
  registry_count="$("${compose[@]}" exec -T -e E2E_SOURCE_ID="$test_run_marker" postgres sh -ec \
    'PGPASSWORD="$CLAUDE_AGENT_DATABASE_PASSWORD" psql --tuples-only --no-align --set=ON_ERROR_STOP=1 --username "$CLAUDE_AGENT_DATABASE_USER" --dbname "$CLAUDE_AGENT_DATABASE" --set=source_id="$E2E_SOURCE_ID" <<SQL
SELECT count(*)
FROM agent_knowledge_documents
WHERE tenant_key = '\''saas'\'' AND source_namespace = '\''production-e2e'\'' AND source_id = :'\''source_id'\'';
SQL')"
  [[ "$registry_count" == 1 ]] || {
    printf 'Production E2E recovery marker is missing from the internal registry.\n' >&2
    return 1
  }
  "${compose[@]}" exec -T \
    -e E2E_ACCOUNT_ID="$expected_account_id" -e E2E_RUN_MARKER="$test_run_marker" -e E2E_DISPLAY_IDS="$display_ids" \
    rails bundle exec rails runner '
    account_id = Integer(ENV.fetch("E2E_ACCOUNT_ID"))
    marker = ENV.fetch("E2E_RUN_MARKER")
    raise "invalid Production E2E marker" unless marker.match?(/\Aproduction-e2e-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}\z/)
    display_ids = ENV.fetch("E2E_DISPLAY_IDS").split(",").reject(&:empty?).map { |value| Integer(value, 10) }.uniq
    marked = Conversation.where(account_id: account_id).where("additional_attributes ->> '\''myinvest_production_e2e_run'\'' = ?", marker).to_a
    recovery = Conversation.where(account_id: account_id).where("custom_attributes ->> '\''myinvest_production_e2e_recovery'\'' = ?", marker).to_a
    exact = Conversation.where(account_id: account_id, display_id: display_ids).to_a
    raise "missing exact Production E2E conversation" unless exact.length == display_ids.length
    (marked + recovery + exact).uniq(&:id).each do |conversation|
      conversation.update!(status: :resolved, custom_attributes: conversation.custom_attributes.merge("myinvest_e2e_retired" => true))
    end
  ' >/dev/null
}
verify_no_active_test_artifacts() {
  local active_documents unresolved_conversations display_ids='' registry_output registry_markers_csv
  local registry_markers=()
  if (( ${#created_display_ids[@]} > 0 )); then
    display_ids="$(IFS=,; printf '%s' "${created_display_ids[*]}")"
    [[ "$display_ids" =~ ^[0-9]+(,[0-9]+)*$ ]] || return 1
  fi
  # Variables intentionally expand inside the PostgreSQL container.
  # shellcheck disable=SC2016
  active_documents="$("${compose[@]}" exec -T postgres sh -ec \
    'PGPASSWORD="$CLAUDE_AGENT_DATABASE_PASSWORD" psql --tuples-only --no-align --set=ON_ERROR_STOP=1 --username "$CLAUDE_AGENT_DATABASE_USER" --dbname "$CLAUDE_AGENT_DATABASE" --command="SELECT count(*) FROM agent_knowledge_documents WHERE source_namespace = '\''production-e2e'\'' AND (active = true OR publication_status <> '\''retired'\'')"')"
  # Variables intentionally expand inside the PostgreSQL container.
  # shellcheck disable=SC2016
  if ! registry_output="$("${compose[@]}" exec -T postgres sh -ec \
    'PGPASSWORD="$CLAUDE_AGENT_DATABASE_PASSWORD" psql --tuples-only --no-align --set=ON_ERROR_STOP=1 --username "$CLAUDE_AGENT_DATABASE_USER" --dbname "$CLAUDE_AGENT_DATABASE" --command="SELECT DISTINCT source_id FROM agent_knowledge_documents WHERE tenant_key = '\''saas'\'' AND source_namespace = '\''production-e2e'\'' AND source_id ~ '\''^production-e2e-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}$'\'' ORDER BY source_id"')"; then
    printf 'Could not verify the internal Production E2E registry.\n' >&2
    return 1
  fi
  while IFS= read -r registry_marker; do
    [[ -n "$registry_marker" ]] || continue
    [[ "$registry_marker" =~ ^production-e2e-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}$ ]] || return 1
    registry_markers+=("$registry_marker")
  done <<< "$registry_output"
  (( ${#registry_markers[@]} > 0 )) || return 1
  registry_markers_csv="$(IFS=,; printf '%s' "${registry_markers[*]}")"
  unresolved_conversations="$("${compose[@]}" exec -T \
    -e E2E_ACCOUNT_ID="$expected_account_id" -e E2E_DISPLAY_IDS="$display_ids" -e E2E_REGISTRY_MARKERS="$registry_markers_csv" \
    rails bundle exec rails runner '
    account_id = Integer(ENV.fetch("E2E_ACCOUNT_ID"))
    markers = ENV.fetch("E2E_REGISTRY_MARKERS").split(",").uniq
    valid = /\Aproduction-e2e-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}\z/
    raise "invalid Production E2E registry marker" unless markers.any? && markers.all? { |marker| marker.match?(valid) }
    display_ids = ENV.fetch("E2E_DISPLAY_IDS").split(",").reject(&:empty?).map { |value| Integer(value, 10) }.uniq
    marked = Conversation.where(account_id: account_id)
      .where("additional_attributes ->> '\''myinvest_production_e2e_run'\'' IN (?)", markers)
      .where.not(status: :resolved)
    recovery = Conversation.where(account_id: account_id)
      .where("custom_attributes ->> '\''myinvest_production_e2e_recovery'\'' IN (?)", markers)
      .where.not(status: :resolved)
    exact = Conversation.where(account_id: account_id, display_id: display_ids).where.not(status: :resolved)
    ids = marked.select(:id).or(recovery.select(:id)).or(exact.select(:id))
    print Conversation.where(id: ids).distinct.count
  ')"
  if [[ "$active_documents" != 0 || "$unresolved_conversations" != 0 ]]; then
    printf 'Production E2E cleanup verification failed (active_documents=%s unresolved_conversations=%s).\n' \
      "$active_documents" "$unresolved_conversations" >&2
    return 1
  fi
}
cleanup_production_e2e() {
  local original_status=$? cleanup_status=0
  trap - EXIT
  set +e
  resolve_test_conversations || cleanup_status=1
  retire_test_knowledge || cleanup_status=1
  if [[ -n "${e2e_runtime:-}" && -d "$e2e_runtime" ]]; then
    find "$e2e_runtime" -depth -delete || cleanup_status=1
  fi
  if (( original_status != 0 )); then
    exit "$original_status"
  fi
  exit "$cleanup_status"
}
trap cleanup_production_e2e EXIT

# A terminated prior run must never influence retrieval or leave a synthetic
# conversation open. Public recovery attributes are usable only after their
# unpredictable values have been loaded from the internal tenant registry.
prior_registry_markers=()
# Variables intentionally expand inside the PostgreSQL container.
# shellcheck disable=SC2016
if ! prior_registry_output="$("${compose[@]}" exec -T postgres sh -ec \
  'PGPASSWORD="$CLAUDE_AGENT_DATABASE_PASSWORD" psql --tuples-only --no-align --set=ON_ERROR_STOP=1 --username "$CLAUDE_AGENT_DATABASE_USER" --dbname "$CLAUDE_AGENT_DATABASE" --command="SELECT DISTINCT source_id FROM agent_knowledge_documents WHERE tenant_key = '\''saas'\'' AND source_namespace = '\''production-e2e'\'' AND source_id ~ '\''^production-e2e-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}$'\'' ORDER BY source_id"')"; then
  printf 'Could not read the internal Production E2E registry.\n' >&2
  exit 1
fi
while IFS= read -r registry_marker; do
  [[ -n "$registry_marker" ]] || continue
  [[ "$registry_marker" =~ ^production-e2e-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}$ ]] || {
    printf 'Production E2E registry returned an invalid marker.\n' >&2
    exit 1
  }
  prior_registry_markers+=("$registry_marker")
done <<< "$prior_registry_output"
if (( ${#prior_registry_markers[@]} > 0 )); then
  prior_registry_markers_csv="$(IFS=,; printf '%s' "${prior_registry_markers[*]}")"
  resolve_registered_recovery_conversations "$prior_registry_markers_csv"
fi

# Variables intentionally expand inside the PostgreSQL container.
# shellcheck disable=SC2016
"${compose[@]}" exec -T postgres sh -ec \
  'PGPASSWORD="$CLAUDE_AGENT_DATABASE_PASSWORD" psql --quiet --set=ON_ERROR_STOP=1 --username "$CLAUDE_AGENT_DATABASE_USER" --dbname "$CLAUDE_AGENT_DATABASE" --command="UPDATE agent_knowledge_documents SET active = false, publication_status = '\''retired'\'', updated_at = now() WHERE source_namespace = '\''production-e2e'\'' AND (active = true OR publication_status <> '\''retired'\'')"' \
  >/dev/null
# Variables intentionally expand inside the PostgreSQL container.
# shellcheck disable=SC2016
"${compose[@]}" exec -T \
  -e E2E_SOURCE_ID="$test_source_id" -e E2E_CONTENT="$test_content" -e E2E_CONTENT_HASH="$test_content_hash" \
  postgres sh -ec \
  'PGPASSWORD="$CLAUDE_AGENT_DATABASE_PASSWORD" psql --quiet --set=ON_ERROR_STOP=1 --username "$CLAUDE_AGENT_DATABASE_USER" --dbname "$CLAUDE_AGENT_DATABASE" --set=source_id="$E2E_SOURCE_ID" --set=content="$E2E_CONTENT" --set=content_hash="$E2E_CONTENT_HASH" <<SQL
INSERT INTO agent_knowledge_documents
  (tenant_key, source_namespace, source_id, title, content, metadata, content_hash,
   publication_status, active, ingest_batch_id)
VALUES
  ('\''saas'\'', '\''production-e2e'\'', :'\''source_id'\'', '\''Production E2E Knowledge'\'', :'\''content'\'',
   jsonb_build_object('\''synthetic'\'', true), :'\''content_hash'\'', '\''published'\'', true, :'\''source_id'\'')
ON CONFLICT (tenant_key, source_namespace, source_id, content_hash)
DO UPDATE SET publication_status = '\''published'\'', active = true, updated_at = now();
SQL' >/dev/null
test_document_inserted=true

"${compose[@]}" exec -T -e FRONTEND_URL -e LOCAL_SMOKE rails \
  bundle exec rails runner /bootstrap/e2e_production_path.rb >/dev/null

account_id="$(jq -r '.account_id' "$context_path")"
[[ "$account_id" == "$expected_account_id" ]] || {
  printf 'Production E2E account does not match the tenant registry.\n' >&2
  exit 1
}
website_token="$(jq -r '.website_token' "$context_path")"
external_base_url="${FRONTEND_URL%/}/api/v1/widget"
e2e_runtime="$(mktemp -d)"

create_external_widget_path() {
  local kind="$1"
  local content="$2"
  local marker="Production E2E ${kind} ${test_source_id}"
  local config_path="$e2e_runtime/${kind}-config.json"
  local conversation_path="$e2e_runtime/${kind}-conversation.json"

  curl --fail --silent --show-error --max-time 30 \
    --header 'content-type: application/json' \
    --data-binary "$(jq -cn --arg website_token "$website_token" '{website_token:$website_token}')" \
    "$external_base_url/config" > "$config_path"
  jq -e '
    (.website_channel_config | type == "object") and
    (.website_channel_config.auth_token | type == "string" and length > 0) and
    (.website_channel_config.website_token | type == "string" and length > 0) and
    (.contact | type == "object")
  ' "$config_path" >/dev/null || {
    printf 'External widget config response does not match the expected schema.\n' >&2
    return 1
  }
  local auth_token
  auth_token="$(jq -er '.website_channel_config.auth_token | select(type == "string" and length > 0)' "$config_path")"
  curl --fail --silent --show-error --max-time 30 \
    --header 'content-type: application/json' \
    --header "X-Auth-Token: $auth_token" \
    --data-binary "$(jq -cn \
      --arg website_token "$website_token" --arg marker "$marker" --arg content "$content" --arg recovery "$test_run_marker" \
      '{website_token:$website_token,contact:{name:$marker},message:{content:$content,referer_url:"https://support.myinvest-pro.de/production-e2e"},custom_attributes:{myinvest_production_e2e_recovery:$recovery}}')" \
    "$external_base_url/conversations" > "$conversation_path"
  jq -e --arg content "$content" '
    (.id | type == "number") and
    (.messages | type == "array") and
    ([.messages[] | select(.message_type == 0 and .content == $content and (.id | type == "number"))] | length == 1) and
    (.contact | type == "object")
  ' "$conversation_path" >/dev/null || {
    printf 'External widget conversation response does not match the expected schema.\n' >&2
    return 1
  }
  local display_id
  display_id="$(jq -er '.id | select(type == "number")' "$conversation_path")"
  # Record the exact account/display tuple before the server-marker write. The
  # EXIT trap can therefore resolve a conversation even if that write fails.
  created_display_ids+=("$display_id")
  "${compose[@]}" exec -T \
    -e E2E_ACCOUNT_ID="$account_id" -e E2E_DISPLAY_ID="$display_id" -e E2E_RUN_MARKER="$test_run_marker" \
    rails bundle exec rails runner '
      account_id = Integer(ENV.fetch("E2E_ACCOUNT_ID"))
      display_id = Integer(ENV.fetch("E2E_DISPLAY_ID"))
      marker = ENV.fetch("E2E_RUN_MARKER")
      raise "invalid Production E2E marker" unless marker.match?(/\Aproduction-e2e-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}\z/)
      conversation = Conversation.find_by!(account_id: account_id, display_id: display_id)
      conversation.update!(additional_attributes: conversation.additional_attributes.merge("myinvest_production_e2e_run" => marker))
    ' >/dev/null
  printf '%s' "$auth_token" > "$e2e_runtime/${kind}-auth-token"
  chmod 600 "$e2e_runtime/${kind}-auth-token" "$config_path" "$conversation_path"
}

handoff_content='Ich möchte mit einem Menschen sprechen.'
answer_content='Wo beginnt die Produktionspfadprüfung?'
create_external_widget_path handoff "$handoff_content"
create_external_widget_path answer "$answer_content"
conversation_display_id="$(jq -r '.id' "$e2e_runtime/handoff-conversation.json")"
message_id="$(jq -r --arg content "$handoff_content" '.messages[] | select(.message_type == 0 and .content == $content) | .id' "$e2e_runtime/handoff-conversation.json")"
answer_conversation_display_id="$(jq -r '.id' "$e2e_runtime/answer-conversation.json")"
answer_message_id="$(jq -r --arg content "$answer_content" '.messages[] | select(.message_type == 0 and .content == $content) | .id' "$e2e_runtime/answer-conversation.json")"
conversation_id="$("${compose[@]}" exec -T -e E2E_ACCOUNT_ID="$account_id" -e E2E_DISPLAY_ID="$conversation_display_id" rails bundle exec rails runner '
  print Conversation.find_by!(account_id: Integer(ENV.fetch("E2E_ACCOUNT_ID")), display_id: Integer(ENV.fetch("E2E_DISPLAY_ID"))).id
')"
answer_conversation_id="$("${compose[@]}" exec -T -e E2E_ACCOUNT_ID="$account_id" -e E2E_DISPLAY_ID="$answer_conversation_display_id" rails bundle exec rails runner '
  print Conversation.find_by!(account_id: Integer(ENV.fetch("E2E_ACCOUNT_ID")), display_id: Integer(ENV.fetch("E2E_DISPLAY_ID"))).id
')"
deadline=$((SECONDS + ${E2E_TIMEOUT_SECONDS:-120}))
until "${compose[@]}" exec -T -e E2E_CONVERSATION_ID="$conversation_id" rails bundle exec rails runner '
  conversation = Conversation.find(Integer(ENV.fetch("E2E_CONVERSATION_ID")))
  exit(conversation.open? ? 0 : 1)
' >/dev/null 2>&1; do
  (( SECONDS < deadline )) || {
    printf 'Timed out waiting for the production AgentBot handoff.\n' >&2
    exit 1
  }
  sleep 2
done

answer_auth_token="$(<"$e2e_runtime/answer-auth-token")"
public_answer_visible=false
while (( SECONDS < deadline )); do
  curl --fail --silent --show-error --max-time 20 --get \
    --header "X-Auth-Token: $answer_auth_token" \
    --data-urlencode "website_token=$website_token" \
    "$external_base_url/messages" > "$e2e_runtime/answer-messages.json"
  jq -e '(.payload | type == "array") and (.meta | type == "object")' \
    "$e2e_runtime/answer-messages.json" >/dev/null || {
    printf 'External widget messages response does not match the expected schema.\n' >&2
    exit 1
  }
  if jq -e --arg source_id "$test_source_id" \
    '[.payload[] | select(.message_type == 1 and (.content | type == "string") and (.content | contains("Quellen:")) and (.content | contains($source_id)))] | length == 1' \
    "$e2e_runtime/answer-messages.json" >/dev/null; then
    public_answer_visible=true
    break
  fi
  sleep 2
done
[[ "$public_answer_visible" == true ]] || {
  printf 'The sourced answer was not visible through the external website widget API.\n' >&2
  exit 1
}

ledger_rows="$("${compose[@]}" exec -T postgres sh -ec \
  "PGPASSWORD=\"\$CLAUDE_AGENT_DATABASE_PASSWORD\" psql --tuples-only --no-align --username \"\$CLAUDE_AGENT_DATABASE_USER\" --dbname \"\$CLAUDE_AGENT_DATABASE\" --command \"SELECT count(*) || ':' || min(status) FROM agent_delivery_ledger WHERE tenant_key = 'saas' AND message_id = $message_id\"")"
[[ "$ledger_rows" == "1:handed_off" ]] || {
  printf 'Production delivery ledger did not record exactly one handoff.\n' >&2
  exit 1
}

until "${compose[@]}" exec -T \
  -e E2E_CONVERSATION_ID="$answer_conversation_id" -e E2E_MESSAGE_ID="$answer_message_id" -e E2E_SOURCE_ID="$test_source_id" \
  rails bundle exec rails runner '
    conversation = Conversation.find(Integer(ENV.fetch("E2E_CONVERSATION_ID")))
    marker = ENV.fetch("E2E_MESSAGE_ID")
    source_id = ENV.fetch("E2E_SOURCE_ID")
    replies = conversation.messages.outgoing.select do |message|
      message.content_attributes["myinvest_agent_delivery_id"] == marker
    end
    exit(replies.one? && replies.first.content.include?("Quellen:") && replies.first.content.include?(source_id) ? 0 : 1)
  ' >/dev/null 2>&1; do
  (( SECONDS < deadline )) || {
    printf 'Timed out waiting for the production Claude answer.\n' >&2
    exit 1
  }
  sleep 2
done

answer_ledger="$("${compose[@]}" exec -T postgres sh -ec \
  "PGPASSWORD=\"\$CLAUDE_AGENT_DATABASE_PASSWORD\" psql --tuples-only --no-align --username \"\$CLAUDE_AGENT_DATABASE_USER\" --dbname \"\$CLAUDE_AGENT_DATABASE\" --command \"SELECT count(*) || ':' || min(status) FROM agent_delivery_ledger WHERE tenant_key = 'saas' AND message_id = $answer_message_id\"")"
[[ "$answer_ledger" == "1:replied" ]] || {
  printf 'Production delivery ledger did not record exactly one Claude reply.\n' >&2
  exit 1
}

event_created_at="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
payload="$(jq -cn \
  --arg created_at "$event_created_at" \
  --argjson account "$account_id" \
  --argjson conversation "$conversation_id" \
  --argjson message "$message_id" \
  '{event:"message_created",id:$message,created_at:$created_at,content:"Ich möchte mit einem Menschen sprechen.",message_type:"incoming",private:false,account:{id:$account},conversation:{id:$conversation}}')"
timestamp="$(date +%s)"
signature="$("${compose[@]}" exec -T \
  -e TENANT_KEY=saas -e TIMESTAMP="$timestamp" -e RAW_BODY="$payload" -e TENANTS_PATH=/bootstrap-output/tenants.json \
  rails ruby -rjson -ropenssl -e '
    tenant = JSON.parse(File.read(ENV.fetch("TENANTS_PATH"))).find { |entry| entry.fetch("key") == ENV.fetch("TENANT_KEY") }
    abort "tenant not found" unless tenant
    data = "#{ENV.fetch("TIMESTAMP")}.#{ENV.fetch("RAW_BODY")}"
    print "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", tenant.fetch("webhookSecret"), data)}"
  ')"
e2e_url="${FRONTEND_URL%/}/_agent/webhooks/chatwoot"
for suffix in first replay; do
  status="$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 20 \
    --header 'content-type: application/json' \
    --header "x-chatwoot-delivery: production-e2e-${message_id}-${suffix}" \
    --header "x-chatwoot-timestamp: $timestamp" \
    --header "x-chatwoot-signature: $signature" \
    --data-binary "$payload" "$e2e_url")"
  [[ "$status" == 202 ]] || {
    printf 'Expected signed production webhook status 202, got %s.\n' "$status" >&2
    exit 1
  }
done

academy_account_id="$(jq -r '.[] | select(.key == "new_academy") | .accountId' "$deployment_dir/runtime/tenants.json")"
cross_tenant_payload="$(jq -c --argjson account "$academy_account_id" '.account.id = $account' <<<"$payload")"
cross_tenant_status="$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 20 \
  --header 'content-type: application/json' \
  --header "x-chatwoot-delivery: production-e2e-${message_id}-cross" \
  --header "x-chatwoot-timestamp: $timestamp" \
  --header "x-chatwoot-signature: $signature" \
  --data-binary "$cross_tenant_payload" "$e2e_url")"
[[ "$cross_tenant_status" == 401 ]] || {
  printf 'Cross-tenant production signature was not rejected.\n' >&2
  exit 1
}

sleep 2
ledger_count="$("${compose[@]}" exec -T postgres sh -ec \
  "PGPASSWORD=\"\$CLAUDE_AGENT_DATABASE_PASSWORD\" psql --tuples-only --no-align --username \"\$CLAUDE_AGENT_DATABASE_USER\" --dbname \"\$CLAUDE_AGENT_DATABASE\" --command \"SELECT count(*) FROM agent_delivery_ledger WHERE tenant_key = 'saas' AND message_id = $message_id\"")"
[[ "$ledger_count" == "1" ]] || {
  printf 'Duplicate production delivery created extra ledger rows.\n' >&2
  exit 1
}

resolve_test_conversations
retire_test_knowledge
verify_no_active_test_artifacts
test_document_inserted=false
find "$e2e_runtime" -depth -delete
trap - EXIT

printf 'Production E2E passed: external website ingress, public AgentBot handoff, one externally visible sourced reply, HMAC, replay suppression, and tenant rejection.\n'
