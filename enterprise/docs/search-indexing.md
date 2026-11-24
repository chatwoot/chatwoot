# Conversation search indexing

Tracking: [CW-7523](https://linear.app/chatwoot/issue/CW-7523/opensearch-support-for-conversations).

## Live indexing

Run `bundle exec rails search:setup_conversations` to create the conversation index,
with OpenSearch configured. The `advanced_search_conversations` feature is enabled
by default for new accounts and enabled for existing accounts by migration. Every
conversation document includes `account_id` and `contact_id`. Contact details are
excluded; contact indexing is a separate feature. Activity timestamps remain available
for the planned conversation-filter migration.

Searchkick 5.5.2 owns the Redis ID queue and bulk jobs. Committed writes add IDs to
`Conversation.search_index.reindex_queue`; a scheduled job invokes Searchkick's
`ProcessQueueJob` every 30 seconds. It deduplicates each page and creates native
`ProcessBatchJob` jobs. Run workers for `async_database_migration` (and the configured
Searchkick queue if overridden). Queue delay and engine refresh add to visibility
latency; 30 seconds is a scheduling interval, not a guarantee.

Searchkick shares Alfred's existing Redis connection pool and its size/checkout timeout.
A small adapter yields the checked-out raw client because Searchkick uses raw commands
and its own `searchkick:` key prefixes. Alfred's other callers retain their `alfred:`
namespace. No additional pool or queue-key migration is needed; search queue traffic
shares the pool's connection capacity with existing Alfred operations.

Inspect pending IDs with `Conversation.search_index.reindex_queue.length`, and
monitor normal Sidekiq queue latency, retries and dead jobs. There are no custom
Redis leases, Lua scripts, throughput thresholds or external-version counters.
Searchkick uses current primary records when jobs run and removes missing records.
Contact edits and CSV contact imports do not enqueue conversation indexing.
Conversation contact-ID changes (including merges), message activity and historical
conversation imports capture the corresponding conversation updates. Deletes still enqueue cleanup when
an account's writer flag has been disabled.

## Lifecycle and recovery

Setup is explicit and never clears an existing index. The scheduled drain leaves
IDs queued when the index is absent; normal application writes do not provision it.
Do not delete/recreate an active index while jobs are running. Disable search reads,
quiet indexing workers, provision/rebuild, and populate before restoring reads. Disable
OpenSearch automatic index creation for the conversation index in production so
already-enqueued bulk jobs cannot recreate an empty, incorrectly mapped index.

Searchkick's queue is best effort: it removes IDs before scheduling a bulk job, so
process death in that interval can lose an update. A database commit followed by a
failed Redis enqueue has the same need for repair. Ordinary job exceptions retry in
Sidekiq; concurrent bulk jobs can finish out of order. This implementation deliberately
uses Searchkick's behavior rather than recreating a reliable queue around it. Recover
with a backfill/rebuild; a missing match cannot be recovered by SQL authorization.

Message activity updates run before the database transaction commits, but search IDs
are queued only after all surrounding transactions commit. Rolled-back messages do
not enqueue. Redis errors and connection-pool checkout timeouts are captured through
`ChatwootExceptionTracker` inside the enqueue callback so message delivery and later
callbacks continue. The missed index update still requires reindexing for recovery.

Before a code rollback, disable producers and drain/cancel this feature's queued,
scheduled and retry jobs while their classes are available. Retain the index until
its retirement is explicitly scheduled. Deployment enables live indexing when OpenSearch
is configured; historical records require an explicit account reindex. Search reads
remain on PostgreSQL until the later reader PRs are deployed.

## Reindex one account on demand

From the production Rails console:

```ruby
SearchIndexing::Conversations.reindex_account(123)
```

Or from a shell:

```sh
bundle exec rails search:reindex_conversations ACCOUNT_ID=123
```

This uses Searchkick's account-scoped `reindex(mode: :async)`. Searchkick scans IDs
in 500-record batches and enqueues its own `BulkReindexJob` for each batch, targeting
the existing shared index. The console/task must stay connected until scheduling
finishes; the bulk jobs continue in Sidekiq afterward. No full-model reindex, index
replacement, custom backfill job, verification scan or repair loop is involved.

There is no account ready/reindexed marker, completion timestamp or activation step.
The command returning means jobs were scheduled, not that every bulk write finished.
Use normal Sidekiq queue/retry/dead-job monitoring. Rerunning the command reindexes
current account records; it does not audit or delete historical orphan documents.
Live callbacks continue to handle new updates and deletions. If scheduling is
interrupted, rerun the account. Native batch jobs retry failures normally.

Run accounts individually at a rate appropriate for worker and OpenSearch capacity.
The native async operation can enqueue many jobs; batch size does not cap total jobs
or worker concurrency. This PR still leaves all search reads on PostgreSQL.

## Conversation search reads

After the search PR is deployed, supported queries use OpenSearch whenever it is
configured and `advanced_search_conversations` is enabled. There is no readiness
check or per-account activation. A partially populated index can return incomplete
historical results until the account reindex jobs finish; deployment does not wait.

OpenSearch matches conversation display IDs and subjects. Contact name/email/phone/
identifier matching remains an account-scoped SQL subquery until contacts are indexed
separately. SQL combines these matches and checks current tenant/inbox access,
matching, dates, order and pagination. Contact edits take effect without reindexing.

ASCII substring queries of 3–256 characters without SQL wildcards or escapes use a
complete set of at most 1,000 engine candidates. Unsupported/broader queries and known
availability failures or partial responses use SQL. Valid empty engine results remain
empty for conversation-field matches. Contact and message search are unchanged.

Disable `advanced_search_conversations` to return an account to SQL; this also stops
ordinary live indexing. Reindex the account after reenabling to catch up on missed
updates. No timestamp or completion state is written to the account.
