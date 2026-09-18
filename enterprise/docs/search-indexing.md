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
No entity lifecycle or search read is enabled by the infrastructure alone.

