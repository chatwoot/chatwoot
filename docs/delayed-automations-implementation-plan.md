# Delayed Automations — Implementation Plan (final)

The build source of truth for CW-7513, target **Jul 15**. Companions:
`docs/delayed-automations.md` (approved design — the what/why) ·
`docs/time-based-automations-phasing-and-rollout.md` (product phases + rollout stages —
this plan implements its Phase 0/1).

Supersedes earlier drafts: feature-flag storage was extended on develop
(`873d16f54c`, #14947 — second bitset column `accounts.feature_flags_ext_1`, 0/63 used), so
the flag is a plain features.yml append; no repurpose migration.

---

## Locked decisions

1. **Delay bounds**: `execution_delay` in minutes, `nil` or `10..43_200` (10 min – 30 days).
2. **Feature flag `delayed_automations`** — appended at the end of `config/features.yml`
   with `column: feature_flags_ext_1` (mandatory: the legacy `feature_flags` column is
   63/63 full; the header documents this), `enabled: false`, `chatwoot_internal: true`.
   No DB migration for the flag itself — the ext column already exists; ConfigLoader
   reconciles the new name (with its `column` metadata) into
   `ACCOUNT_LEVEL_FEATURE_DEFAULTS` on `db:migrate`. The flag is the **per-account stop**,
   enforced at three layers: params (Phase 5), arming (Phase 3), fire time (Phase 4).
3. **Instance kill switch `DISABLE_DELAYED_AUTOMATIONS`** — new entry in
   `config/installation_config.yml` (`value: false`, `type: boolean`, `locked: false`),
   checked in **both** sweep and per-row jobs (Phase 4). Flipping it takes effect within one
   tick, no deploy (`InstallationConfig` `after_commit :clear_cache`).
4. **Episode anchors, split by what armed the rule** (this is the only genuinely new logic;
   see design doc §5.3):
   - *Conversation events*: `"status:{status_changed_at || created_at}"` — clock never
     resets while the conversation stays in the state; leaving + re-entering = new episode.
   - *`message_created`, triggering message outgoing* (Story 2 — customer went quiet):
     `"reply_chase:{max incoming message id}"`; upsert **updates `due_at` + `message_id`**
     so the clock tracks the latest agent reply; a customer reply changes the key →
     fire-time skip.
   - *`message_created`, triggering message incoming* (agent went quiet — the
     unassign-on-no-response ask from the CW-7513 comments): `"awaiting_agent:{waiting_since}"`;
     conflict = no-op (clock counts from the first unanswered customer message). Chatwoot
     clears `waiting_since` on agent/bot reply, so the recomputed key changes and the row
     skips — without this anchor, an "unassign after 30 min silence" rule would unassign
     agents who replied promptly.
5. **`attribute_changed` conditions + delay are mutually exclusive** (model validation):
   the re-check can't reconstruct `changed_attributes` at fire time.
6. **Anchor message persisted** (`message_id` column): `ConditionsFilterService` scopes
   message conditions to the triggering message, so the fire-time re-check needs it.
7. **Retention**: `executed`/`skipped` rows kept 30 days (they are the audit trail and the
   incident blast-radius query), pruned by the daily scheduled job.
8. **No fallback to immediate execution anywhere**: flag off / guard failure ⇒ skip. A
   24h-delayed `send_message` silently becoming instant is worse than not firing.

## Phase 1 — Schema & config

### 1a. Migration: `add_execution_delay_to_automation_rules`
```ruby
add_column :automation_rules, :execution_delay, :integer  # minutes, NULL = immediate
```

### 1b. Migration: `add_status_changed_at_to_conversations`
```ruby
add_column :conversations, :status_changed_at, :datetime  # no default, no backfill
```
Plain nullable no-default add (the `sla_policy_id`/`assignee_agent_bot_id` precedent).
Readers use `status_changed_at.presence || created_at` — stable across a delay window,
which is all the episode key needs.

### 1c. Migration: `create_automation_rule_pending_executions`
```ruby
create_table :automation_rule_pending_executions do |t|
  t.references :automation_rule, null: false
  t.references :conversation,    null: false
  t.references :account,         null: false
  t.bigint     :message_id                      # anchor message for message_created rules
  t.datetime   :due_at, null: false
  t.string     :episode_key, null: false
  t.integer    :status, null: false, default: 0 # pending: 0, processing: 1, executed: 2, skipped: 3
  t.string     :skip_reason                     # rule_inactive | flag_disabled | conversation_gone |
                                                # episode_moved | conditions_changed | expired
  t.timestamps
end
add_index :automation_rule_pending_executions, [:status, :due_at]
add_index :automation_rule_pending_executions,
          [:automation_rule_id, :conversation_id, :episode_key],
          unique: true, name: 'uniq_automation_pending_execution_episode'
```
`processing` is the claim state (double-fire guard); `skip_reason` answers "why didn't my
rule fire" for support and drives incident blast-radius queries.

### 1d. Config files (no migration)
- `config/features.yml`: append `delayed_automations` at the end —
  `column: feature_flags_ext_1`, `enabled: false`, `chatwoot_internal: true`. Never reorder;
  the entry's position within its column is permanent once merged.
- `config/installation_config.yml`: `DISABLE_DELAYED_AUTOMATIONS` (`value: false`,
  `type: boolean`, `locked: false`).

## Phase 2 — Models

### `app/models/automation_rule_pending_execution.rb` (new, flat name per repo convention)
- `belongs_to :automation_rule, :conversation, :account`; optional `belongs_to :message`.
- `enum status: { pending: 0, processing: 1, executed: 2, skipped: 3 }`.
- `scope :sweepable` — due `pending` rows (`due_at <= now`) **or** `processing` rows whose
  lock is older than `STALE_PROCESSING_TIMEOUT` (`.or` of two enum scopes). This single scope
  replaces the old separate `due` window + `reclaim_stale!` bulk update; stale claims simply
  become claimable again. Expiry (`due_at < 3.days.ago`) is decided per-row at fire time.
- `self.purge_terminal!` — `executed`/`skipped` rows past `RETENTION_WINDOW` (30 days) are
  `delete_all`ed in batches of 1000 (keeps the table bounded; `delete_all` skips no needed
  validation and is not a `SkipsModelValidations` concern).
- `#claim!` — atomic compare-and-set under `with_lock`: a row is claimable if `pending`, or
  `processing` but stale. The claim happens **inside the per-row job**, not the sweep, so a
  duplicate enqueue (overlapping sweep or reclaimed stale row) loses the claim and returns —
  this is the double-fire guard. Refreshing `updated_at` on claim renews the lock.
- `self.schedule(rule:, conversation:, message: nil)` — computes `episode_key` + `due_at =
  Time.current + rule.execution_delay.minutes`, then `create!` guarded by the unique episode
  index. On `RecordNotUnique`: status / incoming-anchored episodes no-op (clock not reset);
  outgoing-anchored (reply-chase) episodes update `due_at` + `message_id` when still `pending`
  (a terminal row is never re-armed). Validation-running writes — no `insert`/`upsert`.
- `#episode_current?` — recomputes the episode key from live conversation state, compares.

### `app/models/automation_rule.rb`
- `has_many :pending_executions, class_name: 'AutomationRulePendingExecution',
  dependent: :delete_all`.
- Validation: `execution_delay` nil or integer in `10..43_200`.
- Validation: no `execution_delay` together with an `attribute_changed` condition.
- Update schema annotation.

### `app/models/conversation.rb`
- `before_save -> { self.status_changed_at = Time.current if status_changed? }` — covers
  create (status always "changes" on create) and every transition; runs before the existing
  `notify_status_change` / `dispatch_conversation_updated_event` callbacks so listeners see
  the fresh value.
- `has_many :automation_rule_pending_executions, dependent: :delete_all` (also on Account).
- Verify `status_changed_at` needs no entry in the conversation-updated watched-attributes
  list — we don't want an extra `conversation_updated` storm; a plain column write inside
  the same save is fine.

## Phase 3 — Write path (listener)

### `app/listeners/automation_rule_listener.rb`
Replace the two `ActionService.new(...).perform if conditions_match.present?` call sites
(the `message_created` and `process_conversation_event` loops) with a shared private method:

```ruby
def execute_rule(rule, account, conversation, message: nil)
  if rule.execution_delay.present?
    return unless account.feature_enabled?('delayed_automations')

    AutomationRulePendingExecution.schedule(rule: rule, conversation: conversation, message: message)
  else
    AutomationRules::ActionService.new(rule, account, conversation).perform
  end
end
```
Flag off ⇒ no arming and **no immediate fallback** (locked decision #8). Everything upstream
(loop guard `performed_by_automation?`, auto-reply skip, rule lookup,
`ConditionsFilterService`) is untouched.

## Phase 4 — Fire path (sweep)

### `app/jobs/trigger_scheduled_items_job.rb`
Add one line: `AutomationRules::TriggerPendingExecutionsJob.perform_later`. No change to
`config/schedule.yml` (rides the existing `*/5` cron).

### `app/jobs/automation_rules/trigger_pending_executions_job.rb` (new, queue `scheduled_jobs`)
```ruby
# instance kill switch — MUST use GlobalConfig.get (it applies the `type: boolean` cast;
# get_value returns the raw cached value, and super-admin edits store the STRING 'false',
# which is truthy — the ENABLE_*_CHANNEL_HUMAN_AGENT read pattern):
return if GlobalConfig.get('DISABLE_DELAYED_AUTOMATIONS')['DISABLE_DELAYED_AUTOMATIONS']

purged = AutomationRulePendingExecution.purge_terminal!
rows = AutomationRulePendingExecution.sweepable.order(:due_at).limit(sweep_limit).to_a
rows.each { |row| AutomationRules::ProcessPendingExecutionJob.perform_later(row) }
# The sweep only enqueues — the per-row job claims (double-fire guard), expires, and executes.
# end-of-run summary, JSON so New Relic ingests fields without a parsing rule:
# [AutomationRules::TriggerPendingExecutionsJob] {"event":"completed","enqueued":N,
#  "capped":bool,"purged":N,"duration_ms":N}
```
`sweep_limit`: constant on the job (default 1000) with an InstallationConfig override
(Captain `ScheduleSyncsJob` pattern — a no-deploy tuning knob). Overflow rows stay `pending`
for the next tick; log `capped: true` + remaining count — no silent truncation.
Retention pruning lives in `Internal::TriggerDailyScheduledItemsJob`: batched
`where(status: %i[executed skipped]).where(updated_at: ...30.days.ago)` deletes.

Queue reality (`config/sidekiq.yml` is strict-priority): `scheduled_jobs` ranks below `low`,
so the sweep can be late — `due_at <= now` semantics already tolerate that; per-row jobs on
`medium` preempt `default` and below — the cap is what protects the instance. `WebhookJob`
is also on `medium`, so webhook-heavy delayed rules share that budget.

### `app/jobs/automation_rules/process_pending_execution_job.rb` (new, queue `medium`,
mirrors `Sla::ProcessAppliedSlaJob`)
`discard_on ActiveJob::DeserializationError` (a deleted row fails GlobalID lookup). Re-checks
the kill switch first (sweep-only checking would let a full sweep's already-enqueued rows keep
firing after the flip): if set, return without claiming — the row stays `pending` and replays
or expires via the window. Then `claim!` (bail if lost), then the expiry check
(`due_at < DUE_WINDOW.ago` → `expired`). Guard chain, each failure → `skipped!` with
`skip_reason`:
1. rule exists and `active?` → `rule_inactive`
2. account flag still enabled → `flag_disabled` (the per-account stop)
3. conversation exists → `conversation_gone`
4. `pending.episode_current?` → `episode_moved`
5. `ConditionsFilterService.new(rule, conversation, { message: pending.message }).perform` —
   the re-check (anchor message passed so message-scoped conditions evaluate correctly;
   `changed_attributes` intentionally absent, locked decision #5) → `conditions_changed`
6. all pass → `AutomationRules::ActionService.new(rule, account, conversation).perform`,
   then `executed!`

Per-row rescue → `ChatwootExceptionTracker.new(e, account: account).capture_exception`; the
row stays `processing` on unexpected errors (the next sweep re-enqueues it once the lock goes
stale, and `claim!` lets it run again), it is NOT marked skipped.

Loop safety: `ActionService#initialize` already sets `Current.executed_by = rule` and resets
it in `ensure`, so events emitted by delayed actions carry `performed_by: rule` and are
ignored by the listener — identical to the immediate path.

## Phase 5 — API

### `app/controllers/api/v1/accounts/automation_rules_controller.rb`
Param-level flag gating (the enterprise contacts-controller precedent — `permitted_params`
merges `:company_id` only when `feature_enabled?('companies')`): include `:execution_delay`
in `automation_rules_permit` only when
`Current.account.feature_enabled?('delayed_automations')`; when the param is present with
the flag off, render 422 with a clear error (explicit beats silent stripping). `clone` works
unchanged (`dup` copies the column).

### `app/views/api/v1/accounts/automation_rules/partials/_automation_rule.json.jbuilder`
Expose `execution_delay`.

## Phase 6 — Frontend

All under `app/javascript/dashboard/`:

1. **`routes/dashboard/settings/automation/AutomationRuleForm.vue`** — below the Event
   select: "Execute" radio group (Immediately / After a delay) + number input + unit select
   (minutes / hours / days). Convert to minutes on save; hydrate back to the largest clean
   unit on edit. Client-side validation mirrors the 10 min–30 days bounds.
2. **`helper/automationHelper.js`** — `generateAutomationPayload` passes `execution_delay`
   through (null when "Immediately"). Add a `formatDelay` helper for the badge label.
3. **`composables/useAutomation.js` / `useEditableAutomation.js`** — default
   `execution_delay: null` on create; carry the field when editing/cloning.
4. **Rule list badge** — "Runs after 4h" chip when `execution_delay` present.
5. **Flag gating** — add `delayed_automations` to `featureFlags.js`; render the Execute
   control only when `isFeatureEnabledonAccount` says so. Rules that already have a delay
   keep their badge when the flag is off, and the settings page shows a "delayed execution
   is disabled for this account" banner (flag-off must never silently hide configured
   behavior).
6. **i18n** — `i18n/locale/en/automation.json` only: radio labels, unit names, validation
   message, badge text, disabled-flag banner.
7. Store (`store/modules/automations.js`) and API client (`api/automation.js`) are generic
   passthroughs — no changes expected.

Tailwind-only styling; Composition API `<script setup>` (form already is).

## Phase 7 — Specs (in scope per design doc §7)

- `spec/models/automation_rule_spec.rb` — delay bounds; `attribute_changed` × delay rejection.
- `spec/models/automation_rule_pending_execution_spec.rb` — episode key derivation (all
  three anchors); insert/upsert semantics (status + incoming-anchored: clock not reset;
  outgoing-anchored: due_at tracks latest agent reply); `episode_current?` incl.
  agent-reply-clears-`waiting_since` cancellation; `claim!` (once-only + stale reclaim);
  `sweepable` selection; `purge_terminal!`.
- `spec/models/conversation_spec.rb` — `status_changed_at` set on create and every
  transition, untouched on non-status saves.
- `spec/listeners/automation_rule_listener_spec.rb` — delayed rule records a pending
  execution and does NOT run actions; nil delay unchanged; `performed_by` automation events
  create no rows; flag off → no arming AND no immediate fallback.
- `spec/jobs/automation_rules/trigger_pending_executions_job_spec.rb` — due+pending and stale
  `processing` enqueued (not future); kill switch no-ops the sweep; cap limits enqueues;
  terminal rows past retention purged.
- `spec/jobs/automation_rules/process_pending_execution_job_spec.rb` — full guard chain
  with `skip_reason` per branch; per-row `expired`; kill switch leaves row pending; duplicate
  enqueue executes once (claim guard); happy path executes
  actions exactly once.
- `spec/controllers/api/v1/accounts/automation_rules_controller_spec.rb` —
  permits/persists/serializes `execution_delay` when flag on; 422 when submitted with flag
  off; clone copies it.
- Story-level integration spec (cheap, high value): Story 1 and Story 2 tables from the
  design doc as end-to-end listener→sweep specs with `travel_to`.

## Manual QA script (maps to design-doc stories + rollout Stage B)

1. Story 1: rule `conversation_updated` + `status = pending` + 10 min delay + add label →
   flip to pending, touch the conversation twice (no clock reset), wait for sweep → label.
   Repeat but resolve before due → no label, row `skipped`/`episode_moved` (resolving
   changes `status_changed_at`, so the episode guard fires before the conditions re-check).
2. Story 2: rule `message_created` + `message_type = outgoing` + delay + send_message →
   agent reply, then customer reply before due → cancelled (`episode_moved`). Without
   customer reply → follow-up sent once; the follow-up itself doesn't re-arm the rule.
3. Agent-idle recipe (CW-7513 comments): rule `message_created` + `message_type = incoming`
   + 30 min delay + `assign_agent: None` → customer message, no agent reply → unassigned at
   sweep. Repeat with agent replying before due → NOT unassigned (`waiting_since` episode
   cancelled, `episode_moved`).
4. Story 4: pre-existing rule untouched → still fires instantly.
5. Story 5: disable rule with pending row → sweep marks `rule_inactive`; delete rule →
   rows gone.
6. Flag: disable `delayed_automations` on the account → delay control hidden + banner
   shown; armed rows skip with `flag_disabled`; no new rows armed. Set
   `DISABLE_DELAYED_AUTOMATIONS` → sweep no-ops within one tick and queued per-row jobs
   revert rows to pending.
7. Local tip: temporarily drop the cron to `*/1` or run
   `AutomationRules::TriggerPendingExecutionsJob.perform_now` from console.

## Sequencing / PR split

Stacked PRs off `feature/cw-7513`:

1. **PR 1 — backend**: Phases 1–5 + specs. Reviewable standalone; feature is
   **API-complete** — this is the Jul 15 degenerate path: if PR 2 slips, the canary
   customer's rules can be created via console/API with only PR 1 shipped.
2. **PR 2 — frontend**: Phase 6 (delay control behind the flag, badge, banner, i18n).

Work order within PR 1: schema/config → conversation hook → pending-execution model
(episode semantics are the only genuinely new logic — do them test-first) → listener branch
→ jobs → controller/jbuilder.

## Risks / edge cases to keep in view

- **Upsert vs. validation races**: `insert`/`upsert` skip AR validations — fine, all values
  are server-computed; the unique index is the real guard.
- **`conversation_updated` storm cost**: one indexed insert-conflict per matching event, no
  row growth per episode (unique index). Watch the unique index's bloat after rollout.
- **Rule edited while pending**: conditions re-check uses current conditions (by design);
  `due_at` keeps its original value (documented v1 behavior).
- **`send_email_to_team` / webhook actions at fire time**: work unchanged — rate limit
  (`within_email_rate_limit?`) and `Current.executed_by` both live in ActionService; verify
  in specs, don't reimplement.
- **Audit overlay**: `enterprise/app/models/enterprise/audit/automation_rule.rb` audits the
  new column automatically — verify the audited payload includes `execution_delay`.
- **Super-admin flag UI**: `selected_feature_flags=` spans both bitset columns since
  #14947 — the per-account toggle works with zero extra code; being `chatwoot_internal`,
  the flag is visible only on Cloud super-admin until Stage E.
- **Retroactivity limitation** (documented, not a bug): delayed rules arm on events; a new
  rule does nothing for conversations already sitting in the target state with no further
  activity. Release notes + user guide + rule-form microcopy state this; closing it is a
  Phase 2 decision (see rollout doc).
- **Deprecation note in `lib/events/types.rb`** (opened/resolved → status_changed): no
  impact, we add no new events.
