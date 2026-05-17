#!/usr/bin/env bash
# Dumps relevant DB rows for the WhatsApp inbox migration round-trip test.
#
# Usage:
#   script/snapshot_migration_state.sh <label> <source_account_id> <target_account_id> <inbox_id>
#
# Output: /tmp/chatwoot_snapshot_<label>.txt with deterministic ordering
# so snapshots can be diffed with `diff -u`.

set -euo pipefail

LABEL="${1:?usage: $0 <label> <source_account_id> <target_account_id> <inbox_id>}"
SRC="${2:?missing source account id}"
TGT="${3:?missing target account id}"
INBOX="${4:?missing inbox id}"

OUT="/tmp/chatwoot_snapshot_${LABEL}.txt"
: > "${OUT}"

run_sql() {
  local title="$1"
  local sql="$2"
  {
    echo "===== ${title} ====="
    docker compose exec -T postgres psql -U postgres -d chatwoot_dev -A -F $'\t' -q -c "${sql}"
    echo
  } >> "${OUT}"
}

run_sql "accounts(${SRC},${TGT})" \
"SELECT id, name FROM accounts WHERE id IN (${SRC}, ${TGT}) ORDER BY id;"

run_sql "inboxes(inbox=${INBOX})" \
"SELECT id, account_id, channel_type, channel_id, name FROM inboxes WHERE id = ${INBOX};"

run_sql "channel_whatsapp(inbox=${INBOX})" \
"SELECT c.id, c.account_id, c.phone_number, c.provider
 FROM channel_whatsapp c JOIN inboxes i ON i.channel_id = c.id AND i.channel_type='Channel::Whatsapp'
 WHERE i.id = ${INBOX};"

run_sql "conversations(inbox=${INBOX})" \
"SELECT id, account_id, inbox_id, contact_id, status, assignee_id, team_id,
        campaign_id, sla_policy_id, additional_attributes::text
 FROM conversations WHERE inbox_id = ${INBOX} ORDER BY id;"

run_sql "conversation_display_ids(inbox=${INBOX})" \
"SELECT id, account_id, display_id FROM conversations WHERE inbox_id = ${INBOX} ORDER BY id;"

run_sql "messages(inbox=${INBOX})" \
"SELECT id, account_id, conversation_id, message_type, status, sender_type, sender_id,
        content, content_attributes::text, COALESCE(additional_attributes::text, '')
 FROM messages WHERE inbox_id = ${INBOX} ORDER BY id;"

run_sql "attachments(inbox=${INBOX})" \
"SELECT a.id, a.account_id, a.message_id, a.file_type
 FROM attachments a JOIN messages m ON m.id = a.message_id
 WHERE m.inbox_id = ${INBOX} ORDER BY a.id;"

run_sql "contacts(account=${SRC})" \
"SELECT id, account_id, name, email, phone_number, identifier
 FROM contacts WHERE account_id = ${SRC} ORDER BY id;"

run_sql "contacts(account=${TGT})" \
"SELECT id, account_id, name, email, phone_number, identifier
 FROM contacts WHERE account_id = ${TGT} ORDER BY id;"

run_sql "contact_inboxes(inbox=${INBOX})" \
"SELECT ci.id, ci.contact_id, ci.inbox_id, ci.source_id, c.account_id AS contact_account_id
 FROM contact_inboxes ci JOIN contacts c ON c.id = ci.contact_id
 WHERE ci.inbox_id = ${INBOX} ORDER BY ci.id;"

run_sql "reporting_events(account=${SRC})" \
"SELECT id, account_id, inbox_id, conversation_id, user_id, name
 FROM reporting_events WHERE account_id = ${SRC} ORDER BY id;"

run_sql "reporting_events(account=${TGT})" \
"SELECT id, account_id, inbox_id, conversation_id, user_id, name
 FROM reporting_events WHERE account_id = ${TGT} ORDER BY id;"

run_sql "inbox_members(inbox=${INBOX})" \
"SELECT id, user_id, inbox_id FROM inbox_members WHERE inbox_id = ${INBOX} ORDER BY id;"

run_sql "notifications(conv in inbox=${INBOX})" \
"SELECT id, account_id, primary_actor_type, primary_actor_id, secondary_actor_type
 FROM notifications
 WHERE (primary_actor_type='Conversation' AND primary_actor_id IN (SELECT id FROM conversations WHERE inbox_id=${INBOX}))
    OR (secondary_actor_type='Message' AND secondary_actor_id IN (SELECT id FROM messages WHERE inbox_id=${INBOX}))
 ORDER BY id;"

run_sql "row_counts" \
"SELECT 'conversations' AS t, COUNT(*) FROM conversations WHERE inbox_id=${INBOX}
 UNION ALL SELECT 'messages',      COUNT(*) FROM messages WHERE inbox_id=${INBOX}
 UNION ALL SELECT 'attachments',   COUNT(*) FROM attachments a JOIN messages m ON m.id=a.message_id WHERE m.inbox_id=${INBOX}
 UNION ALL SELECT 'contact_inboxes', COUNT(*) FROM contact_inboxes WHERE inbox_id=${INBOX}
 UNION ALL SELECT 'reporting_events_src', COUNT(*) FROM reporting_events WHERE account_id=${SRC}
 UNION ALL SELECT 'reporting_events_tgt', COUNT(*) FROM reporting_events WHERE account_id=${TGT}
 UNION ALL SELECT 'contacts_src',   COUNT(*) FROM contacts WHERE account_id=${SRC}
 UNION ALL SELECT 'contacts_tgt',   COUNT(*) FROM contacts WHERE account_id=${TGT}
 ORDER BY t;"

echo "Snapshot written to ${OUT}"
