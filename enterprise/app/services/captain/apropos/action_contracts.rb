class Captain::Apropos::ActionContracts
  COMMON_EFFECTS = 'Uses normal model callbacks, events, and configured automation. Inspect receipts and current state before retrying.'.freeze
  DEFINITIONS = {
    'create-contact-note' => {
      target: 'contacts', arguments: { content: 'nonblank string: internal note text' }, effect: 'internal_write',
      description: 'Create an internal note on a contact profile. Not a conversation private note or customer message.',
      example: '(act "create-contact-note" (hash "type" "contacts" "id" 42) (hash "content" "Prefers email follow-ups."))',
      returns: 'Receipt result: ref (contact_notes), contact_id, content, user_id. Use related contact-ref "notes" to read notes.',
      requirements: 'Existing contact in this account and nonblank string content.',
      side_effects: 'Creates a Note with the acting user as author; normal model callbacks apply. No customer message is sent.',
      retry: 'Not idempotent: retrying creates another note. Inspect receipts before retrying.'
    },
    'update-contact-note' => {
      target: 'contact_notes', arguments: { content: 'nonblank string: complete replacement text' }, effect: 'internal_write',
      description: 'Replace an existing contact note, matching the app contact-note update behavior. Read the current note first.',
      example: '(act "update-contact-note" (hash "type" "contact_notes" "id" 7) (hash "content" "Prefers phone follow-ups."))',
      returns: 'Receipt result: ref, contact_id, content, user_id.',
      requirements: 'Existing note in this account; cannot move the note to another contact.',
      side_effects: 'Replaces content and sets user_id to the acting user, as the UI does. No customer message is sent.',
      retry: 'Same content is repeatable, but may overwrite another user edit. Re-read current state before retrying.'
    },
    'add-private-note' => { target: 'conversations', arguments: { content: 'string' }, effect: 'internal_write' },
    'send-reply' => { target: 'conversations', arguments: { content: 'string' }, effect: 'external_write' },
    'set-status' => { target: 'conversations', arguments: { status: 'open | resolved | pending' }, effect: 'internal_write' },
    'set-priority' => { target: 'conversations', arguments: { priority: 'low | medium | high | urgent' }, effect: 'internal_write' },
    'assign-team' => { target: 'conversations', arguments: { team_id: 'account team database ID' }, effect: 'internal_write' },
    'assign-agent' => { target: 'conversations', arguments: { agent_id: 'account agent database ID' }, effect: 'internal_write' },
    'add-label' => { target: 'conversations', arguments: { label: 'existing account label title' }, effect: 'internal_write' },
    'create-conversation' => {
      target: 'inboxes', arguments: { contact_id: 'integer: existing contact database ID in this account' }, effect: 'internal_write',
      description: 'Open a conversation for an existing contact in an inbox. No initial message is sent by this operation.',
      example: '(act "create-conversation" (hash "type" "inboxes" "id" 10) (hash "contact_id" 42))',
      returns: 'Receipt result: ref, display_id, created, status, inbox_id, contact_id. created=false means an existing conversation was returned.',
      requirements: 'Contact and inbox must belong to the current account. Channel-specific email/phone requirements apply.',
      behavior: 'Reuses or builds the contact-inbox. ConversationBuilder honors lock_to_single_conversation. ' \
                'Existing conversations are not reopened. New status follows normal model defaults and callbacks.',
      retry: 'Not idempotent unless the inbox enforces a single conversation. A retry can create another conversation.',
      side_effects: COMMON_EFFECTS
    },
    'create-contact' => {
      target: 'accounts',
      arguments: { attributes: 'object: optional name string; email, phone_number, identifier string or null; custom_attributes object' },
      effect: 'internal_write', description: 'Create an account contact, without an inbox association or conversation.',
      example: '(act "create-contact" (hash "type" "accounts" "id" 1) (hash "attributes" (hash "name" "Maya" "email" "maya@example.com")))',
      returns: 'Receipt result: ref and created=true. Use fetch on the ref for normalized values.',
      requirements: 'Current account only. Unknown fields are rejected; normal contact format and uniqueness validation applies.',
      retry: 'Not idempotent. Search existing contacts and inspect receipts before retrying; do not assume email implies an upsert.',
      side_effects: COMMON_EFFECTS
    },
    'update-contact' => {
      target: 'contacts',
      arguments: { attributes: 'object: optional name string; email, phone_number, identifier string or null; custom_attributes object' },
      effect: 'internal_write', description: 'Update supplied contact fields; merge supplied custom-attribute keys, preserving other keys.',
      example: '(act "update-contact" (hash "type" "contacts" "id" 42) (hash "attributes" (hash "name" "Maya")))',
      returns: 'Receipt result: ref, contact fields, and merged custom_attributes.',
      requirements: 'Existing account contact. Unknown fields and malformed types are rejected; model validation applies.',
      retry: 'Setting the same values is repeatable, but concurrent edits and callback effects must be considered.', side_effects: COMMON_EFFECTS
    },
    'update-label' => {
      target: 'labels', arguments: { attributes: 'object: optional title string, description string or null, color string, show_on_sidebar boolean' },
      effect: 'internal_write', description: 'Edit an existing account label. Does not create a label.',
      example: '(act "update-label" (hash "type" "labels" "id" 12) (hash "attributes" (hash "color" "#ff0000")))',
      returns: 'Receipt result: id, title, description, color, show_on_sidebar.',
      requirements: 'Existing account label. Title format and uniqueness validation applies.',
      side_effects: 'Renaming schedules Chatwoot label-association updates across the account; propagation is asynchronous.',
      retry: 'Repeatable values, but inspect current state before retrying a rename.'
    },
    'remove-label' => {
      target: 'conversations', arguments: { label: 'string: exact label title to remove' }, effect: 'internal_write',
      description: 'Remove one label from a conversation, preserving other labels. Does not delete the account label.',
      example: '(act "remove-label" (hash "type" "conversations" "id" 123) (hash "label" "agent-triage"))',
      returns: 'Receipt result: updated labels list.', requirements: 'Existing account conversation; label title is matched exactly.',
      retry: 'Removing an absent label is a no-op on the label set.', side_effects: COMMON_EFFECTS
    },
    'update-custom-attributes' => {
      target: 'conversations', arguments: { attributes: 'object with string keys: custom-attribute values to merge' }, effect: 'internal_write',
      description: 'Merge conversation custom attributes without replacing unspecified keys. Null is stored as a value, not key deletion.',
      example: '(act "update-custom-attributes" (hash "type" "conversations" "id" 123) (hash "attributes" (hash "reviewed" #t)))',
      returns: 'Receipt result: merged custom_attributes.', requirements: 'Existing account conversation; normal model validation applies.',
      retry: 'Repeatable values, but concurrent edits may change the current attributes.', side_effects: COMMON_EFFECTS
    },
    'unassign-agent' => {
      target: 'conversations', arguments: {}, effect: 'internal_write',
      description: 'Clear the human assignee, leaving the team and bot assignments unchanged.',
      example: '(act "unassign-agent" (hash "type" "conversations" "id" 123) (hash))',
      returns: 'Receipt result: agent_id and team_id after callbacks.', requirements: 'Existing account conversation.',
      retry: 'Already-unassigned is valid. Configured assignment automation can subsequently assign another agent.', side_effects: COMMON_EFFECTS
    },
    'unassign-team' => {
      target: 'conversations', arguments: {}, effect: 'internal_write', description: 'Clear the team without explicitly clearing the human assignee.',
      example: '(act "unassign-team" (hash "type" "conversations" "id" 123) (hash))',
      returns: 'Receipt result: agent_id and team_id after callbacks.', requirements: 'Existing account conversation.',
      retry: 'Already-unassigned is valid. Subsequent automation may alter assignments.', side_effects: COMMON_EFFECTS
    },
    'snooze-conversation' => {
      target: 'conversations', arguments: { until: 'string: future ISO 8601 timestamp with Z or explicit timezone offset' }, effect: 'internal_write',
      description: 'Set snoozed status until a specific future time. Normal Chatwoot wake-up and incoming-message behavior applies.',
      example: '(act "snooze-conversation" (hash "type" "conversations" "id" 123) (hash "until" "2027-01-01T09:00:00Z"))',
      returns: 'Receipt result: status and snoozed_until.',
      requirements: 'Existing conversation; malformed, timezone-less, and past times are rejected.',
      retry: 'Repeatable while the requested time remains in the future; reread status before retrying.', side_effects: COMMON_EFFECTS
    }
  }.freeze
end
