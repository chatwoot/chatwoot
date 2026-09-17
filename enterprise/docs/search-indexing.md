# Contact and conversation search indexing

The indexing pipeline coalesces committed record IDs in Redis and flushes every
30 seconds. Source records are loaded from the primary database. Claimed IDs
remain in Redis with a 120-second visibility timeout until individual bulk
results are acknowledged. Updates arriving during a write remain pending.

Run dedicated live workers with `bundle exec sidekiq -q search_indexing`.
The default shared queue is a development/self-hosted convenience, not a
production capacity reservation. Keep live indexing separate from backfill
workers. The 30-second flush interval is not a visibility guarantee: worker
latency and OpenSearch refresh add to it.

Documents use external write versions allocated before loading primary records.
Deleted rows produce minimal versioned tombstones without indexed customer
content. All readers must exclude `deleted: true`. Worker recovery re-reads
current data; expired owners cannot acknowledge a successor's claim.

The Redis epoch and monotonic sequence have no expiration and require Redis
persistence and a non-evicting queue store. Loss of either creates a new epoch,
which addresses a different physical index. Old work cannot write to a new
generation. Never restore/reset the counter independently of its epoch.
A whole Redis restore requires explicitly rotating the epoch and rebuilding.

Inspect pending/failed/oldest work with
`SearchIndexing::Buffer.new(entity: entity, account_id: account_id).statistics`.
Permanent bulk item errors are retained without document payloads. After
repairing the cause, use `retry_failed` until no failed entries remain.
Transient bulk errors retry with bounded exponential backoff. Transport errors
retain claims for recovery by the dispatcher.

This is at-least-once processing, not a transactional outbox. Process death
between a database commit and Redis enqueue requires reconciliation/backfill.
Contact producers are default-off. Enable the account's
`contact_search_indexing` flag to start writes; Cloud additionally requires
`advanced_search_indexing`. Existing self-hosted message indexing is unchanged.
Deleting contacts still queues cleanup after the flag is disabled.
Normal contact saves, merges, CSV saves, and silent integration import writes
all use the same after-commit producer. Read rollout is controlled separately.

Contact text uses contiguous three-character tokens with phrase matching to
preserve substring search, including punctuation and spaces. Short terms and
query forms that cannot preserve SQL semantics must stay on SQL. The schema
uses standard text mappings rather than requiring newer wildcard field types.
Only fields required for search, eligibility, and supported sorts are indexed.

Enable the default-off `conversation_search_indexing` account flag to index
conversation identity, inbox, activity times, and associated contact search
fields. Message activity and silent imports explicitly submit their direct
updates. Contact identity changes/deletion coalesce in the
`contact_conversations` buffer. Its worker persists a primary-key cursor after
each 500-conversation page. A newer contact change restarts that cursor; expired
workers cannot overwrite successor progress. Contact activity-only changes do
not fan out. Existing message indexing and search remain unchanged.

## Backfills and reconciliation

Run a separate `bundle exec sidekiq -q search_backfill -c 2` worker after running
database migrations. Backfills are explicitly started, never started by a deploy:

```sh
ENTITY=contacts ACCOUNT_ID=123 bundle exec rails search:backfill
ENTITY=conversations ACCOUNT_ID=123 bundle exec rails search:backfill
ACCOUNT_ID=123 bundle exec rails search:indexing_status
STATE_ID=1 bundle exec rails search:pause_backfill
STATE_ID=1 bundle exec rails search:resume_backfill
```

Omit `ACCOUNT_ID` to enqueue backfills for all accounts eligible for the chosen
entity, in pages of 25 accounts. Start with one canary account. Measure Redis
memory, queue age, database load, OpenSearch bulk latency/rejections and backfill
progress before increasing concurrency. The defaults are starting limits, not
measured production throughput guarantees.

Each job reads at most 500 source IDs, waits 30 seconds between pages, and pauses
feeding when more than 2,000 IDs are pending for that account/entity. A Postgres
state stores the cursor, upper source ID, schema/generation, status, counts and
readiness. Every page rotates its run token; duplicate/stale jobs cannot advance
a resumed or restarted run. A one-minute maintenance job recovers interrupted
running states. Pause takes effect after the current bounded page completes.

Completion requires draining captured writes and contact-to-conversation
dependencies, comparing source documents, and sweeping indexed IDs for records
no longer in the database. Repairs go through the same live writer and external
version protocol. Repeat verification until no repairs remain. A continuously
busy or unhealthy account may remain unready until its pending queue drains;
monitor its oldest pending timestamp and provision live capacity accordingly.
Permanent failed items block completion. After fixing the cause:

```sh
STATE_ID=1 CURSOR=0 bundle exec rails search:retry_failed_writes
# Repeat with the returned cursor until it is 0 and the failed count is 0.
STATE_ID=1 bundle exec rails search:resume_backfill
```

Ready accounts are reconciled at least daily as worker capacity permits. This
checks current source data without rewriting unchanged documents, and catches
missed callbacks and deletions. A repair clears readiness until verification
finishes. Disabling indexing invalidates readiness; re-enabling requires an
explicit backfill. Deleting an account schedules an indexed-data purge and
retains only its progress record until the purge completes.

After Redis loss/restoration, stop old workers, rotate the epoch (delete
`SearchIndexing::Store::EPOCH_KEY` through `Redis::Alfred`), and start fresh
backfills before enabling reads. Never copy a lower sequence into an existing
epoch. Old physical indices are not read by the new epoch. Delete old physical
indices only after old workers are stopped and the replacement is verified;
include them in customer-data retention/deletion procedures. Redis and database
restores require this same procedure. Search readiness is always checked against
the current epoch and schema, rather than inferred from document counts.

## Search read rollout

After both backfills are verified for a canary account, enable `contact_search`
and/or `conversation_search` on that account. These flags default off and do not
replace either writer flag. Global contact/conversation search and
`/contacts/search` use OpenSearch; conversation-list message-body search and
message search retain their existing implementations.

OpenSearch supplies at most 1,000 candidate IDs. The application applies the
current SQL search/authorization scope, CRM rules, date filters, sorting and
pagination to that bounded set. The complete candidate set is used before
pagination, so revoked permissions or stale hits cannot underfill a page or
expose an unauthorized engine total. Conversation candidates are scoped to the
account and current inboxes in OpenSearch and checked again through
`PermissionFilterService` in SQL, including custom roles. Contact identifier
case handling remains specific to each endpoint. All existing contact sorts
and response metadata are preserved, with an ID tie-breaker for stable pages.

Queries with more than 1,000 candidates use SQL for the whole request, on every
page. This avoids silent truncation and OpenSearch's deep-pagination limit.
SQL also handles terms shorter than three characters, terms longer than 256
characters, non-ASCII terms, and SQL wildcard/escape syntax. This deliberately
retains broad-query database costs; measure the candidate cap against production
workloads before expanding the rollout. Search remains eventually consistent:
new matching records can appear after the live write batch and index refresh.

Reads require the matching verified epoch/schema, no permanent failed items,
and no live/dependency work older than two minutes. Missing readiness, excessive
lag, partial/timed-out engine results, and known transport/availability errors
fall back to SQL. Valid empty results stay empty. Programming and mapping errors
are not swallowed. Recreating a missing physical index invalidates readiness
for all affected accounts; run backfills again. Administratively replacing an
index must follow the generation-reset procedure above.

Use `search.search_indexing`, `fallback.search_indexing`, and
`flush.search_indexing` notifications to measure engine time, fallback reasons
and bulk latency without recording search terms or document content. Compare
query latency and database cost on a canary, allow the normal indexing delay
when comparing results, and check all contact sorts, CRM modes, date filters,
restricted roles, and multiple pages. No production benchmark or rollout is
implied by the local validation.

Rollback is immediate: disable `contact_search` and/or `conversation_search`.
Keep writer flags and live workers enabled so a later read canary can resume.
Pause a backfill to stop feeding new historical pages; committed pending writes
continue to drain. To cancel its readiness and invalidate outstanding page jobs,
call `SearchIndexing::IndexState.find(state_id).invalidate!` from the console.
Restart with `search:backfill` to reset the cursor and verify a new run.
