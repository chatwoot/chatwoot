# Delayed Automations — Time-Based Automation Rules

**Status:** Design approved, pending implementation
**Target:** July 15 release
**Owner:** Tanmay

**Key decisions**
- Merged into existing automation rules (same model, same UI, same API) — not a separate
  feature or a special rule type. Delay is an optional property (`execution_delay`).
- No future-scheduled Sidekiq jobs — DB `due_at` + the existing 5-minute cron sweep
  (`TriggerScheduledItemsJob`), the same entry point SLA uses.
- Fire-time **re-check** of the rule's conditions is what gives "stayed in state for N hours"
  semantics; the episode guard (key recomputation) is what auto-cancels follow-ups when the
  customer replies.

---

## 1. Problem

Chatwoot automation rules are purely **event-driven**. A rule fires at the instant one of five
events occurs (`conversation_created`, `conversation_updated`, `conversation_opened`,
`conversation_resolved`, `message_created`) and never again. There is no way to express
*duration*:

- "If a conversation stays in status X for more than N hours → add a label"
- "If the end user doesn't reply within N hours → send a follow-up message"
- "If a conversation is open for more than N hours → add a label"

Nothing in the system wakes up N hours later to check. That is the gap this feature fills.

## 2. Goals

- Automation rules can be configured with a **delay**: "execute this rule N hours/minutes after
  the triggering event, if the conditions still hold."
- Covers the three customer asks above using **existing events, conditions, and actions**.
- Supported actions include at least **add label** and **send message** (both already exist).
- Fully backward compatible: existing rules keep behaving exactly as today.
- Safe at Chatwoot Cloud volume: load must scale with *pending delayed rules*, not raw event traffic.

## 3. Non-goals (v1)

- **Per-action delays / multi-step sequences** (wait 24h → message → wait 24h → label).
  v1 is one delay per rule. Sequences are a natural follow-up.
- **Exact-second firing.** Delays are hours-scale; firing within ~5 minutes of the due time
  is acceptable.
- **New duration condition attributes** (`hours_in_status`, etc.). The delay + re-check model
  covers the v1 stories without them; richer "time since X" anchors are Phase 2 — see
  `docs/time-based-automations-phasing-and-rollout.md`.
- **Recurring execution** (fire every N hours while the condition holds). v1 fires at most
  once per conversation per qualifying episode.

## 4. Core model: delay + re-check

The design rests on one insight:

> **"Has been in state X for N hours" ≡ "matched the conditions at T₀, and still matches at T₀ + N."**

So instead of building a new duration-condition engine, we:

1. Evaluate the rule's conditions at event time, exactly as today.
2. If the rule has a delay, **record a pending execution** due at `now + delay` instead of
   acting immediately.
3. When the due time arrives, **re-evaluate the same conditions** against the conversation's
   current state.
   - Still matches → run the actions.
   - No longer matches → discard silently. This is what makes the semantics correct: a
     follow-up message is automatically cancelled when the customer replies, a "stuck in
     pending" label is skipped if the conversation moved on.

Everything downstream — `AutomationRules::ConditionsFilterService`,
`AutomationRules::ActionService`, all existing actions — is reused unchanged.

### Not a special type of rule

A delayed rule is **not** a new rule type — no STI, no new class, no new `event_name`. It stays
a plain `AutomationRule`; the only difference is whether `execution_delay` is set:

```ruby
rule.execution_delay # => nil  → executes immediately (today's path)
rule.execution_delay # => 240 → records a pending execution due in 4 hours
```

Why a property beats a type:

- Any existing rule can become delayed (and back) by setting one field, without recreating it
  as a different kind of object.
- The listener branch is a single `if` at the point where actions would run; everything
  upstream (rule lookup by account+event, condition evaluation) is identical for both paths.
- The UI stays one form. A separate type would mean a type picker, separate list filters, and
  separate API handling — ceremony with no behavioral payoff.

The only places it *acts* special are the rule-list badge ("runs after 4h") and the fire-time
guard chain — both driven off the field, not a type.

### Why not Sidekiq `perform_in`?

The obvious implementation (enqueue a future Sidekiq job per matching event) is wrong at our
volume:

- `conversation_updated` fires on nearly every touch. Each match would push a job into Redis'
  scheduled set, where it sits for **hours to days**. Redis bloats and the scheduled-set poller
  degrades. Work scales with raw event volume — the worst thing to couple to.
- Cancelling/deduping scheduled Sidekiq jobs is awkward (no efficient lookup by
  rule+conversation).

Instead we use the pattern Chatwoot already uses for snooze, auto-resolve, campaigns, and SLA:
**store a `due_at` in Postgres and sweep due rows from the existing 5-minute cron**
(`TriggerScheduledItemsJob`). One indexed row per pending (rule, conversation) pair, a bounded
`WHERE due_at <= now` range scan, Redis untouched.

## 5. Architecture

### 5.1 Data model

**`automation_rules.execution_delay`** — new integer column, delay in **minutes**.
`NULL` (default) = execute immediately, i.e. today's behavior. No backfill needed.

**`automation_rule_pending_executions`** — new table (name TBD):

| Column | Type | Notes |
|---|---|---|
| `automation_rule_id` | bigint FK | rule to execute |
| `conversation_id` | bigint FK | target conversation |
| `account_id` | bigint FK | for scoping/cleanup |
| `due_at` | datetime | `event_time + rule.execution_delay` |
| `episode_key` | string | identifies the qualifying episode (see §5.3) |
| `status` | enum | `pending` / `processing` / `executed` / `skipped` |
| timestamps | | |

Final schema (incl. the `message_id` anchor, `skip_reason`, and the `processing` claim
state) is in the implementation plan, Phase 1c.

Indexes:
- `(status, due_at)` — the sweep query.
- Unique `(automation_rule_id, conversation_id, episode_key)` — dedup: repeated events for the
  same episode collapse into one row. For status- and waiting_since-anchored episodes the
  clock is **not reset**; outgoing-anchored (reply-chase) episodes update `due_at` to track
  the latest agent reply (impl plan, locked decision #4).

**`conversations.status_changed_at`** — new datetime column, set on every status transition
(hooked into the existing status-change path on `Conversation`). Serves two purposes:
- It is the `episode_key` source for status-based rules, so "entered open → left → re-entered
  open" counts as a *new* episode with a fresh timer.
- Lets the fire-time check confirm the status held continuously, not just coincidentally at
  both endpoints.

### 5.2 Event-time flow (write path)

Inside the existing `AutomationRuleListener` path — no new events:

```
event fires
  └─ for each active rule matching (account, event_name):
       ConditionsFilterService.perform
         └─ matched?
              ├─ rule.execution_delay.nil?  → ActionService.perform   (unchanged, today's path)
              └─ rule.execution_delay set   → upsert pending execution
                                              due_at = now + delay
                                              (unique index ⇒ one row per episode; clock NOT
                                               reset — except outgoing-anchored reply-chase
                                               episodes, which update due_at to track the
                                               latest agent reply)
```

### 5.3 Episode semantics — "don't reset the clock"

`conversation_updated` fires on every touch. For a rule like *"status = pending for 4 hours"*:

- First event where conditions match → pending row created, `due_at = entered_pending_at + 4h`,
  `episode_key = status_changed_at`.
- Every subsequent update while still pending → same episode key → upsert no-ops. The timer
  keeps counting from when the conversation *entered* the state.
- Conversation leaves pending, later returns → new `status_changed_at` → new episode → fresh
  timer. The old pending row is discarded at fire time by the re-check.

For message rules the anchor depends on the triggering message's direction (impl plan,
locked decision #4): *outgoing-anchored* (customer went quiet) keys on the latest incoming
message id, with `due_at` tracking the latest agent reply; *incoming-anchored* (agent went
quiet) keys on `waiting_since`, which Chatwoot clears on agent/bot reply — so the reply
cancels the pending action via the episode guard.

### 5.4 Fire-time flow (sweep)

Hooked into the existing **`TriggerScheduledItemsJob`** (every 5 minutes, `config/schedule.yml`
→ `trigger_scheduled_items_job`, cron `*/5`) — the same entry point SLA piggybacks on. Note:
SLA does *not* run every minute; it also rides this 5-minute job.

```
TriggerScheduledItemsJob (cron, */5)
  └─ AutomationRules::TriggerPendingExecutionsJob
       └─ PendingExecution.pending.where(due_at: ..Time.current)
            .find_each → ProcessPendingExecutionJob (per record):
              1. rule still exists & active?          no → mark skipped
              2. conversation still exists?           no → mark skipped
              3. episode still current? (anchor unchanged)
                                                      no → mark skipped
              4. ConditionsFilterService still true?  no → mark skipped   ← the re-check
              5. ActionService.perform → mark executed
```

**Same pattern as SLA, but flatter.** SLA needs a 3-level fan-out
(`TriggerSlasForAccountsJob` → per-account `ProcessAccountAppliedSlasJob` → per-record
`ProcessAppliedSlaJob`) because it must *recompute* deadlines from conversation timestamps on
every pass — it doesn't know in advance when a breach will happen. We do know: `due_at` is
precomputed at event time. So we skip the per-account fan-out entirely:

- One global indexed range query on `(status, due_at)`. The table only contains rows that are
  actually waiting — accounts with no delayed rules contribute zero rows, zero cost.
- Per-record jobs for the actual execution (guards + re-check + `ActionService`), so one slow
  or failing conversation doesn't block the batch — this part mirrors
  `Sla::ProcessAppliedSlaJob` exactly.

**Why 5-minute cadence is enough.** Delays are hours-scale ("4 hours", "24 hours"); worst case
a rule fires 5 minutes late, which is invisible at that scale. A 1-minute cadence would buy
precision nobody asked for at 5× the cron load. If tighter precision is ever needed, the fix is
cadence-only — one line in `schedule.yml` — with no design change.

Notes:
- `Current.executed_by = rule` is set exactly as in the immediate path, so events emitted by the
  delayed actions are recognized as automation-performed and don't retrigger rules (loop guard).
- Executed/skipped rows are kept 30 days (audit trail / incident blast-radius queries — impl
  plan locked decision #7), pruned by the daily scheduled job.

### 5.5 Volume characteristics

| Concern | Answer |
|---|---|
| Redis scheduled-set growth | Zero — no future jobs enqueued |
| Write amplification from update storms | Collapsed by the unique episode index (1 row per rule×conversation×episode) |
| Sweep cost | Indexed range scan on `(status, due_at)`; scales with count of *due* rows, not traffic |
| Accounts without delayed rules | Zero cost — no pending rows are ever created |
| Firing precision | Within the 5-min cron window; fine for hours-scale delays |

### 5.6 Frontend

In the Add/Edit Automation Rule dialog, below Event (per the mockup):

```
Execute   ( • ) Immediately
          (   ) After a delay:  [ 4 ] [ hours ▾ ]
```

- Stored as minutes in `execution_delay`; UI offers minutes/hours/days units.
- Shown for all existing events — no new event types in the dropdown.
- Rule list row shows a badge like "runs after 4h" for delayed rules.
- Changes: `AutomationRuleForm` + `constants.js` untouched for conditions/actions;
  `automation.json` i18n additions; API strong params + jbuilder gain `execution_delay`.

## 6. User stories & expected behavior

### Story 1 — Label conversations stuck in Pending

> *As an admin, I create: Event = **Conversation Updated**, Condition = **Status equals Pending**,
> Delay = **4 hours**, Action = **Add label `stale-pending`**.*

| What happens | Behavior |
|---|---|
| Conversation moves to Pending at 10:00 | Rule matches → pending execution created, due 14:00 |
| Agent adds a private note at 11:30 (another `conversation_updated`) | Same episode → no new row, **clock not reset**, still due 14:00 |
| Conversation still Pending at 14:00–14:05 sweep | Re-check passes → label `stale-pending` added |
| — or — conversation was resolved at 13:00 | Re-check fails at 14:00 → nothing happens, row marked skipped |
| Conversation reopens and goes Pending again next day | New `status_changed_at` → new episode → fresh 4-hour timer |

### Story 2 — Follow up when the customer goes quiet

> *As a support lead, I create: Event = **Message Created**, Condition = **Message Type is
> Outgoing**, Delay = **24 hours**, Action = **Send message** "Just checking in — did that solve
> it for you?"*

| What happens | Behavior |
|---|---|
| Agent replies to the customer Monday 15:00 | Pending execution created, due Tuesday 15:00 |
| Agent sends two more replies Monday 15:10 | Anchor updates → the follow-up tracks the latest agent reply |
| Customer replies Monday 18:00 | The reply changes the episode key; at fire time the episode guard sees it → **follow-up silently cancelled** (`episode_moved`) |
| Customer never replies | Tuesday ~15:00–15:05 → follow-up message sent to the end user, exactly once |
| The follow-up message itself is created | `Current.executed_by = rule` → does **not** re-arm the rule (no infinite follow-up loop) |

*(v1 note: whether the follow-up re-arms after each new agent reply, or fires once per
conversation, is decided by the episode key — default is once per "waiting" episode.)*

### Story 3 — Escalation label on long-open conversations

> *As an admin, I create: Event = **Conversation Created**, Condition = **Status equals Open**
> (optionally + Inbox = Support), Delay = **48 hours**, Action = **Add label `sla-risk`**.*

| What happens | Behavior |
|---|---|
| Conversation created Wednesday 09:00, still open Friday 09:00 | Label `sla-risk` added at the Friday ~09:00 sweep |
| Conversation resolved Thursday | Re-check fails Friday → no label |
| Conversation resolved Thursday, **reopened** Friday 08:00 | v1: original episode ended → no label from the old timer. (`conversation_opened` + delay can cover re-opens as a separate rule.) |

### Story 4 — Existing rules are untouched

> *As an existing customer, my current rules have no delay.*

| What happens | Behavior |
|---|---|
| Any existing rule fires | `execution_delay` is `NULL` → immediate path, byte-for-byte today's behavior |
| I edit an old rule and never touch the delay field | Still immediate |

### Story 5 — Rule lifecycle while a timer is pending

| What happens | Behavior |
|---|---|
| Admin **disables** the rule while executions are pending | Fire-time guard: rule inactive → all its pending rows skipped |
| Admin **deletes** the rule | Pending rows removed (FK/dependent destroy) |
| Admin **edits the delay** from 4h → 8h | Applies to new episodes; already-pending rows keep their original `due_at` (simple, predictable v1 rule) |
| Admin edits the **conditions** | Fire-time re-check uses the *current* conditions — the edited rule is what's enforced |
| Conversation deleted before due | Guard: skipped |

## 7. Scope for July 15

**In:**
1. Migration: `automation_rules.execution_delay`, `conversations.status_changed_at`,
   pending-executions table.
2. Listener wiring: delayed rules record a pending execution instead of executing.
3. Sweep job hooked into `TriggerScheduledItemsJob` with the fire-time guard chain.
4. Frontend delay field in the rule form + list badge + i18n (`en.json` only).
5. Specs: model validations, listener branching, sweep guards/re-check, episode dedup.

**Out (follow-ups):** per-action wait steps, recurring fires, business-hours-aware delays
(SLA's `Sla::BusinessHoursService` is the ready-made building block when we want it),
exact-time firing.

## 8. Open questions

1. **Delay bounds** — enforce a min (≥ 5 min, below cron granularity is meaningless) and a max
   (e.g. 30 days) at the model level.
2. **Follow-up re-arm policy** (Story 2): once per waiting-episode (default) vs. once per
   conversation ever. Proposing per-episode.
3. **Enterprise overlay** — feature ships in OSS core (automation rules are OSS; the scan cost
   is self-limiting since accounts without delayed rules create zero rows). Confirm no
   enterprise gating is wanted.
4. Table/row retention: ~~delete executed/skipped rows immediately vs. keep N days~~ —
   **resolved**: keep 30 days (audit/blast-radius), pruned by the daily scheduled job.
