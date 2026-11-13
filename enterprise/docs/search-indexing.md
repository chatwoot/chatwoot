# Conversation search indexing

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
No entity lifecycle or search read is enabled by the infrastructure alone.

Backlogged streams rotate behind streams still awaiting a turn, so the bounded
dispatch page does not repeatedly select the same accounts.

Enable the default-off `conversation_search_indexing` account flag to index
conversation identity, inbox, activity timestamps, email subject, and associated
contact search fields. Cloud also requires `advanced_search_indexing`.
This does not index contacts or change contact search.

Message activity and silent historical imports explicitly submit committed
conversation IDs. Contact identity edits/deletions refresh dependent conversation
documents in resumable pages of 500. Contact activity-only changes do not fan out.
The `contact_conversations` buffer stores dependency work, not contact documents.

## Conversation backfills and recovery

Keep `conversation_search_indexing` enabled before starting a backfill. Run
`bundle exec rails search:backfill ACCOUNT_ID=123` for a canary account, or omit
`ACCOUNT_ID` to schedule eligible accounts in pages of 25. `ENTITY=contacts`
is unsupported. Use separate `search_backfill` workers so rebuilds cannot
consume the live-indexing worker capacity.

Each account persists a run token, generation, cursor, counters, and readiness.
Pages contain at most 500 records; producers pause above 2,000 pending IDs.
Source verification repairs missing/stale documents; an index sweep removes
orphans. Readiness requires a drained queue, successful refresh, complete
verification responses, and no permanent item failures. Reconciliation runs
daily. Account deletion starts a purge even when live indexing ran without a
backfill, and uses the current generation.

- Inspect: `bundle exec rails search:indexing_status ACCOUNT_ID=123`
- Pause: `bundle exec rails search:pause_backfill STATE_ID=1`
- Resume: `bundle exec rails search:resume_backfill STATE_ID=1`
- Repair the cause of permanent errors, then run
  `bundle exec rails search:retry_failed_writes STATE_ID=1 CURSOR=0` until the
  returned cursor is zero; resume the backfill afterward.

An epoch/schema change requires restarting the backfill. Never mark an account
ready manually. These commands schedule work; deploying the PR does not start
production backfills. Redis epoch rotation makes old indices inaccessible to
current readers; operators must remove retired indices under the deployment's
data-retention policy.

## Conversation search rollout

After a canary backfill is ready, enable the separate default-off
`conversation_search` flag. Only global conversation search and its count use
this path. Contact search, message search, and conversation-list message-body
search retain their existing backends.

OpenSearch supplies all candidates (up to 1,000), then the existing SQL relation
applies current tenant/inbox/custom-role permissions, substring matching, time
filters, ordering, counts, and pagination. The projection includes email subject
alongside contact identity and conversation number. Counts and page sizes follow
the existing API. A valid empty engine response remains empty.

Unsupported queries (shorter than three characters, longer than 256, non-ASCII,
or containing SQL wildcard/escape characters), broad matches, partial responses,
unready generations, pending work older than two minutes, permanent failures,
and known transport failures fall back to SQL. Missing physical indices
invalidate readiness before recreation. This is eventually consistent search;
the healthy path may lag until the next flush and refresh.

Monitor `search.search_indexing`, `fallback.search_indexing`, buffer age,
pending/failed counts, and backfill progress. Disable `conversation_search` for
immediate SQL rollback while keeping writes active. Disabling indexing makes
readiness stale and requires a backfill before reads resume. Start with one
account, compare results/counts and latency, then expand gradually. Do not enable
reads globally or run production backfills as part of deployment.
