# Production Reliability for Implementation and Review

Use the sections relevant to the behavior being changed. A small UI or copy change does not require a production benchmark, rollout plan, or another reviewer. Apply these checks when the actual caller, workload, persisted state, or deployment makes the failure possible.

Use existing evidence and representative local data where practical. Record assumptions, data shape, and unverified limits.

## 1. Trace the behavior that will run

- Name the changed contract and follow its entry points, source of truth, side effects, and consumers. Include relevant OSS/Enterprise behavior, background jobs, APIs, and supported clients.
- A new caller, default, callback, serializer field, or feature activation can make an unchanged helper a source of regressions. Inspect the old code reached by the new path.
- Preserve documented legacy configurations and valid provider payloads. Distinguish compatibility with supported states from coercing malformed input.
- For a stack of PRs, identify the assembled commits and carry deferred concerns into the wiring or activation change. A foundation PR being safe while unused does not establish that the activated feature is safe.

## 2. Keep reads and disabled features inexpensive

- Where boolean configuration is valid, distinguish `false` from missing. Exercise configured, disabled, and absent values, including repeated reads and warm/cold cache behavior.
- Check that frequent reads do not repeatedly create configuration, run migration logic, write records, or invalidate shared caches.
- Inspect the disabled path through serializers, callbacks, jobs, APIs, and providers. A hidden UI or false flag does not prove that the feature adds no work.
- Keep expensive optional derived behavior independently disableable when its failure should not take down an established core flow. Do not conceal invalid required configuration; handle only failures that are realistic and have a defined product behavior.

## 3. Bound work and contention

For hot requests, listeners, invalidation, broadcasts, bulk operations, or retries, estimate the relevant multiplication:

`events per second × affected recipients/items × work per item × refresh/retry multiplier`

Use supported or measured bounds. Identify the relevant SQL queries, Redis round trips, provider calls, queued jobs, and lock/connection hold time. A useful estimate explains where work is capped and what happens at that cap.

- Redis `SCAN MATCH` filters returned keys but still traverses the database keyspace. A narrow prefix is not a bound on scan work. Replacing `KEYS` with `SCAN` does not make frequent full scans cheap.
- Trace cache invalidation together with the next miss, rebuild, and client refetch. A build lock prevents some duplicates but does not make one synchronous rebuild bounded or stop an invalidation/rebuild loop.
- Include provider callbacks, event subscribers, and frontend refreshes in fanout calculations.
- Check shared-row locks and database connections held across network calls, additional threads, and retries. More workers can increase contention instead of throughput.
- Enforce eligibility before scanning or enqueuing. A zero-eligible-recipient case should not repeatedly perform account-wide work.

## 4. Validate database behavior at the relevant scale

- Inspect the exact generated query and index column order for the affected role and filter paths. Administrator queries can differ substantially from inbox-scoped agent queries.
- Use representative tenant size and skew: historical versus active records, selective versus broad predicates, and relevant `LIMIT`, ordering, count, and join variants.
- Where scale is material, use query plans and timing evidence with the data shape and environment stated. Compare cold/warm behavior when activation or cache eviction makes it relevant. An index existing or a test passing on a small database is not capacity evidence.
- For identity/model changes, verify ownership, uniqueness scope, concurrent writes, and existing-record compatibility. Follow the repository's migration and deletion guidelines.
- For migrations, restores, or database upgrades, verify physical indexes and required backfills; schema migration history alone is insufficient. Include per-tenant sequences/objects, planner statistics, connection recovery, and cutover time when the operation affects them.

## 5. Test temporal state and recovery

- Review sequences, not only individual invocations: `failure → success → failure`, token expiry/refresh, disable/re-enable, retry after partial completion, and new events arriving while work is held.
- Distinguish consecutive failures from cumulative history. A success should reset a failure streak when that is the intended contract. A stopped operation must not also be the only path capable of recovering itself.
- A quota hold must remain effective when new messages/events arrive. Bound scheduled wakeups per logical work item. Include direct and delayed enqueue paths; a dispatcher batch limit may not cover them.
- For daily/monthly resets, verify bounded release and shared-lock contention. Jitter spreads work but does not deduplicate it or establish a throughput limit.
- Assert the required value or state. For example, a refreshed token must equal the new token; merely being different from the old token also accepts `nil`.

## 6. Exercise real boundaries and clients

- For authentication and rate-limit changes, send the actual supported request format through the parsing and middleware chain. For JSON auth, include independent users and verify that missing identifiers cannot put them in a shared blank bucket.
- Distinguish issuance, enqueue, provider acceptance, recipient delivery, and successful use. A successful mailer call does not prove a mandatory verification email can reach the user. Verify realistic rejection, suppression, quota exhaustion, and recovery behavior when affected.
- For provider signature, identity, or URL handling, exercise authentic payload variants and existing installation configurations as well as malicious requests. Check real redirect behavior where downloads depend on it.
- For material frontend behavior, verify the real route and affected loading/error/empty states. Exercise overlapping requests, component reuse/navigation, and supported older clients where relevant. Use shared cancellation and stable component identity; do not infer success from component tests alone.

## 7. Include existing state in rollout and rollback

- For a risky activation, identify the affected population, representative large tenant, cold-start or clock-boundary case, and observable product success/failure signal.
- Record what disabling or reverting the change actually stops. Account for old workers/clients, scheduled jobs, persisted flags, cached counters, and partial writes.
- Name necessary cleanup, reconciliation, or backfill, including any lookback limit that could lose coverage during an outage. A code rollback does not itself repair state written by the previous version.
- Carry material unverified scale or recovery assumptions into the handoff and verdict. Keep operational requirements proportionate to the change.

## 8. Close findings with evidence

For each material finding, record the failure scenario, reviewed commit, disposition, and evidence. Recheck each causal claim in a compound finding; fixing one branch may leave the original failure possible.

| Disposition          | Required basis                                                                                                                   |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Fixed                | The original scenario is prevented on the reviewed head, supported by a focused test, reproduction, or trace of the invariant.   |
| Not applicable       | Evidence that the scenario cannot occur on a supported path, or an explicit product decision establishing the intended behavior. |
| Accepted risk        | Explicit acceptance with an owner, rationale, mitigation, and follow-up or activation condition.                                 |
| Open / needs recheck | The failure remains or the evidence is insufficient. A resolved/outdated GitHub thread does not change this.                     |

- Check all findings, including pasted or AI-assisted feedback, against the correct PR, file, and commit. Comments and tests can both encode the same incorrect assumption.
- Keep the verdict consistent with the disposition. Do not describe an unresolved issue as blocking while marking the change approved.
- If the reviewed head changes, inspect the delta and recheck affected findings before finalizing. An approval on a prior head and green CI are evidence inputs, not proof that the latest behavior is safe.
- Keep review-only tasks read-only unless changes are requested. Report missing validation honestly rather than presenting unexecuted checks or reviewer claims as personal verification.
