# WhatsApp Inbox Account Migration Handoff

## Objective

Move one existing `Channel::Whatsapp` inbox from the wrong Chatwoot account to the correct account while preserving the inbox history.

Scope of v1:

- preserve `conversations` and `messages`
- preserve the WhatsApp inbox/channel identity
- clone or reuse contacts in the destination account
- regenerate `conversation.display_id` in the destination account
- clear user/account-scoped artifacts that are unsafe cross-account

Artifact implemented for this work:

- `script/migrate_whatsapp_inbox_account.rb`

## Recommended execution model

Primary recommendation for production:

- run the script inside Kubernetes, in a Chatwoot web/rails pod, using the same image/env/secrets as the running app
- do **not** use the local workstation as first choice
- do **not** deploy app changes just to run this once; copy the script into a pod (for example under `/tmp`) and run `rails runner` there

Why:

- avoids copying DB/Redis secrets locally
- avoids local env drift
- uses the same runtime/config as production
- reduces risk around Redis/password/TLS/tunnel mismatches

Local fallback is acceptable only if the infra agent confirms:

- local checkout matches the deployed Chatwoot version closely enough
- SSH tunnels to Postgres and Redis are stable
- all required env vars/secrets are available locally

## Current script behavior

The script supports:

- `--mode=dry-run`
- `--mode=execute`

### Dry-run

Dry-run prints counts, warnings, and blockers without changing data.

### Execute

Inside one DB transaction, execute will:

- ensure destination account labels exist for migrated conversation labels
- find all contacts referenced by `contact_inboxes` for the source inbox
- reuse destination contacts when there is exactly one match by `identifier`, `email`, or `phone_number`
- clone contacts otherwise
- remap `contact_inboxes.contact_id`
- remap `messages.sender_id` when `sender_type = 'Contact'`
- update `messages.account_id` and `messages.inbox_id`
- update `attachments.account_id` for attachments tied to migrated messages
- update `csat_survey_responses.account_id` and `contact_id`
- clear `csat_survey_responses.assigned_agent_id`
- clear `csat_survey_responses.review_notes_updated_by_id`
- update `reporting_events.account_id` and `inbox_id`
- clear `reporting_events.user_id`
- update `conversations.account_id`
- regenerate `conversations.display_id` using `conv_dpid_seq_<target_account_id>`
- clear `conversations.assignee_id`
- clear `conversations.assignee_last_seen_at`
- clear `conversations.team_id`
- clear `conversations.assignee_agent_bot_id`
- clear `conversations.campaign_id`
- clear `conversations.sla_policy_id`
- delete `conversation_participants`
- delete `mentions`
- delete conversation/message-linked `notifications`
- move `inboxes.account_id`
- move `channel_whatsapp.account_id`
- remove `inbox_assignment_policy`
- remove `agent_bot_inbox`
- delete `inbox_members`
- clear the round-robin Redis queue
- reset account cache keys on source and destination accounts after commit

## v1 blockers intentionally enforced

The script aborts if any of the following exist for the source inbox/history:

- inbox is not `Channel::Whatsapp`
- source and target account are the same
- inbox/channel account mismatch already exists
- inbox-level `webhooks`
- inbox-level `integrations hooks`
- inbox `campaigns`
- conversations with `campaign_id`
- messages with `additional_attributes['campaign_id']`
- notes on referenced contacts
- conversations with `sla_policy_id`
- enterprise `applied_slas`
- enterprise `sla_events`
- ambiguous destination contact match
- `calls` rows on the inbox (voice/call feature)
- `captain_inboxes` link (Captain assistant attached to the inbox)
- `inbox_capacity_limits` rows (agent capacity policy attached to the inbox)
- `captain_assistant_responses` with `documentable_type='Conversation'` for the inbox's conversations
- `reporting_events_rollups` with `dimension_type='inbox'` for the inbox

Reason for blockers:

- v1 is optimized for safe migration of the happy path
- anything tightly coupled to account-specific integrations or policies is treated as out of scope
- the call/captain/capacity/rollup blockers prevent cross-account references after the move; clean those records first if you need to migrate

## Authorship of historical messages

The script preserves `messages.sender_id` for `sender_type='User'` and `sender_type='AgentBot'`:

- target-account agents will see historical messages attributed to user ids/bot ids that may belong to the source account
- this is intentional to keep history intact; dry-run reports counts so you can decide whether that is acceptable
- if it is not, those records should be cleaned up manually before/after the migration (out of scope for v1)

## Side-effect safety: the script does not re-send messages

The migration **never** triggers WhatsApp message delivery or any other outbound side effect.

Why:

- every mutation uses raw SQL (`update_all`, `update_columns`, `delete_all`, `insert_all!`)
- none of these instantiate ActiveRecord objects, so `Message` create/update/commit callbacks do not fire
- in particular `Message#send_reply` is only invoked from `after_create_commit`, and the script never creates `Message` rows
- `Attachment.update_all`, `Conversation.update_all`, `ContactInbox.update_all` and the inbox/channel `update_columns` follow the same pattern
- the entire mutation block runs inside a single `ActiveRecord::Base.transaction`, so any failure rolls back without leaving partial state

Operational implication:

- stopping Sidekiq during the window is recommended for general isolation, not because the script enqueues delivery jobs
- after the migration, agents on the destination account using the moved inbox will send messages normally because `channel_whatsapp.provider_config` (`api_key`, phone number id, etc.) is preserved and only `account_id` is moved

## Round-trip behavior (A → B → A)

Validated locally by running the migration both ways against the same inbox/account pair and diffing snapshots.

What is fully preserved on a round-trip back to the original account:

- `inboxes.account_id` returns to the original account
- `channel_whatsapp.account_id` and `phone_number` return to the original account
- all `messages` rows: `status`, `content`, `content_attributes`, `sender_type`, `sender_id`, `conversation_id`
- all `attachments` rows
- `contacts` rows in the original source account (intact, same ids)
- `contact_inboxes` re-point to the original contact ids (the dedupe logic matches them by phone/email/identifier)
- `inbox_members`, `notifications`, `mentions`, `conversation_participants` (already cleared during first migration and stay cleared)
- `reporting_events` are moved back and tied to the original conversation ids

What changes (by design, documented as warnings/behavior in dry-run):

- `conversations.display_id` advances on every move because the script calls `nextval('conv_dpid_seq_<account_id>')`. Doing A → B → A leaves the original conversations with new display ids in account A. External links that referenced the old display id will not resolve.
- `reporting_events.user_id` is cleared on every move and stays `NULL` thereafter.
- Cloned contacts in account B (created when the source contact had no match) are **not deleted** on the way back. After A → B → A, account B will contain orphan contact rows with no `contact_inbox` and no conversations attached. They are inert but visible in account B contact lists.

What this means operationally:

- the script is safe to re-run as a rollback path if you executed A → B and need to undo, with the caveat that display ids will have advanced and orphan contacts remain in B
- repeated round-trips compound these two effects (display ids keep advancing, orphan contacts keep accumulating); they do not corrupt history

Reproduction:

- `script/seed_migration_test_data.rb` builds a deterministic source/target/inbox/contacts fixture
- `script/snapshot_migration_state.sh <label> <source_id> <target_id> <inbox_id>` dumps a diffable snapshot of the relevant tables to `/tmp/chatwoot_snapshot_<label>.txt`
- run seed → snapshot → migrate A→B → snapshot → migrate B→A → snapshot → `diff -u`

## Important assumptions behind v1

- source is Chatwoot OSS-compatible core behavior; Enterprise tables may exist but SLA-linked history is blocked
- preserving history matters more than preserving current inbox membership/policies
- destination account should start without members/teams/assignees for this inbox
- deleting notifications/mentions/participants is acceptable for this migration
- reusing contacts is acceptable only when the match is unique

## Kubernetes runbook recommendation

### Before migration

- take a DB backup/snapshot
- schedule a maintenance window
- stop or scale down Sidekiq/worker deployments to `0`
- prevent agents from actively using the inbox during the window

### Dry-run approach

- choose a Chatwoot web/rails pod in the target namespace
- copy `script/migrate_whatsapp_inbox_account.rb` into the pod, for example to `/tmp/migrate_whatsapp_inbox_account.rb`
- run `bundle exec rails runner /tmp/migrate_whatsapp_inbox_account.rb --source-inbox-id=... --target-account-id=... --mode=dry-run`
- review blockers/warnings and stop if blockers exist

### Execute approach

- run the same command with `--mode=execute`
- validate the inbox and history immediately after execution
- scale workers back up only after validation

## Local fallback via SSH tunnel

Use only if running inside k8s is impractical.

Minimum local env expected by Chatwoot:

- `RAILS_ENV`
- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `POSTGRES_DATABASE`
- `POSTGRES_USERNAME`
- `POSTGRES_PASSWORD`
- `REDIS_URL`
- `REDIS_PASSWORD` if applicable

Potentially also needed depending on infra:

- `REDIS_SENTINELS`
- `REDIS_SENTINEL_MASTER_NAME`
- `REDIS_SENTINEL_PASSWORD`
- `REDIS_OPENSSL_VERIFY_MODE`
- any installation secrets required for Rails boot in the real deployment

## What the infra-specialized agent should provide or confirm

### Kubernetes/runtime

- namespace name
- Chatwoot web deployment/pod selector
- Sidekiq/worker deployment name(s)
- exact command path used in the running container (`bundle exec rails runner` should already work there)
- whether a temporary copied script under `/tmp` is acceptable

### Secrets/env

- how env vars are injected (Secret, ExternalSecret, SealedSecret, Helm values, etc.)
- whether the web pod already contains all Rails/DB/Redis env vars needed for runner execution
- whether any additional env vars are required in this installation beyond standard Chatwoot defaults

### Redis topology

- standalone Redis vs Sentinel vs managed service
- password/TLS requirements
- whether worker shutdown is enough to avoid interference during the migration window

### Operational safety

- exact worker scale-down/scale-up commands
- backup/snapshot procedure before execute
- rollback procedure if execute needs to be reverted from backup

## What the customized-code agent should review

Review both OSS and custom overlay code for anything that changes account/inbox/history behavior.

### High-priority review areas

- any custom changes under `enterprise/`
- any custom changes to `Conversation`, `Message`, `Contact`, `ContactInbox`, `Inbox`, `Channel::Whatsapp`
- any custom jobs/listeners/webhooks triggered by conversation or inbox updates
- any custom integrations/hooks/webhooks tied to inbox/account ownership
- any custom reporting tables or analytics consumers using `account_id`, `inbox_id`, or `conversation_id`
- any custom SLA/campaign/automation logic
- any custom Redis keys tied to inbox membership or account ownership

### Specific questions for the customized-code agent

- are there extra tables referencing `conversation_id`, `contact_id`, `inbox_id`, or `account_id` that the script must also update?
- are there custom callbacks/events on inbox/channel/account changes that could fire during this migration?
- are there custom WhatsApp routing rules based on `account_id` rather than phone-number/channel lookup?
- are there custom labels, notes, bots, campaign, or webhook behaviors that make current blockers insufficient?
- is there any custom code that assumes conversation participants/mentions/notifications must be preserved?

## Validation checklist after execute

- inbox appears in the target account
- source account no longer owns the inbox/channel
- migrated conversations open normally in the target account
- message history is intact
- contact identity per conversation is correct
- conversation `display_id` values are unique and valid in the target account
- WhatsApp outbound sending works
- inbound webhook processing still resolves the moved channel correctly
- labels display correctly in the target account
- no stale agent membership or round-robin state remains on the moved inbox

## Residual risks / open points

- v1 intentionally drops notifications, mentions, and conversation participants
- v1 intentionally blocks campaign/SLA/integration-heavy inboxes
- if custom code adds extra account-scoped tables, the script may need extension before execute
- production execution should be treated as a controlled maintenance operation, not a casual admin task

## Suggested handoff package to the next agent

Share these artifacts with the infra/custom-code agent:

- `script/migrate_whatsapp_inbox_account.rb`
- this document: `docs/whatsapp_inbox_account_migration_handoff.md`
- source inbox id
- target account id
- namespace / deployment names
- any known custom Chatwoot patches or private extensions
