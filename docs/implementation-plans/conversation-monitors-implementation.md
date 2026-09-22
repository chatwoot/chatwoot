# Conversation Monitors: implementation and rollout

Implemented on 2026-09-22, following the [approved plan](conversation-monitors.md). The feature is Enterprise-only and off by default. It is independent of Captain.

## Enable an account

1. Run `bundle exec rails db:migrate` in the deployment environment.
2. Set `TYPESAFE_API_KEY` in both Rails and Sidekiq environments. Restart the processes after changing environment variables.
3. Ensure workers consume `monitors_live` and `monitors_backfill`. The default Sidekiq configuration includes them. For a busy installation, dedicate bounded worker capacity to each queue. Keep the existing `scheduled_jobs`, `low`, and `critical` workers running for recovery and ActionCable delivery.
4. Enable `reports` and `conversation_monitors` on the intended account through Super Admin or Rails console:

   ```ruby
   Account.find(account_id).enable_features!('reports', 'conversation_monitors')
   ```

5. Open **Reports → Monitors** as an administrator. Preview a condition, create the monitor, and wait for its historical coverage to finish.

Administrators pause through `PATCH /api/v1/accounts/:account_id/monitors/:id` with `{ "paused": true }`. Repeating the request keeps the original pause timestamp. Historical charts and administrator drilldowns remain available; retry is disabled while paused. Source deletion and redaction still remove affected data.

Paused monitors have a Resume action with two choices:

- **Check the paused period** scans conversations created or receiving public customer messages between the pause and resume timestamps, including replies on older conversations, then continues live collection.
- **Start from now** starts live collection without scanning that interval. The report identifies the gap in coverage.

Both choices preserve completed results on the same monitor. Resume uses `POST /api/v1/accounts/:account_id/monitors/:id/resume` with `mode` (`catch_up` or `from_now`) and the integer `collection_version` returned by the monitor API. Stale requests receive `422 monitor_changed`; the UI refreshes the monitor. Resuming also rechecks the account's active-monitor limit. Work left unfinished before the pause is discarded; catch-up only requests the selected paused interval. An interrupted initial historical scan therefore remains marked incomplete.

Disabling `conversation_monitors` hides the API and stops evaluation. Durable incoming work is retained for accounts with active monitors, so reenabling catches up. Pause an individual monitor to stop collecting while keeping its results. Its default chart and seven-day card count stay anchored to the pause time. Queued work skips paused monitors, and responses from calls already in flight cannot add results after the pause. Delete hides it immediately; scheduled cleanup removes its derived rows. Neither operation deletes source conversations.

## Product contract

- Initial history includes conversations **created** in the preceding rolling seven days. All statuses are eligible.
- Each conversation counts once per monitor, in its **creation-time** bucket. A conversation can match several monitors. A later message can update an earlier bar.
- New public customer messages trigger reevaluation for unmatched monitors. Existing matches are sticky. Public agent replies provide context. Private notes, activity messages, and deleted content are excluded.
- Public-content edits, redaction, and message deletion invalidate existing decisions before reevaluation. Conversation deletion cascades derived records and invalidates the report revision.
- Edit changes the name and description (the matching condition). A changed condition atomically clears prior decisions, advances the collection version to reject stale provider results, and queues previously checked conversations for evaluation again. Skipped conversations and historical coverage gaps remain skipped. A durable recheck marker lets dispatch recover failed enqueueing; paused monitors defer this work until resume, including future-only resume. Name-only edits preserve results. Model, threshold, and context version stay fixed. Duplicate, pause, resume, and delete are also available as header icons with tooltips and accessible names. Archived monitors remain readable, but their conditions cannot be changed.
- Existing report viewers can see aggregate charts. Only account administrators can preview, create/manage monitors, or drill down.
- Hour, six-hour, and day buckets use an explicit IANA timezone, including daylight-saving transitions. Chart and drilldown share half-open boundaries. A stale drilldown gets `409 data_changed` and the UI refreshes.
- The date picker offers 7-day and 30-day presets plus a custom range of 7–30 calendar days inclusive. It automatically uses the account reporting timezone, then the general account timezone, then the user's browser timezone. The timezone selector is hidden. The account API normalizes Rails timezone names to IANA identifiers for browser date calculations.
- Historical results are retained until monitor or source deletion, or until a description change replaces them through reevaluation. Individual report requests are bounded to 366 days and 744 buckets. Ranges before the initial scan visibly indicate incomplete coverage.
- The graph has no separate progress card. Paused/scanning states and actionable errors appear as compact text beside the chart, with Retry available for administrators. One short coverage note appears below the chart when the selected range includes periods that were not fully checked.

## Configuration and evaluation

| Setting | Default | Purpose |
| --- | --- | --- |
| `TYPESAFE_API_KEY` | Required | Server-side bearer credential; never sent to the browser |
| `TYPESAFE_MODEL` | `jev-1.13.0` | Model pinned on newly created monitors |
| `CONVERSATION_MONITORS_LIMIT` | `20` | Maximum active monitors per account |
| `CONVERSATION_MONITORS_ATTRIBUTES` | Empty | Comma-separated allowlist of contact/conversation custom attribute keys |
| `CONVERSATION_MONITORS_DAILY_TOKEN_LIMIT` | `20000000` | Daily UTC allowance per account |
| `TYPESAFE_REQUESTS_PER_MINUTE` | `600` | Shared installation request limit |

The per-account limit is 60 provider requests per minute. Preview checks at most five recent conversations and is limited to one request per administrator every 30 seconds. The form shows the remaining cooldown and automatically re-enables Preview when it expires, including after condition edits or reopening the dialog. A request during another tab's cooldown receives `429 preview_rate_limit` with the remaining `retry_after` and `Retry-After` header, distinct from evaluation capacity failures. Its result IDs are kept in shared Redis for 15 minutes; each read loads current account-scoped conversation data, so deleted conversations and cached pre-redaction text are not returned. Duplicate deliveries of completed preview jobs do not call Jev again.

Set attribute keys before enabling the pilot. For example, `CONVERSATION_MONITORS_ATTRIBUTES=deployment_type` lets Jev use a customer's known hosting type. Otherwise, hosting type must be supported by the public conversation. Do not put arbitrary secrets or internal notes in the allowlist.

The Ruby client uses the existing Faraday dependency and Jev's Noul primitive. It batches up to eight independent conditions per request. New monitors use threshold `0.65`; each evaluation stores its actual returned model and score. A context version is persisted with the monitor. Changing the shared context builder or attribute allowlist is an operator change that requires reevaluating quality; automatic migration of existing cohorts is not included.

Context is read in bounded database pages and conservatively limited to 28,000 serialized bytes. The complete request is limited to 60,000 bytes. Oversized or textless conversations produce visible exclusions, never silent negative decisions. No new transcription or attachment parsing is performed; existing textual attachment context is used when available.

Redis atomically checks and reserves the global request, account request, and conservative byte-based token allowances before each request, then reconciles successful calls to reported input tokens. Rejected reservations do not consume another allowance. Failed/unknown calls retain their reservation. Missing/invalid credentials, invalid requests, and permanent context exclusions require attention. Transient failures retry with bounded exponential delay and jitter; rate/budget suspension resumes after capacity is available. Administrators can retry unfinished evaluations.

## Persistence and recovery

PostgreSQL is authoritative:

- `conversation_monitors` stores account-owned definitions and report revisions.
- `conversation_monitor_evaluations` stores one decision per monitor/conversation.
- `conversation_monitor_backfills` stores the resumable historical cursor.
- `conversation_monitor_work_items` stores per-conversation input revisions, generation, due time, and fenced worker leases.
- `conversation_monitor_resumptions` records each resume choice and paused interval, with a durable cursor for catch-up and cancellation markers for interrupted scans.

Pause and resume increment the monitor's collection version. Queued scans and in-flight provider responses from an older version cannot add matches after resumption. Explicit scan requests carry the target monitor/version; shared conversation work also stores its actual incoming-activity time so another monitor's scan cannot make a future-only monitor process older activity. Catch-up jobs use the backfill queue and the minute dispatcher recovers missed enqueue attempts. A scan locks all of its conversation work rows before locking the monitor, matching live evaluation's lock order.

Message changes record durable work within the source transaction. A commit callback catches monitor activation that occurred after message creation began. The Enterprise import hook also schedules completed conversation imports, since bulk imports intentionally bypass Message callbacks. Provider calls run outside database locks. Result writes check lease/generation and monitor eligibility, preserving newer pending input and rejecting stale redaction results. Workers enqueue follow-up work; the minute dispatcher recovers interrupted/enqueue-failed jobs and unfinished backfills. Creation still returns the saved monitor when its initial enqueue fails. Each provider batch checks current feature eligibility and the work generation/lease before sending context.

Monitor update events send only `account_id`, `monitor_id`, and `data_revision` through ActionCable, to users currently authorized by ReportPolicy. Both the monitor list and graph also listen for the active account's `conversation.created` and `message.created` events. They refetch authoritative counts immediately for initial activity and again when evaluation results arrive, coalescing bursts into a two-second window that preserves the final refresh. Broadcast jobs release their coalescing key before reading the latest revision so a later result can schedule another update. The browser also refreshes on focus, reconnect, and every 30 seconds while visible. It does not increment local counts from websocket payloads. Hidden tabs defer refreshes, and navigation removes listeners and suppresses pending callbacks. Drilldowns retain the displayed chart request while a refresh is pending; changed revisions or rolling bucket populations close the drawer. Account/monitor navigation cancels requests and clears the previous chart.

Monitor usage emits `evaluation.conversation_monitors` notifications containing account ID, actual model, question count, reported input tokens, and duration. Operational dashboards/alerts and billing integration are not included. Inspect durable due times and evaluation error codes to diagnose backlog.

## Validation

The implementation was exercised against isolated PostgreSQL and Redis databases with synthetic data only:

- 556 RSpec examples passed, including 63 monitor examples and existing account, message, conversation, report policy/controller, schedule, and expanded Intercom/Freshdesk import coverage. OpenSearch was disabled for this local run so unrelated search callbacks could not contact the configured external cluster.
- 36 Vitest tests passed, including seven chart-refresh, navigation, pause, and resume regression tests and existing report drilldown, conversation card, chart, and ActionCable coverage.
- Production Vite build passed. Ruby lint passed; frontend lint has no errors (existing dynamic-translation rule warns on computed keys in the new views).
- Deterministic integration probes covered backfill, independent multi-monitor decisions, sticky positives, negative reevaluation, duplicate execution, a message arriving during evaluation, commit-after-activation catch-up, generation fencing, redaction/deletion, feature disable/reenable, authorization, preview, invalid/stale drilldowns, and DST/fractional-offset buckets.
- Failure probes covered 429 with Retry-After, invalid credentials, partially missing answers, private-note edits, disabling the feature during a provider request, and long-context exclusions.
- Resume regression coverage includes both modes, old conversations receiving new replies, private/agent message exclusion, existing matches, stale administrator actions, enqueue recovery, late message commits, account limits, repeated pause/resume cycles, shared work across monitors, interrupted catch-up coverage, and an in-flight result arriving after pause and resume.
- Browser verification covered the empty landing page, preview, creation, historical counts, admin drilldown, live incoming updates, grouping controls, and a 390-pixel mobile layout. The updated preview and drilldown paths were rechecked after the regression fixes. Pause was also exercised in the local app: an incoming message and a new conversation scheduled no monitor work, four existing matches remained unchanged, and the paused chart retained administrator drilldowns.
- Both Resume choices were exercised through the local browser with real Jev evaluations and background workers. Catch-up added a missed match, increasing the count from four to five. A later future-only resume preserved five matches and skipped a newly created paused-period conversation; a fresh customer message after resuming then matched it and updated the chart to six. The skipped interval remained visibly marked incomplete.
- The preview cooldown fix passed 21 focused backend API/usage examples and 12 form/report frontend tests. Browser verification covered successful refund and WhatsApp BSUID previews, the visible countdown, and automatic button re-enablement. Ruby and frontend lint had no errors, and the production build passed.
- The realtime refresh changes passed 37 frontend tests and 21 focused backend broadcast/evaluation examples, with clean lint and a successful production build. A local conversation produced both creation events, each burst triggered an immediate and final report refresh, and evaluation completion produced a further websocket-triggered refresh. The visible count increased from seven to eight without a manual reload. Tests also cover foreign-account events, hidden tabs, reconnects, and navigation during a pending refresh.
- A real Redis concurrency probe admitted exactly five of ten simultaneous attempts at a configured five-request limit and reserved exactly 500 tokens; denied requests consumed no shared capacity.
- A PostgreSQL concurrency probe held a conversation work row in a live transaction while catch-up waited for it. Live work could still acquire the monitor lock and finish, after which catch-up completed; all probe writes were rolled back.

The opt-in benchmark is reproducible with:

```sh
bundle exec rails runner script/conversation_monitors/benchmark.rb
bundle exec rails runner script/conversation_monitors/benchmark.rb script/conversation_monitors/holdout.json
```

After calibrating the threshold on 12 synthetic conversations, all 36 condition decisions on a separate 12-conversation holdout matched their labels. The final calibration rerun also passed 36/36. Calibration and holdout consumed 5,866 and 5,924 input tokens respectively; observed individual calls took 0.165–0.326 seconds. These are small synthetic checks, not measured production precision/recall or load guarantees. A representative authorized pilot dataset and real queue-capacity measurements remain necessary before broad rollout.

A local query probe with 10,000 memberships and 169 hourly buckets returned the exact expected chart and drilldown counts. With current PostgreSQL table statistics, aggregation took about 7 ms (23 ms including bucket construction); `EXPLAIN ANALYZE` confirmed about 6 ms. Fresh bulk fixtures with stale statistics selected a poor nested-loop plan, so keep normal PostgreSQL autovacuum/analyze enabled. This small local probe is not a production-scale throughput guarantee.
