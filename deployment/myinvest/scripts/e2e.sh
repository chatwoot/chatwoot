#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
compose=(docker compose --project-directory "$deployment_dir" --env-file "$env_path" -f "$deployment_dir/compose.yaml")

set -a
# shellcheck disable=SC1090
source "$env_path"
set +a
[[ "$LOCAL_SMOKE" == true ]] || {
  printf 'The synthetic E2E test is restricted to LOCAL_SMOKE=true.\n' >&2
  exit 1
}

context_path="$deployment_dir/runtime/e2e.json"
"${compose[@]}" exec -T rails bundle exec rails runner '
  require "fileutils"
  require "json"
  require "securerandom"
  account = Account.where("custom_attributes ->> ? = ?", "myinvest_tenant_key", "saas").first!
  inbox = account.inboxes.find_by!(name: "#{account.name} Website")
  contact = account.contacts.create!(name: "Local E2E #{SecureRandom.hex(4)}")
  contact_inbox = ContactInbox.create!(
    contact: contact, inbox: inbox, source_id: SecureRandom.uuid
  )
  conversation = Conversation.create!(
    account: account, contact: contact, contact_inbox: contact_inbox,
    inbox: inbox, status: :pending
  )
  context = {
    account_id: account.id,
    conversation_record_id: conversation.id,
    conversation_id: conversation.display_id,
    message_id: 1_000_000_000 + SecureRandom.random_number(1_000_000_000)
  }
  path = "/bootstrap-output/e2e.json"
  File.write(path, JSON.generate(context), mode: "w", perm: 0o600)
  File.chmod(0o600, path)
'

account_id="$(jq -r '.account_id' "$context_path")"
conversation_record_id="$(jq -r '.conversation_record_id' "$context_path")"
conversation_id="$(jq -r '.conversation_id' "$context_path")"
message_id="$(jq -r '.message_id' "$context_path")"
"${compose[@]}" exec -T \
  -e E2E_CONVERSATION_RECORD_ID="$conversation_record_id" -e E2E_CONVERSATION_DISPLAY_ID="$conversation_id" \
  rails bundle exec rails runner '
    conversation = Conversation.find(Integer(ENV.fetch("E2E_CONVERSATION_RECORD_ID")))
    expected_display_id = Integer(ENV.fetch("E2E_CONVERSATION_DISPLAY_ID"))
    raise "E2E public conversation identifier drifted from display_id" unless conversation.display_id == expected_display_id
  ' >/dev/null
event_created_at="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
payload="$(jq -cn \
  --arg created_at "$event_created_at" \
  --argjson account "$account_id" \
  --argjson conversation "$conversation_id" \
  --argjson message "$message_id" \
  '{event:"message_created",id:$message,created_at:$created_at,content:"Ich möchte mit einem Menschen sprechen.",message_type:"incoming",private:false,account:{id:$account},conversation:{id:$conversation}}')"
timestamp="$(date +%s)"
delivery_id="local-e2e-${message_id}"
signature="$(TENANT_KEY=saas TIMESTAMP="$timestamp" RAW_BODY="$payload" TENANTS_PATH="$deployment_dir/runtime/tenants.json" \
  ruby -rjson -ropenssl -e '
    tenant = JSON.parse(File.read(ENV.fetch("TENANTS_PATH"))).find { |entry| entry.fetch("key") == ENV.fetch("TENANT_KEY") }
    abort "tenant not found" unless tenant
    data = "#{ENV.fetch("TIMESTAMP")}.#{ENV.fetch("RAW_BODY")}"
    print "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", tenant.fetch("webhookSecret"), data)}"
  ')"

e2e_url="https://localhost:${HTTPS_PORT:-443}/_agent/webhooks/chatwoot"
for _ in 1 2; do
  status="$(curl --insecure --silent --output /dev/null --write-out '%{http_code}' \
    --header 'content-type: application/json' \
    --header "x-chatwoot-delivery: $delivery_id" \
    --header "x-chatwoot-timestamp: $timestamp" \
    --header "x-chatwoot-signature: $signature" \
    --data-binary "$payload" "$e2e_url")"
  [[ "$status" == 202 ]] || {
    printf 'Expected signed webhook status 202, got %s.\n' "$status" >&2
    exit 1
  }
done

deadline=$((SECONDS + 60))
until "${compose[@]}" exec -T \
  -e E2E_CONVERSATION_RECORD_ID="$conversation_record_id" \
  rails bundle exec rails runner '
    conversation = Conversation.find(Integer(ENV.fetch("E2E_CONVERSATION_RECORD_ID")))
    exit(conversation.open? ? 0 : 1)
  ' >/dev/null 2>&1; do
  (( SECONDS < deadline )) || {
    printf 'Timed out waiting for the handoff result.\n' >&2
    exit 1
  }
  sleep 2
done

ledger_rows="$("${compose[@]}" exec -T postgres sh -ec \
  "PGPASSWORD=\"\$CLAUDE_AGENT_DATABASE_PASSWORD\" psql --tuples-only --no-align --username \"\$CLAUDE_AGENT_DATABASE_USER\" --dbname \"\$CLAUDE_AGENT_DATABASE\" --command \"SELECT count(*) || ':' || min(status) FROM agent_delivery_ledger WHERE tenant_key = 'saas' AND message_id = $message_id\"")"
[[ "$ledger_rows" == "1:handed_off" ]] || {
  printf 'Durable delivery ledger did not record exactly one handoff.\n' >&2
  exit 1
}

academy_account_id="$(jq -r '.[] | select(.key == "new_academy") | .accountId' "$deployment_dir/runtime/tenants.json")"
cross_tenant_payload="$(jq -c --argjson account "$academy_account_id" '.account.id = $account' <<<"$payload")"
cross_tenant_status="$(curl --insecure --silent --output /dev/null --write-out '%{http_code}' \
  --header 'content-type: application/json' \
  --header "x-chatwoot-delivery: ${delivery_id}-cross" \
  --header "x-chatwoot-timestamp: $timestamp" \
  --header "x-chatwoot-signature: $signature" \
  --data-binary "$cross_tenant_payload" "$e2e_url")"
[[ "$cross_tenant_status" == 401 ]] || {
  printf 'Cross-tenant signature was not rejected: %s.\n' "$cross_tenant_status" >&2
  exit 1
}

# Seed one synthetic source, then exercise Chatwoot's actual message callback,
# AgentBot listener, SafeFetch, HMAC signing, queue, worker, and reply API.
# The one-off Rails process alone permits the internal test URL; production
# services keep private-network SafeFetch disabled.
# Database variables intentionally expand only inside the PostgreSQL container.
# shellcheck disable=SC2016
"${compose[@]}" exec -T postgres sh -ec '
  PGPASSWORD="$CLAUDE_AGENT_DATABASE_PASSWORD" psql \
    --username "$CLAUDE_AGENT_DATABASE_USER" --dbname "$CLAUDE_AGENT_DATABASE" <<SQL
DELETE FROM agent_knowledge_documents
 WHERE tenant_key = '\''saas'\'' AND source_id = '\''local-e2e'\'';
INSERT INTO agent_knowledge_documents
  (tenant_key, source_id, title, content, metadata, content_hash)
VALUES
  ('\''saas'\'', '\''local-e2e'\'', '\''Kontoeinrichtung'\'',
   '\''Die Kontoeinrichtung startet im Bereich Einstellungen.'\'',
   '\''{"url":"https://www.myinvest-pro.de/support"}'\''::jsonb,
   '\''local-e2e-v1'\'');
SQL
' >/dev/null

"${compose[@]}" run --rm \
  -e LOCAL_SMOKE=true \
  -e SAFE_FETCH_ALLOW_PRIVATE_NETWORK=true \
  -e E2E_AGENT_URL=http://claude-agent:8080/webhooks/chatwoot \
  rails bundle exec rails runner /bootstrap/e2e_real_path.rb >/dev/null

real_conversation_id="$(jq -r '.conversation_id' "$deployment_dir/runtime/e2e-real.json")"
real_message_id="$(jq -r '.message_id' "$deployment_dir/runtime/e2e-real.json")"
deadline=$((SECONDS + 60))
until "${compose[@]}" exec -T \
  -e E2E_CONVERSATION_ID="$real_conversation_id" -e E2E_MESSAGE_ID="$real_message_id" \
  rails bundle exec rails runner '
    conversation = Account.where("custom_attributes ->> ? = ?", "myinvest_tenant_key", "saas")
                          .first!.conversations.find(Integer(ENV.fetch("E2E_CONVERSATION_ID")))
    marker = ENV.fetch("E2E_MESSAGE_ID")
    # Chatwoot uses ActiveRecord::Store for this JSON column, so PostgreSQL sees
    # the serialized JSON string while the model exposes the decoded hash.
    replies = conversation.messages.outgoing.select do |message|
      message.content_attributes["myinvest_agent_delivery_id"] == marker
    end
    exit(replies.one? && replies.first.content.include?("Lokaler E2E-Antwortpfad erfolgreich.") ? 0 : 1)
  ' >/dev/null 2>&1; do
  (( SECONDS < deadline )) || {
    printf 'Timed out waiting for the real AgentBot reply path.\n' >&2
    exit 1
  }
  sleep 2
done

real_ledger="$("${compose[@]}" exec -T postgres sh -ec \
  "PGPASSWORD=\"\$CLAUDE_AGENT_DATABASE_PASSWORD\" psql --tuples-only --no-align --username \"\$CLAUDE_AGENT_DATABASE_USER\" --dbname \"\$CLAUDE_AGENT_DATABASE\" --command \"SELECT count(*) || ':' || min(status) FROM agent_delivery_ledger WHERE tenant_key = 'saas' AND message_id = $real_message_id\"")"
[[ "$real_ledger" == "1:replied" ]] || {
  printf 'Real AgentBot reply was not durably recorded exactly once.\n' >&2
  exit 1
}

printf 'E2E passed: real AgentBot reply, HMAC, duplicate suppression, handoff, and tenant rejection.\n'
