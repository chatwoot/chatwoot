# WhatsApp Inbox Migration Briefing

## Goal

Move one existing `Channel::Whatsapp` inbox from the wrong Chatwoot account to the correct account while preserving history.

## Current implementation

Implemented script:

- `script/migrate_whatsapp_inbox_account.rb`

Primary handoff doc:

- `docs/whatsapp_inbox_account_migration_handoff.md`

## v1 migration strategy

- keep the same inbox and WhatsApp channel records
- move `inbox.account_id` and `channel_whatsapp.account_id`
- preserve `conversations` and `messages`
- regenerate `conversation.display_id` in the target account
- reuse destination contacts when there is exactly one unique match
- clone contacts otherwise
- clear cross-account user-scoped artifacts that are unsafe to keep

## What the script updates

- `contact_inboxes.contact_id`
- `messages.account_id`
- `messages.inbox_id`
- `messages.sender_id` for contact senders
- `attachments.account_id` for attachments tied to migrated messages
- `csat_survey_responses.account_id`
- `csat_survey_responses.contact_id`
- `reporting_events.account_id`
- `reporting_events.inbox_id`
- `conversations.account_id`
- `conversations.display_id`

## What the script clears/deletes intentionally

- `conversation_participants`
- `mentions`
- related `notifications`
- `inbox_members`
- `inbox_assignment_policy`
- `agent_bot_inbox`
- round-robin Redis queue
- conversation assignee/team/SLA/campaign references
- CSAT agent metadata
- reporting event user attribution

## Important blockers in v1

The script aborts on:

- inbox-level webhooks
- inbox-level integration hooks
- campaigns or campaign-linked history
- contact notes
- SLA-linked history
- ambiguous destination contact matches
- `calls` rows on the inbox (voice/call history)
- `captain_inboxes` link (Captain assistant attached to the inbox)
- `inbox_capacity_limits` rows (agent capacity policy attached to the inbox)
- `captain_assistant_responses` with `documentable_type='Conversation'` for the inbox's conversations
- `reporting_events_rollups` with `dimension_type='inbox'` for the inbox

## Side-effect safety

All mutations use raw SQL (`update_all`, `update_columns`, `delete_all`, `insert_all!`) inside a single transaction. ActiveRecord callbacks do not fire, so the script never re-sends WhatsApp messages or triggers any other outbound delivery. See the handoff doc for details.

## Execution recommendation

Preferred production execution model:

- run inside Kubernetes in a Chatwoot web/rails pod
- copy the script into the pod temporarily
- run `bundle exec rails runner` there
- stop/scale down workers before `execute`

Local execution through SSH tunnels is a fallback only.

## What the next agent should confirm

- correct namespace and web pod/deployment
- worker deployment names and scale-down procedure
- how env vars/secrets are injected in k8s
- whether custom code adds extra account/inbox/conversation-linked tables
- whether any custom WhatsApp/integration behavior makes v1 insufficient
