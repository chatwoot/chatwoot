# Time-Based Automations — Product Phasing & Rollout Plan

**Status:** Draft for review (adversarially reviewed; implementation plan amended to match — see §5 note)
**Owner:** Tanmay
**Companions:** `docs/delayed-automations.md` (v1 design, approved) ·
`docs/delayed-automations-implementation-plan.md` (v1 build plan — amended by this doc's review)
**Tracking:** CW-7513 (v1, due Jul 15) · CW-5790 (parent tracker, "Needs Spec" — this doc is
the spec for everything past v1)

---

## 1. The end goal, defined

"Time-based automations" is not one feature — it is a ladder that every mature support
platform climbs in the same order (Zendesk, Freshdesk, Intercom, HubSpot, Help Scout, Front
all converge on it):

1. Delayed action with fire-time re-check ← **v1 (CW-7513)**
2. Run-once / anti-loop semantics owned by the platform, not the user
3. Rich "time since X" condition vocabulary (created / entered status / last customer reply /
   last agent reply / assigned)
4. Business-hours-aware time accounting
5. SLA-integrated escalation (at-risk + breach stages with actions)
6. Multi-step sequences (follow-up → wait → follow-up → resolve, interruptible on reply)
7. Scheduled/calendar triggers and full workflow builder

**End goal for Chatwoot (12-month horizon): rungs 1–6.** Rung 7 (visual builder, cron
triggers) is a separate product investment and stays out of this plan except as a
compatibility constraint: nothing we ship may assume "one rule = one delayed action" so
deeply that sequences can't be layered on.

Three facts from the research shape everything below:

- **The v1 engine is already the end-state engine.** Per-conversation pending executions with
  fire-time re-check is the architecture Front and Intercom use; Zendesk/Freshdesk's hourly
  full-table sweeps are the legacy model whose user-visible warts (whole-hour granularity,
  ±1 h slop, "nullifying condition" hacks) we get to skip. Every later phase is additive
  vocabulary and UI on the same table + sweep — no rewrite is on the ladder.
- **One capability the sweep model has that ours doesn't: eventless, retroactive
  evaluation.** An event-armed engine does nothing for conversations already sitting in the
  target state when a rule is created. This is a real, user-visible limitation ("why didn't
  it label my existing backlog?") — v1 documents it plainly (§3, Phase 1) and Phase 2 carries
  a named scope decision for closing it.
- **Community demand is mapped, with honest issue states.** Phases cite Chatwoot GitHub
  issues as *evidence of demand*; several were bulk-closed as stale (marked below), so they
  document the ask, not a ticket we get to close.

## 2. Product phases at a glance

| Phase | Ships | Evidenced demand | Target |
|---|---|---|---|
| **0. Engine (dark)** | Schema, pending-execution engine, sweep, guardrails, feature flag — no UI | — | with v1 PRs |
| **1. Delayed rules** | `execution_delay` + fire-time re-check; both reply directions via episode anchors; delay UI; badge | CW-7513 (all 3 examples + unassign-on-idle from comments); #1270 *(partial: single reminder)* | **Jul 15** |
| **2. Time vocabulary + business hours + run history** | "Time since last customer/agent reply, time in status, time since created" conditions; run inside/outside business hours; per-rule execution history UI | #6861 (open), #10455 (open), #12694 (open), #4542 *(closed-stale; documents the WhatsApp-24h ask)*; #6889 *(recipe becomes possible)* | ~6 weeks after Cloud GA |
| **3. Follow-up chains + SLA escalation** | Repeat-with-terminator ("remind ×N then resolve"); SLA at-risk/breach as automation events; snooze-duration action | #1270 (open, full ask), #6889 (open), #10118 *(closed-stale)* | Q4 2026 |
| **4. Scheduled triggers / builder** | Calendar/cron rule triggers, scheduled sends, visual sequences | #9484 (open) + scheduled-send cluster (#5554 closed-stale, #9771, #11486, #12146, #12823); CW-5790 original ask | 2027, own spec |

Each phase is independently shippable, independently valuable, and strictly additive on the
Phase 0 engine.

## 3. Phase detail

### Phase 0 — Engine, shipped dark

Everything in `docs/delayed-automations-implementation-plan.md` (migrations, pending-execution
model with claim states, listener branch, sweep jobs with caps/windows/kill switch, API
gating, feature flag) merged with no UI exposure. `execution_delay` stays `NULL` for every
rule, so the listener branch is dead code for 100% of traffic until the flag turns the UI on —
this is what makes the merge risk-free.

Exit criteria (measurable, and achievable while dark):
- Engine + guard specs green.
- Sweep running in production logging `"due":0,"enqueued":0` every 5 minutes.
- All three CW-7513 stories exercised **on staging** with compressed delays (10 min).
- §6 alerts created and verified end-to-end with a test trigger.

(Live dogfood on Chatwoot's own account requires the flag on — that is Stage B, Phase 1.)

### Phase 1 — Delayed rules (CW-7513, Jul 15)

The v1 surface: "Execute: immediately / after a delay" on the existing rule form, delay badge
in the rule list.

**What "time since last reply" means in v1 — both directions, precisely:**
- *Customer went quiet* (CW-7513 example 2, design-doc Story 2): rule anchored on an
  **outgoing** message. Episode tracks the latest agent reply; a customer reply cancels the
  pending follow-up at fire time.
- *Agent went quiet* (the unassign ask in the Linear comments; the #6861 phrasing): rule
  anchored on an **incoming** message. Episode is keyed on `waiting_since`, which Chatwoot
  clears when an agent or bot replies — so an agent reply cancels the pending action at fire
  time. Without this anchor the recipe would unassign agents who *did* reply promptly; the
  implementation plan's episode-key section now specifies both anchors (this was the single
  most important correction from review).

With that, the unassign-on-no-response recipe from the Linear comments is buildable in the
UI on day one (the agent dropdown already offers "None", serializing to the `'nil'`
sentinel — `useAutomationValues.js:88`): *Message Created + Message Type is Incoming + delay
30 min + Assign agent: None*. Ship it as a documented recipe. The thread's follow-up ask
(agent online/offline as a condition) is not in v1 — logged as a Phase 3 open item.

**Known limitation, stated everywhere users will hit it** (release notes, user-guide,
rule-form microcopy): delayed rules apply to conversations that have activity *after* the
rule is created. A brand-new "stuck in Pending 4h" rule does not retroactively arm for
conversations already sitting in Pending. Closing this is a named Phase 2 decision.

**Run-once semantics** (ladder rung 2) are built in from day one via episode keys — the
lesson from Zendesk/Freshdesk, whose users must hand-build nullifying conditions. Never
expose a knob that lets a rule re-fire hourly.

**Observability in v1 is internal-only**: support/eng can answer "why didn't it fire" from
the pending-executions table (`skip_reason` column). Admin-facing run history ships in
Phase 2 — until then this is a known support load, priced in.

Exit criteria:
- Before Jul 15: the requesting customer confirms the two reply-direction readings above
  match their expectation (don't discover a mismatch after release).
- Canary accounts using delayed rules for 1 week: `expired` = 0 sustained, fire-lag p95
  < 10 min, zero new Sentry groups under the two job classes.
- Story 2's cancellation observed in production (a real customer reply cancelling a pending
  follow-up), not just in specs.
- Week-1 executed:skipped mix recorded as the baseline band for Stage D gating.

### Phase 2 — Time vocabulary, business hours, run history

What users ask for the moment v1 lands (top evidenced asks):

1. **"Time since X" conditions** — new condition attributes evaluated by the same engine:
   `hours_since_last_customer_message`, `hours_since_last_agent_message`,
   `hours_in_current_status`, `hours_since_created`. Mechanically these are alternate
   **episode anchors + due-at sources** for a pending execution — the rule form gains a
   "when time elapses" trigger style that composes with existing conditions.
   **Named scope decision — arming for quiet/pre-existing conversations:** event-armed
   pending rows don't cover conversations with no future events. Options: (a) one-time
   arming scan at rule save (bounded, predictable — recommended), (b) periodic eligibility
   scan (reintroduces exactly the per-account sweep v1 avoided; needs its own cost model).
   Decide at Phase 2 spec with Cloud row-count data from Phase 1.
2. **Business hours** — two separable features, in this order:
   a. *Gate*: "only run this rule inside/outside inbox business hours" (a fire-time guard
      against `working_hours`) — the #10455/#12694 ask.
   b. *Accounting*: "4 business hours" delays that pause the clock outside schedules —
      reuse `Sla::BusinessHoursService`. That service lives in `enterprise/`; either
      accounting becomes a premium capability (matching SLA) or the calculator moves to OSS
      core. Decide at Phase 2 spec; the schema needs nothing either way.
3. **Re-arm policy control** — expose the v1 episode semantics as an explicit choice
   ("once per conversation" / "every time it re-qualifies"), defaulting to current behavior.
4. **Per-rule execution history UI** — fired/skipped(+reason) list on the rule, from the
   existing table + `skip_reason` (30-day retention shown as a visible constraint). This is
   the Zendesk/Intercom-parity observability the feature's support load demands.

Exit criteria (self-contained, not tied to issue states):
- A rule "send a template when >23h since the last inbound customer message on a WhatsApp
  inbox" works end-to-end (the WhatsApp 24h-session use case).
- A rule gated to business hours provably does not fire outside them; delay *accounting*
  verified against SLA's calculator on shared fixtures.
- Each re-arm policy behaves per spec in the Story-2 integration test.
- An admin can answer "why didn't my rule fire on this conversation" from the rule's history
  page without contacting support.

### Phase 3 — Follow-up chains + SLA escalation

1. **Repeat-with-terminator** (#1270's full ask): "send reminder every N hours, at most K
   times, then resolve." Schema: `max_occurrences` + occurrence counter on the pending
   execution — the episode model already prevents overlap. Sequences-*lite*: one repeated
   action + one terminal action, deliberately short of a builder.
2. **SLA integration** (#6889): emit `sla_missed` / `sla_at_risk` as automation events
   (enterprise overlay adds them to the event dropdown, the same way `sla_policy_id`
   conditions are added today), so escalation rules compose from existing actions. SLA
   already computes the timing; automations subscribe. (Note: #6889's literal "waited more
   than X hours → escalate" becomes satisfiable with Phase 2 vocabulary — publish that
   recipe with Phase 2; Phase 3 makes it SLA-native.)
3. **Snooze composition** (#10118's ask): `snooze_conversation` action gains a duration
   param; snooze-expiry already rides the same 5-min sweep.
4. Evaluate the agent online/offline condition (Linear-thread follow-up ask) with
   assignment-policy input.

Exit criteria: Intercom's canonical journey (reply-chase → reminder → auto-resolve)
buildable in two rules; SLA-escalation recipe documented; sweep p95 flat vs Phase 2 baseline.

### Phase 4 — Scheduled triggers / builder (out of this plan's scope)

Calendar/cron triggers ("every Monday 9am"), scheduled one-off sends, visual multi-step
builder. Needs its own spec (CW-5790 becomes that spec once Phases 1–3 close the
duration-based demand). The only obligation now: keep `event_name` + pending-executions
generic enough that a `schedule` pseudo-event can create pending executions without a
conversation event — the current schema (rule, conversation, due_at, episode) already
permits this.

## 4. Rollout plan (Phase 1 in full; later phases reuse the template)

### 4.1 Gating levers

| Lever | Choice for this feature |
|---|---|
| Per-account feature flag | `delayed_automations`, appended at the end of `config/features.yml` with **`column: feature_flags_ext_1`**. The bit-budget problem this plan originally flagged was solved on develop (`873d16f54c`, #14947): a second bitset column `accounts.feature_flags_ext_1` exists (0/63 used) and the features.yml header now mandates new flags use it — the legacy `feature_flags` column is 63/63 full. No repurpose migration; ConfigLoader reconciles the new name (with its `column` metadata) into `ACCOUNT_LEVEL_FEATURE_DEFAULTS` on migrate, and `selected_feature_flags=` / super-admin toggles span both columns since #14947. `enabled: false`, `chatwoot_internal: true` at introduction. Flag name and its position within the ext column are frozen forever once merged. |
| What the flag gates | **Three layers, one coherent semantics — the flag is the per-account stop.** (1) *Configuration*: the delay control in the rule form (`featureFlags.js` + `isFeatureEnabledonAccount`), and server-side, `execution_delay` is accepted only when the flag is on — param-level gating per the enterprise contacts-controller precedent (`permitted_params` includes `:company_id` only when `feature_enabled?('companies')`), returning 422 when a delay is submitted with the flag off (explicit beats silent stripping). (2) *Arming*: the listener does not create pending executions for flag-off accounts — and does **not** fall back to immediate execution (a 24h-delayed message silently becoming instant is worse than skipping). (3) *Fire time*: the guard chain checks the flag and marks rows `skipped` / `skip_reason: flag_disabled`. Rules keep their delay badge when the flag is off; the settings page shows a "delayed execution is disabled for this account" banner. |
| Instance kill switch | `DISABLE_DELAYED_AUTOMATIONS`, **declared in `config/installation_config.yml` with `type: boolean`** (so "false" means false — the bare `DISABLE_GRAVATAR` presence-check pattern would treat any non-blank string as disabled), checked in **both** the sweep job *and* the per-row job (sweep-only would let up to a full sweep's already-enqueued per-row jobs fire after the flip). Rows the per-row job refuses stay `pending` and replay or expire via the due-window. Takes effect within one tick, no deploy (`InstallationConfig` `after_commit :clear_cache`). |
| Rule-level off | Existing `active` toggle — already in the fire-time guard chain. |
| Premium? | **Ship non-premium** (see Decisions, §7). The `premium: true` + `ReconcilePlanFeaturesService` lever stays available with zero schema cost if the business later wants plan-gating. |

One honesty note: the wave-enablement rake in Stage D is **new work**, not existing
machinery. Its safety kit (dry-run default, `APPLY=true`, `LIMIT=n`, confirmation) is
specified here, modeled on `assignment_v2:migrate`'s interactive confirm + `ACCOUNT_ID`
scoping and `reporting_events_rollup.rake`'s dry-run prompt — no committed rake has the full
kit today.

### 4.2 Stages

**Stage A — Dark merge (deadline: Fri Jul 10 EOD; Sat Jul 11 is slack, not the plan).**
PR 1 (engine + flag, per the amended implementation plan) and PR 2 (UI behind flag) land on
`develop`. Named reviewers with a same-day review SLA are a §7 decision to lock **today**.
Confirm the weekend deploy policy: if Cloud doesn't deploy weekends, Friday's deploy is the
last train before dogfood. §5 marks which guardrails are Stage-A-blocking vs fast-follow so
a compressed schedule sheds the right load. Everyone is on the immediate path; the sweep
runs and logs `"due":0,"enqueued":0`.

**Stage B — Internal dogfood (Fri Jul 10 evening – Tue Jul 14).**
Enable the flag on Chatwoot's own support account + staging via super-admin
(`chatwoot_internal` keeps it invisible to self-hosted super-admins). The window spans a
weekend — compensate: staging rules at 10-minute delays to compress many cycles Sat–Sun,
plus one realistic 24h rule on the production support account; name who watches the first
sweep ticks Saturday morning. Go/no-go **Tue Jul 14** requires at least one business day
(Mon) of real traffic and: fire-lag p95 < 10 min, `expired` = 0, zero unexpected Sentry
groups, every skip row's `skip_reason` explainable, **and Story 2's cancellation path
observed against real traffic** (customer replied → follow-up cancelled).

**Stage C — Canary (Wed Jul 15 — the release commitment).**
Enable for a hand-picked cohort: the CW-7513 requesting customer, the accounts attached to
CW-5790's three customer conversations, ~10–20 design partners. **White-glove the first
one**: on Jul 15, set up the customer's three rules together with them, so the one-week
canary clock starts on day one instead of waiting for self-serve discovery. Mechanism:
super-admin toggle or `account.enable_features!('delayed_automations')`. CW-7513 is
"released" at this stage. Delayed `send_message` rules stay within dogfood + canary
accounts until Stage D (highest-blast-radius action; messages can't be unsent).

**Degenerate paths (decided now, not during the incident):**
- PR 2 (UI) slips → Jul 15 is still met: the feature is API-complete after PR 1; enable the
  customer's flag and create their three rules via console/API.
- PR 1 slips past Mon Jul 13 → customer comms + Stage C moves to Jul 16–17. The commitment
  is the capability in the customer's hands, not a specific artifact.

**Stage D — Cloud GA (earliest Jul 22; gated, not dated).**
Entry gate: ≥5 canary accounts each with ≥1 delayed rule that completed ≥1 full execution
cycle, and Phase 1 exit metrics holding. Waves ordered by *real* signal (an inert-flag wave
proves nothing — the flag only unlocks configuration):
1. **Wave 1**: accounts with ≥1 active automation rule, batched ascending by conversation
   volume — the population that will actually create delayed rules, arriving gradually.
2. **Wave 2**: high-volume automation accounts, after Wave 1 metrics hold for 24–48h.
3. Zero-rule accounts get the flag via the new-account default flip below — bulk-enabling
   them separately is ceremony.
Pause criterion between batches: any `expired > 0` sustained or new Sentry group within 24h
of a batch. New rake task carries the specified safety kit (dry-run default, `APPLY=true`,
`LIMIT=n`, interactive confirmation). Simultaneously flip the new-account default:
migration mutating `ACCOUNT_LEVEL_FEATURE_DEFAULTS['delayed_automations'].enabled = true` +
`GlobalConfig.clear_cache` (assignment_v2 `20260409091202` precedent).

**Stage E — Self-hosted GA (next tagged release after Stage D holds for 2 weeks).**
In one PR: `enabled: true` in `features.yml` (new installs), drop `chatwoot_internal`
(flag becomes visible in self-hosted super-admin), ship the Stage D config-flip + backfill
migrations (existing installs get them on `db:migrate` — ConfigLoader alone never flips an
existing install's defaults; the migration is mandatory, per the captain_tasks +
assignment_v2 precedent pair). **Exit criteria, not follow-ups:**
- Docs page: `DISABLE_DELAYED_AUTOMATIONS` (where to set, halts within ~5 min) and the
  flag's exact three-layer semantics.
- Upgrade note: "if you run a custom Sidekiq queue list, `scheduled_jobs` **and** `medium`
  must be processed or delayed rules never fire" (stock `sidekiq.yml` is titled a *sample*
  configuration).
- Expectations paragraph: on strict-priority queues, low-concurrency installs will see
  sweep lag; hours-scale delays are the design point.
- The run-once-semantics user-guide article.

**Stage F — Cleanup (2–3 weeks post-GA).**
Keep the controller flag guard (self-hosted admins legitimately toggle account flags).
Cleanup: retire the canary rake if one-off, close CW-7513, re-spec CW-5790 as Phase 2,
record learnings + the Phase 1 baseline bands for Phase 2 gating.

### 4.3 Rollback playbook

| Symptom | Response | Blast radius |
|---|---|---|
| Sweep melting `medium` queue / runaway executions | Set `DISABLE_DELAYED_AUTOMATIONS` → sweep no-ops next tick **and** already-enqueued per-row jobs refuse to execute (switch is checked in both). Pending rows accumulate; the 3-day due-window caps replay on re-enable | Instance-wide stop; immediate path untouched |
| One account's rules misbehaving | Disable the account's `delayed_automations` flag — per-account stop at all three layers (no new arming; armed rows skip with `flag_disabled`). Or deactivate the specific rule | Single account |
| **Re-check bug: rule fires where it shouldn't** | (1) Kill switch. (2) Blast radius = executed rows for that rule in the window (`rule_id, conversation_id, updated_at` — this audit trail is why `skip_reason`/rows are kept 30 days). (3) Reversible actions (labels, assignments): remediation rake driven off that row list. (4) `send_message`: **irreversible** — comms template + a named support owner; this is why delayed sends stay dogfood/canary-only until Stage D | Bounded by the executed-rows list |
| Bad migration / schema issue at Stage A | Standard revert; `execution_delay` is nullable with no readers when dark | Deploy-level |

An explicit non-rollback: **never delete the flag or reorder features.yml** — bit positions
are permanent (header contract in features.yml).

## 5. Engine guardrails (folded into the implementation plan)

> These originated as review amendments; the schema/scope/spec deltas are now **written into
> `docs/delayed-automations-implementation-plan.md`** so the PRs are built from one source of
> truth. This section keeps the rationale and the Stage-A-blocking split.

**Stage-A-blocking** (the sweep is unsafe without them):
- **Bounded due-window**: sweep selects `due_at: 3.days.ago..Time.current`
  (campaign/snooze-reopen precedent); older rows → `skipped` / `skip_reason: expired`,
  count logged — no silent truncation.
- **Per-sweep cap**: constant on the job class with an InstallationConfig override
  (Captain ScheduleSyncsJob pattern — gives a no-deploy tuning knob), default 1000;
  overflow logs `capped: true` + remaining count; due rows stay due for the next tick.
- **Claim transition**: the sweep only enqueues; the per-row job does the atomic
  `pending → processing` claim under a row lock, so a row re-enqueued by an overlapping sweep
  (or a reclaimed stale row) loses the claim and can't double-fire. Stale `processing` rows
  older than 15 min become claimable again (mechanism per Captain's stale-claim recovery — its
  `SYNC_STALE_TIMEOUT` is 2h; we choose 15 min to match the 5-min cadence).
- **Kill switch checked in both jobs** (§4.1).
- **Queue reality** (`config/sidekiq.yml` is strict-priority, no weights): per-row jobs on
  `medium` (3rd) preempt `default` and below — the cap is what protects the instance;
  `scheduled_jobs` (8th) sits *below* `low`, so the sweep itself can be late — `due_at <=
  now` semantics already tolerate that. Note `WebhookJob` is **also** `queue_as :medium`,
  so webhook-heavy delayed rules add to the same queue; covered by the cap.
- Per-row error isolation: `discard_on ActiveJob::DeserializationError`; rescue →
  `ChatwootExceptionTracker.new(e, account:).capture_exception`, continue.

**Fast-follow tolerable** (days, not weeks; needed before Stage C):
- `skip_reason` terminal values on every skip path (`rule_inactive | conversation_gone |
  flag_disabled | episode_moved | conditions_changed | expired`).
- Structured end-of-run summary log + dashboards (§6).

**Unchanged from the implementation plan** (called out because review probed them):
- Migration shapes: plain nullable no-default `add_column` on `conversations`; concurrent
  indexes; retention pruning batched under the global 14s `statement_timeout`.
- Email actions keep `within_email_rate_limit?` via ActionService reuse — verify in specs,
  don't reimplement.

## 6. Observability, metrics, alerts

**Structured summary log per sweep**, emitted as JSON so New Relic ingests fields without a
parsing rule:
`[AutomationRules::TriggerPendingExecutionsJob] {"event":"completed","enqueued":N,
"capped":false,"purged":N,"duration_ms":N}` — plus per-row terminal
`skip_reason` stored on the row (the support-facing answer to "why didn't my rule fire"
until Phase 2's history UI).

**Alerts are pre-Stage-A tasks with owners, or they don't exist.** Each needs its NRQL/Sentry
rule created, a notification channel, and a named acknowledger for Jul 10–22 (§7 decision):

| Alert | Mechanism | Owner / channel |
|---|---|---|
| Sweep summary absent > 15 min | NR loss-of-signal on `event:'completed'` from the job class | *fill at §7 sign-off* |
| `expired > 0` sustained (2+ ticks) | NRQL on the JSON field |〃 |
| Pending-row count growing across 6 ticks | NRQL on `due` | 〃 |
| New Sentry group under the two job classes | Sentry issue alert filtered by job-class tag | 〃 |

Stage A exit includes a live end-to-end test of each alert (test trigger → channel).

**Dashboards** (New Relic, existing log forwarding + newrelic-sidekiq-metrics):
fire lag (`executed_at - due_at` p50/p95; target p95 < 10 min) · outcome mix by
`skip_reason` (high `conditions_changed` is *healthy* — cancelled follow-ups working; any
`expired` means starvation) · pending count + oldest-pending age · `medium` and
`scheduled_jobs` queue latency.

**Numeric gates** (replacing fuzzy language): Stage B go/no-go and Stage D pause criteria in
§4.2; the week-1 canary executed:skipped mix is *recorded as the baseline band* — later
deviations from that band, not an arbitrary number, are the anomaly signal.

**Success metrics (product):** accounts with ≥1 delayed rule (adoption), delayed executions
per day, executed:skipped ratio vs baseline, and the CW-7513 customer's three scenarios
confirmed by them.

## 7. Decisions needed (owners; lock before Stage A — i.e., today/tomorrow)

1. **Flag name sign-off** (eng, Tanmay): `delayed_automations` on `feature_flags_ext_1` —
   ~~resolved~~: the ext column shipped on develop (#14947), so this is a plain features.yml
   append; the name/position freezes on merge. Non-blocking beyond PR review.
2. **Premium or not** (product, Pranav/Sony): recommendation **non-premium** — base
   `automations` is free, engine cost is self-limiting (no delayed rules → zero rows), and
   Phases 2–3 carry natural premium hooks (business-hours accounting alongside SLA, SLA
   escalation). Plan-gating later is one `ReconcilePlanFeaturesService` change.
3. **Named reviewers + review SLA for PR 1/2** (eng leads): Friday EOD merge deadline makes
   this load-bearing.
4. **Alert ownership Jul 10–22** (eng/on-call): who receives and acks §6's four alerts.
5. **Weekend deploy policy** (infra): confirms whether Stage B starts Friday evening or
   Monday.
6. **Delay bounds** (product): 10 min–30 days per the implementation plan — confirm.
7. **Canary cohort** (product/support): CW-7513 customer + CW-5790 attached accounts +
   design partners; confirm the white-glove session on Jul 15.
8. **Phase 2 business-hours placement** (product, at Phase 2 spec): OSS gate + premium
   accounting, or all-OSS. No schema impact either way.

## 8. Timeline

| Date | Milestone |
|---|---|
| Thu Jul 9 | This plan signed off; §7 decisions 1–5 locked; PR 1 (engine+flag, dark) in review |
| Fri Jul 10 | PR 2 (UI behind flag); **both merged EOD** (named-reviewer SLA); deploy; Stage B flag on for internal accounts |
| Sat–Sun Jul 11–12 | Slack for merge slip; staging compressed-delay cycles running; Saturday-morning sweep watch (named) |
| Mon Jul 13 | First full business day of dogfood signal |
| Tue Jul 14 | Go/no-go on §4.2 Stage B gates |
| **Wed Jul 15** | **Stage C canary — CW-7513 delivered** (white-glove setup with the requesting customer; degenerate path: console-created rules if PR 2 slipped) |
| Jul 22+ | Stage D Cloud GA — earliest date, entry-gated on canary evidence; waves per §4.2 + new-account default flip |
| Next tagged release | Stage E self-hosted GA (checklist in §4.2 are exit criteria) |
| +2–3 weeks | Stage F cleanup; Phase 2 spec kickoff (re-scope CW-5790; carries the arming-scan decision + business-hours placement) |
| ~Sep | Phase 2 ship (time vocabulary + business hours + run history) |
| Q4 2026 | Phase 3 (chains + SLA escalation) |
| 2027 | Phase 4 spec (scheduled triggers / builder) |
