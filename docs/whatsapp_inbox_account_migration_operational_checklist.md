# WhatsApp Inbox Migration Operational Checklist

## Inputs required

- source inbox id
- target account id
- Kubernetes namespace
- Chatwoot web pod/deployment name
- worker/Sidekiq deployment name(s)

## Pre-flight checklist

- [ ] Confirm this is a `Channel::Whatsapp` inbox
- [ ] Confirm source and target account ids
- [ ] Confirm maintenance window
- [ ] Confirm DB backup/snapshot plan
- [ ] Confirm rollback owner and rollback process
- [ ] Confirm workers can be scaled to `0`
- [ ] Confirm no active agent usage on the inbox during the window
- [ ] Confirm script file to run: `script/migrate_whatsapp_inbox_account.rb`
- [ ] Confirm custom code review is complete
- [ ] Confirm infra review is complete

## Kubernetes dry-run checklist

- [ ] Select a Chatwoot web/rails pod in the target namespace
- [ ] Copy script into pod, e.g. `/tmp/migrate_whatsapp_inbox_account.rb`
- [ ] Run `bundle exec rails runner ... --mode=dry-run`
- [ ] Save dry-run output for review
- [ ] Review blockers (script aborts on calls / captain inboxes / inbox capacity limits / captain assistant responses / reporting events rollups, plus the existing SLA/campaign/webhook/note blockers)
- [ ] Review warnings (including counts for `sender_type='User'` / `sender_type='AgentBot'` messages whose authorship will be preserved cross-account)
- [ ] Review counts for conversations/messages/attachments/contacts/notifications/reporting/CSAT
- [ ] Stop if any blocker exists

## Pre-execute checklist

- [ ] Dry-run completed with no blockers
- [ ] Backup/snapshot is confirmed fresh enough
- [ ] Worker deployments scaled down to `0`
- [ ] Sidekiq queues for the moving inbox (destroy_async, webhook, automation) are drained
- [ ] Inbox is not being actively used
- [ ] Command for execute is prepared and reviewed
- [ ] List of target-account members/teams to add to the inbox post-execute is prepared

## Execute checklist

- [ ] Run `bundle exec rails runner ... --mode=execute`
- [ ] Capture full stdout/stderr (the last line prints the absolute path of the pre-migration snapshot JSON)
- [ ] Do not restart workers until validation is done
- [ ] Copy the snapshot JSON out of the pod before the pod is destroyed: `kubectl cp <namespace>/<pod>:<snapshot_path> ./inbox_<id>_<ts>.json`
- [ ] Store the snapshot alongside the dry-run output and the DB backup reference for the change record
- [ ] Optional: override default location with `--snapshot-path=/tmp/inbox_<id>.json` when the default `tmp/migration_snapshots/` is not writable

## Post-execute validation checklist

- [ ] Inbox now belongs to the target account
- [ ] Source account no longer owns the inbox/channel
- [ ] Conversations open normally in the target account
- [ ] Message history is intact
- [ ] Attachments display correctly in migrated messages
- [ ] Contact identity is correct in migrated conversations
- [ ] Display ids are valid in the target account
- [ ] WhatsApp outbound sending works
- [ ] WhatsApp inbound processing works
- [ ] Labels display correctly
- [ ] No stale inbox members or round-robin state remain
- [ ] Target-account members/teams are added to the inbox (script does not seed them)

## Post-execute communication checklist

- [ ] Notify source-account agents to hard refresh (Cmd/Ctrl+Shift+R); the migrated inbox will disappear from their sidebar
- [ ] Add inbox members on the target account
- [ ] Notify target-account agents to hard refresh; the migrated inbox will appear in their sidebar
- [ ] Confirm with a target-account agent that conversations open and reply works end-to-end

## Re-enable background processing

- [ ] Sidekiq queue counts inspected for leftover destroy_async jobs targeting migrated records
- [ ] Workers scaled back to original replica count
- [ ] Queue/worker health looks normal
- [ ] No immediate follow-up errors in logs

## If something is wrong

- [ ] Stop and avoid retrying execute blindly
- [ ] Preserve logs/output
- [ ] Compare actual state vs expected state
- [ ] Decide between targeted remediation and restore-from-backup with the infra owner
