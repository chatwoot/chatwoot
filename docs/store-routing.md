# Store routing and the Hermes assignment ledger

Store routing extends native Assignment V2. Teams and their members are managed in
Chatwoot's existing Settings → Teams screen. Only online inbox members with the
assignment policy's seller role participate. Store/team mappings are internal
account configuration; no public endpoint or second distributor is introduced.

## Routing contract

- The first public incoming message supplies `[PSD]`, `[LAP]`, or `[TAT]`, ignoring case.
- Without a code, use structured Meta campaign/ad-set metadata, then the same phone's
  latest identified store conversation within 60 days, then `loja-indefinida`.
- Wait at most five seconds after the first incoming message for ad enrichment.
  No customer message means no automatic store decision yet.
- Labels and `campanha` belong to the conversation. Original messages are untouched.
  The initial classification is frozen; existing manual owners/teams are preserved.
- An online store waits if its agents reach the native hourly or capacity limit.
  Only an offline store falls back to another active store team. Its original store
  label remains; its assigned team is the receiving seller's team.
- Returning customers prefer their previous seller when that seller is eligible.
  Otherwise balance by open unattended conversations, with native round-robin ties.
  A bulk run visits eligible sellers before repeating. Returning-owner preference
  takes precedence over this round, as specified by the customer-return rule.
- Overnight leads precede daytime leads, oldest first. Daytime leads retain their
  assignment policy's priority. Existing business hours and seven-day exclusions apply.
- Manual assignment remains available to managers. The five-minute reassignment
  timer is intentionally outside this release.

For a store transfer, update the team and store label together in Chatwoot. Remove
a seller from their old store team before adding them to another. Duplicate store
memberships are treated as misconfiguration, not resolved by picking an arbitrary team.

## Durable reporting

Each assignee change to a user creates a `ConversationAssignmentEvent` in the same
database transaction. This includes automatic and manual assignments for the
configured ledger inboxes. Events distinguish `initial` from `reassignment` and
include agent/name, store/origin/campaign/rule, first incoming timestamp, assignment
timestamp and the conversation's internal and display IDs.

The low-priority sync job inserts into the existing Hermes `distribution_logs`.
A unique `event_key` makes retries safe, including a crash after the remote INSERT
but before acknowledging it locally. A minute job recovers pending deliveries.
Hermes's existing `conversation_id` continues to contain the **display ID**.
`assigned_at` preserves UTC in the legacy timezone-less column; `date` is the
São Paulo business date. Existing reports continue counting assignment events;
new columns allow distinguishing transfers from unique leads in future reports.

No historical assignments are reconstructed from current owners or backfilled by
activation. Recovery of the n8n-to-native gap is a separate evidence-based operation.

## Deployment

1. Back up the Chatwoot database and Hermes `distribution_logs`, then rehearse both
   additive schemas on isolated copies with separate Redis and outbound traffic disabled.
2. Apply the Rails migration and `script/hermes_assignment_ledger.sql` to their
   respective databases. The latter uses a short lock timeout and preserves old rows.
3. Provision a PostgreSQL user with INSERT/SELECT on `distribution_logs` and USAGE
   on its sequence. Configure `HERMES_DISTRIBUTION_DATABASE_URL` on the app and both
   workers; do not put its credentials in account settings, source or logs.
4. Deploy the same immutable release image to all three services.
5. Preview the configuration with `ACCOUNT_ID`, `CONFIG_PATH` and
   `bundle exec rails runner script/configure_store_routing.rb`.
   Add `APPLY=true` only after reviewing the team membership and inbox scope.
6. Check labels, ownership, event rows, pending age, successful Hermes inserts,
   hourly/capacity limits and unchanged settings on other inboxes.

Configuration input example (replace all IDs with reviewed account-specific IDs):

```json
{
  "inbox_ids": [20],
  "ledger_inbox_ids": [20, 56, 57, 58, 59, 60],
  "stores": {
    "psd": {"team_name": "pq. são domingos", "member_ids": [18, 10, 40]},
    "lap": {"team_name": "lapa", "member_ids": [12, 32, 46]},
    "tat": {"team_name": "tatuapé", "member_ids": [21, 44, 47]}
  }
}
```

The setup script changes store-team seller membership, preserving managers. It
does not alter the assignment policy, capacity limits, existing conversation owners,
personal reads, Captain, logout settings, or other inboxes' routing.

## Rollback

Remove `store_routing` from the account's internal attributes to restore native
selection. Keep `assignment_ledger` and the new database tables while unsynced
events exist. Restore team memberships from the configuration preview if required.
An application rollback can retain both additive schemas. Database restoration
requires reconciling post-backup assignment events and other writes before resuming.
