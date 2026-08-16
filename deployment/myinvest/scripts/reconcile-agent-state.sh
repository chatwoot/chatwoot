#!/usr/bin/env bash
set -Eeuo pipefail

deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_path="${ENV_FILE:-$deployment_dir/.env}"
compose=(docker compose --project-directory "$deployment_dir" --env-file "$env_path" -f "$deployment_dir/compose.yaml")

set -a
# shellcheck disable=SC1090
source "$env_path"
set +a

[[ "${AGENT_STATE_RECONCILE_CONFIRMATION:-}" == "reconcile:${CADDY_SITE_ADDRESS}" ]] || {
  printf 'Set AGENT_STATE_RECONCILE_CONFIRMATION=reconcile:%s for this exact host.\n' "$CADDY_SITE_ADDRESS" >&2
  exit 1
}

work_dir="$(mktemp -d "$deployment_dir/runtime/agent-state-reconcile.XXXXXX")"
live_messages="$work_dir/live-messages.tsv"
live_conversations="$work_dir/live-conversations.tsv"
postgres_id="$("${compose[@]}" ps -q postgres)"
run_tag="$(date -u +%Y%m%dT%H%M%SZ)-$$"
container_messages="/tmp/myinvest-agent-state-${run_tag}-messages.tsv"
container_conversations="/tmp/myinvest-agent-state-${run_tag}-conversations.tsv"
writers_paused=false

cleanup() {
  if [[ -n "$postgres_id" ]]; then
    docker exec "$postgres_id" find /tmp -maxdepth 1 -type f \
      \( -name "$(basename "$container_messages")" -o -name "$(basename "$container_conversations")" \) \
      -delete >/dev/null 2>&1 || true
  fi
  find "$work_dir" -depth -delete >/dev/null 2>&1 || true
  if [[ "$writers_paused" == true ]]; then
    "${compose[@]}" unpause caddy sidekiq claude-agent >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

[[ -n "$postgres_id" ]] || {
  printf 'PostgreSQL container is not running.\n' >&2
  exit 1
}

# Hold public ingress and asynchronous delivery writers while Rails produces the
# live relation and PostgreSQL commits the reconciliation. Rails stays running
# only so the read-only runner can export the canonical Chatwoot identifiers.
"${compose[@]}" pause caddy sidekiq claude-agent >/dev/null
writers_paused=true

"${compose[@]}" exec -T -e TENANTS_JSON rails bundle exec rails runner '
  require "json"
  tenants = JSON.parse(ENV.fetch("TENANTS_JSON")).to_h do |tenant|
    [Integer(tenant.fetch("accountId")), tenant.fetch("key")]
  end
  Message.incoming.where(private: false).joins(:conversation)
    .where(conversations: { account_id: tenants.keys }).find_each do |message|
      conversation = message.conversation
      puts [tenants.fetch(conversation.account_id), message.id, conversation.display_id, message.created_at.to_i].join("\t")
    end
' > "$live_messages"

"${compose[@]}" exec -T -e TENANTS_JSON rails bundle exec rails runner '
  require "json"
  tenants = JSON.parse(ENV.fetch("TENANTS_JSON")).to_h do |tenant|
    [Integer(tenant.fetch("accountId")), tenant.fetch("key")]
  end
  Conversation.where(account_id: tenants.keys).find_each do |conversation|
    puts [tenants.fetch(conversation.account_id), conversation.display_id, conversation.created_at.to_i].join("\t")
  end
' > "$live_conversations"

docker cp "$live_messages" "$postgres_id:$container_messages" >/dev/null
docker cp "$live_conversations" "$postgres_id:$container_conversations" >/dev/null

docker exec -i "$postgres_id" sh -ec \
  'PGPASSWORD="$CLAUDE_AGENT_DATABASE_PASSWORD" psql --quiet --tuples-only --no-align --set=ON_ERROR_STOP=1 --username "$CLAUDE_AGENT_DATABASE_USER" --dbname "$CLAUDE_AGENT_DATABASE"' <<SQL
BEGIN;
CREATE TEMP TABLE live_message_events (
  tenant_key text NOT NULL,
  message_id bigint NOT NULL,
  conversation_id bigint NOT NULL,
  created_at_epoch bigint NOT NULL,
  PRIMARY KEY (tenant_key, message_id)
);
CREATE TEMP TABLE live_conversation_events (
  tenant_key text NOT NULL,
  conversation_id bigint NOT NULL,
  created_at_epoch bigint NOT NULL,
  PRIMARY KEY (tenant_key, conversation_id)
);
\copy live_message_events (tenant_key, message_id, conversation_id, created_at_epoch) FROM '$container_messages' WITH (FORMAT text, DELIMITER E'\t');
\copy live_conversation_events (tenant_key, conversation_id, created_at_epoch) FROM '$container_conversations' WITH (FORMAT text, DELIMITER E'\t');

CREATE TEMP TABLE reconcile_counts (name text PRIMARY KEY, value bigint NOT NULL);
CREATE TEMP TABLE delivery_to_retire AS
SELECT ledger.tenant_key, ledger.message_id
FROM agent_delivery_ledger AS ledger
WHERE ledger.message_id > 0
  AND ledger.conversation_id > 0
  AND NOT EXISTS (
    SELECT 1 FROM live_message_events AS live
    WHERE live.tenant_key = ledger.tenant_key
      AND live.message_id = ledger.message_id
      AND live.conversation_id = ledger.conversation_id
      AND extract(epoch FROM ledger.updated_at)::bigint >= live.created_at_epoch
  );

CREATE TEMP TABLE conversation_state_to_retire AS
SELECT state.tenant_key, state.conversation_id
FROM agent_conversation_states AS state
WHERE state.conversation_id > 0
  AND state.status = 'handed_off'
  AND NOT EXISTS (
    SELECT 1 FROM live_conversation_events AS live
    WHERE live.tenant_key = state.tenant_key
      AND live.conversation_id = state.conversation_id
      AND extract(epoch FROM state.updated_at)::bigint >= live.created_at_epoch
  );

INSERT INTO reconcile_counts
SELECT 'retired_delivery', count(*) FROM delivery_to_retire;

UPDATE agent_delivery_ledger AS ledger
SET conversation_id = -abs(ledger.conversation_id)
FROM delivery_to_retire AS stale
WHERE ledger.tenant_key = stale.tenant_key
  AND ledger.message_id = stale.message_id;

INSERT INTO reconcile_counts
SELECT 'retired_conversation_states', count(*) FROM conversation_state_to_retire;

UPDATE agent_conversation_states AS state
SET status = 'active'
FROM conversation_state_to_retire AS stale
WHERE state.tenant_key = stale.tenant_key
  AND state.conversation_id = stale.conversation_id;

INSERT INTO reconcile_counts
SELECT 'remaining_delivery_mismatches', count(*)
FROM agent_delivery_ledger AS ledger
WHERE ledger.message_id > 0
  AND ledger.conversation_id > 0
  AND NOT EXISTS (
    SELECT 1 FROM live_message_events AS live
    WHERE live.tenant_key = ledger.tenant_key
      AND live.message_id = ledger.message_id
      AND live.conversation_id = ledger.conversation_id
      AND extract(epoch FROM ledger.updated_at)::bigint >= live.created_at_epoch
  );

INSERT INTO reconcile_counts
SELECT 'remaining_conversation_state_mismatches', count(*)
FROM agent_conversation_states AS state
WHERE state.conversation_id > 0
  AND state.status = 'handed_off'
  AND NOT EXISTS (
    SELECT 1 FROM live_conversation_events AS live
    WHERE live.tenant_key = state.tenant_key
      AND live.conversation_id = state.conversation_id
      AND extract(epoch FROM state.updated_at)::bigint >= live.created_at_epoch
  );

SELECT json_build_object(
  'event', 'agent_state_reconciled',
  'retired_delivery', (SELECT value FROM reconcile_counts WHERE name = 'retired_delivery'),
  'retired_conversation_states', (SELECT value FROM reconcile_counts WHERE name = 'retired_conversation_states'),
  'remaining_delivery_mismatches', (SELECT value FROM reconcile_counts WHERE name = 'remaining_delivery_mismatches'),
  'remaining_conversation_state_mismatches', (SELECT value FROM reconcile_counts WHERE name = 'remaining_conversation_state_mismatches')
);
COMMIT;
SQL
