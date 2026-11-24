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

Conversation search uses OpenSearch when it is configured and both
`advanced_search` and `advanced_search_conversations` are enabled. Otherwise the
existing PostgreSQL conversation/contact matching and pagination remain unchanged.
There is no readiness gate; historical conversation documents must be populated by
the account reindex operation before they can match.

Run `bundle exec rails search:setup_conversations` when deploying the reader. Setup
adds a `conversation_id` field alias pointing to the existing conversation `id`
field, including on an already-populated index. This is an additive mapping update;
existing conversation documents and the message index do not require a new backfill
for grouping. The existing advanced-search message index must be available.

One multi-index query matches conversation display IDs/subjects and the existing
message content, email subjects and transcripts. It groups hits by conversation ID,
selecting up to 10,000 candidates by their best OpenSearch `_score`, with conversation
ID as the tie-breaker. Global term statistics are requested across shards. A second
query counts matching messages for these candidates, using the same account, inbox,
text and message time-window conditions. It includes all candidate buckets on each
shard so counts are complete. Conversation documents do not contribute to the count.

The entire candidate window is reranked before pagination using
`best_score * (1 + min(0.5, 0.15 * ln(max(matching_message_count, 1))))`.
Zero or one matching message adds no bonus; two add about 10%, ten about 35%, and
the bonus caps at 50%. Conversation ID descending breaks equal adjusted scores.
Candidates outside the initial 10,000 remain excluded, even if their message count
could have promoted them. This is a relevance-selected window, not the global top
10,000 after the message-count bonus. Both queries rerun on each page; they transfer
at most 10,000 hits/count buckets but can examine many matching message documents.
Production latency and capacity need validation with representative tenant workloads.

Contact name/email/phone/identifier do
not contribute to this path; PostgreSQL only loads records and checks current tenant,
inbox/custom-role permissions and conversation activity dates. Contact and message
tabs retain their existing behavior. Message matching retains the configured message
search time window.

Ranked results show at most 25 conversations at a time, with Next results and Previous
results. Pagination covers the reranked candidate window. Current permission/date
checks may reduce the visible results within that window. SQL permission checks
use batches of at most 500 candidates and continue until the visible page is
filled or the window is exhausted; no intermediate empty batch is shown. The engine
search is never replaced by SQL text matching because a query is broad.

The conversation endpoint supplies `meta.has_more` and `meta.next_cursor`. Clients
send `conversation_cursor` for the next page, retaining prior page offsets to navigate
back. `page` is also supported as a ranked offset when a cursor is absent. Reset page
history on query/account/date changes. Rankings are live; index updates can move
matches between pages. There is no server-side search session or additional Redis state.

Known engine failures and incomplete responses return `meta.error: true`; the dashboard
shows a retryable error and keeps its current page. It never presents contact-only SQL
results or treats engine failure as a definitive empty result. Invalid mappings and
programming errors remain visible. Missing setup must be corrected operationally.

Disable either reader flag to restore legacy conversation search. Disabling
`advanced_search_conversations` also stops ordinary live conversation indexing; reindex
the account after reenabling to catch up. No account completion marker is written.

## Conversation filters

The filter PR adds status, priority and assignment/team fields to the document.
Run `bundle exec rails search:setup_conversations` to apply additive mappings, then
reindex accounts to populate the additional fields. Filtering starts using the index
for supported requests as soon as the PR is deployed and the account flag is on;
there is no mapping-version or backfill-completion gate. Until populated, filters
and counts can omit historical conversations.

The first slice supports administrators, with status, inbox, assignee, team,
priority and creation/activity conditions. AND/OR precedence, null handling,
human/bot assignment counts and date/timezone boundaries follow the existing API.
Creation/activity sorting supports the first 10,000 results. SQL checks selected
rows against current account ownership, permissions and filter conditions; stale
page candidates and known engine availability failures use the full SQL request.

Agents, custom roles, labels, custom attributes, unsupported sorts and deeper pages
keep the existing SQL path. Counts and matches retain normal indexing lag.
Disable the account flag to restore SQL reads and stop ordinary indexing.

Team/user/bot/Captain deletion and bulk agent removal can bypass conversation
callbacks. Their account-scoped refresh jobs scan old indexed references in bounded
pages and use Searchkick to load current records. User and global-bot deletion
capture affected account IDs and refresh them independently. These jobs maintain
live assignment changes; they do not audit coverage or mark accounts ready.
