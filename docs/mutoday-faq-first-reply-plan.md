# MUToday FAQ First-Reply (LINE OA) — Implementation Plan

**Spec:** [mutoday-faq-first-reply-spec.md](mutoday-faq-first-reply-spec.md)
Paths are repo-relative. **App id:** `mutoday_faq_reply`. **Target branch:** `develop`.

---

## 1. Corrections to the spec

Every blocker from the three reviews, with a verdict. Reviews are cited as R1/R2/R3.

### C1 — `content_attributes` is a `json` column; the `?` operator is jsonb-only — **FIXED**
*(R1 B1, R2 B1 — same defect, reported twice)*

Verified in `db/schema.rb` line ~1248: `t.json "content_attributes", default: {}`, four lines above `t.jsonb "additional_attributes", default: {}`. Every promotion-gate and monitoring query in the spec would have died with `ERROR 42883 operator does not exist: json ? unknown`.

**Fix:** the telemetry blob moves to **`messages.additional_attributes['mutoday_faq_reply']`** (real jsonb). Verified safe: `Message`'s only validator on that column is `JsonSchemaValidator, schema: TEMPLATE_PARAMS_SCHEMA` (`app/models/message.rb:75-77`), whose schema constrains only a `template_params` key and sets no `additionalProperties: false`, so a sibling top-level key validates. `human_response?` reads only `additional_attributes['campaign_id']`, which we never set. `content_attributes` is left entirely alone.

All queries become `additional_attributes ? 'mutoday_faq_reply'`.

**Sub-fix, R2's index proposal — REJECTED.** R2 asked for a GIN expression index mirroring `index_messages_on_additional_attributes_campaign_id`. That needs a migration with `CREATE INDEX CONCURRENTLY` against the production `messages` table — precisely the hazard CLAUDE.md documents (a statement-timeout kill leaves an invalid index that `if_not_exists` then skips on retry while reporting success). Instead: **every monitoring query is bounded by `created_at`**, which uses the existing `index_messages_on_created_at`, and all of them are run through `docker compose exec -T postgres psql -U postgres -d chatwoot_production`, never a Rails connection (`config/database.yml` sets `statement_timeout: 14s`). No migration in v1.

### C2 — G8 is evaluated up to 8 s before the write; an agent can be talked over — **FIXED**
*(R1 B2)*

**Fix:** the G8 existence query is re-run immediately before `conversation.messages.create!`, inside the same service. A hit logs `outcome=skipped guard=human_replied_during_classify` and returns; the Redis marker stays claimed (fail closed). Covered by the indexed `index_messages_on_conversation_account_type_created`. Precedent for re-checking at decision time is `app/services/message_templates/hook_execution_service.rb:30`.

### C3 — `RateLimiter#reserve` conflates a breach with a WATCH abort — **FIXED**
*(R1 B3, R2 B4, R3 B9 first half)*

`redis.multi` returns `nil` when the WATCH is invalidated by ordinary concurrency, and `result.present?` cannot tell that from a real breach — so normal traffic on the shared inbox-hour key would page Sentry, suppress a customer reply, and post a Thai note claiming a safety limit fired.

**Fix:** `reserve` returns a three-state symbol — `:ok` / `:limited` / `:contended`. `:contended` is retried in a bounded loop (3 attempts); after that it is treated as `:ok` and logged at `info` (a breaker set 5× above peak can safely lose one contended increment; withholding a reply over CAS contention cannot be right). Only `:limited` trips §9.3. A spec asserts two concurrent reserves both return `:ok` while capacity remains.

### C4 — "zero writes to the `conversations` table" is false — **FIXED (restated), and now deliberately superseded**
*(R1 B4, R3 "Missing" #2)*

Verified: `Message#set_conversation_activity` (`app/models/message.rb:449-452`) runs `conversation.update_columns(last_activity_at:, updated_at:)` inside the same `after_create_commit` chain, on every message. The invariant as written was untrue.

**Fix:** the boundary is restated as: *the feature never writes `status`, `assignee_id`, `assignee_agent_bot_id`, `ai_assignee`, `additional_attributes` or `custom_attributes` on a conversation.* `last_activity_at`/`updated_at` are bumped by Chatwoot's own callback and are out of our control; the accepted consequence is that an AI reply re-sorts the conversation to the top of the agent's "Latest" list. Additionally, C8 below now writes **labels** on deny-list hits — verified D6-safe because `determine_conversation_status` is `before_create` only (`app/models/conversation.rb:138`), so `Labelable#add_labels`'s `update!` cannot set `pending`.

### C5 — greeting / out-of-office does not race us, it kills us silently and permanently — **FIXED**
*(R1 B5, R2 B5)*

Verified: `execute_message_template_hooks` runs **synchronously** in the inbound message's `after_create_commit` (`app/models/message.rb:332, 441-443`), while our reply travels AsyncDispatcher → EventDispatcherJob → HookJob (`medium`) → our job (`high`). The template always wins; G8 then rejects our reply for the life of that conversation, and the only trace is an `info` line reading `guard=already_answered`. The spec's "non-deterministic race" was wrong, and its consequence was understated.

**Fix, three parts:**
1. P1/P2 rewritten with the real mechanism, as hard preconditions.
2. When G8 rejects because of a `template` message that is **not ours** (no `additional_attributes['mutoday_faq_reply']`), the outcome is `misconfigured guard=foreign_template`, with a deduped Sentry alert — the same treatment G5 gets. Never a quiet skip.
3. `rake mutoday:faq:doctor` exits non-zero on either setting, and the inbox's greeting/OOO flags join the standing checks so a re-enable six months from now is caught the same day.

### C6 — turning the out-of-office message off deletes working product behaviour — **FIXED**
*(R3 B6)*

Right, and the spec never noticed. Today a customer at 23:00 is told the hours; after P2 they would get "a human will follow up" with no timeframe and a ten-hour wait.

**Fix:** the OOO text is **moved, not deleted.** `inbox.out_of_office_message` is blanked (so the template cannot fire first) but `working_hours_enabled` stays **on**, and the same Thai text is stored in `hook.settings['after_hours_note']`. `ReplyService` appends it when `inbox.out_of_office?` — that is a read of the inbox, not a gate on it, so §9.4's "no business-hours gating" is untouched and A1 is not violated. Net effect: one message instead of two, same information. Blanking the greeting is a separate product decision and needs owner sign-off (Owner decision **O-1**).

### C7 — the deny-list eats the corpus's own flagship question — **FIXED**
*(R1 B6, R3 B7)*

`THAI_TERMS[:human]` contained the bare substrings `ติดต่อทีมงาน` and `เจ้าหน้าที่`, and §8.3's worked FAQ entry is `q: "ติดต่อทีมงาน MU Today ได้ช่วงเวลาไหน"` — the deny-list contained the corpus's headline question verbatim, so that answer could never ship. `ลิขสิทธิ์` in `legal` caught routine PR/photo-permission questions. `เสียหาย` appeared in both `money` and `complaint`, and `thai_topic` returns the first hash match, so its telemetry label was silently wrong.

**Fix:**
- **Hard-stop groups are now `money`, `legal`, `complaint`, `crisis`, `credential` only** — the topics where a wrong model answer is dangerous.
- `human` is kept but narrowed to unambiguous escalation only: `คุยกับคน · คุยกับเจ้าหน้าที่ · ขอเจ้าหน้าที่ · ต่อเจ้าหน้าที่ · คุยกับแอดมิน · ขอแอดมิน · คุยกับพนักงาน`. **Removed:** `ติดต่อทีมงาน · ติดต่อแอดมิน · ติดต่อเจ้าหน้าที่ · เจ้าหน้าที่ (bare) · เบอร์โทร · ขอเบอร์ · สายด่วน · คอลเซ็นเตอร์` — those are information requests and belong to the corpus.
- **Removed from `legal`:** `ลิขสิทธิ์ · ละเมิดลิขสิทธิ์ · ข้อมูลส่วนบุคคล`. Kept: `ทนาย · ฟ้องร้อง · จะฟ้อง · ดำเนินคดี · แจ้งความ · สคบ · หมิ่นประมาท · คุ้มครองผู้บริโภค · ลบข้อมูลของฉัน`.
- `เสียหาย` de-duplicated (kept in `complaint` only).
- ASCII `agent` and `claim` removed (fire on ordinary English, buy nothing the Thai terms don't).
- `NON_MATCHING_FIXTURES` becomes a **real frozen constant** in `deny_list.rb`, and two mechanical checks enforce the term-addition rule: a spec asserting no term is a substring of any fixture, and an importer validation asserting **no deny term is a substring of any corpus `q` or alias** (this is the check that would have caught the original bug).

### C8 — the routed body promises a handoff the code is forbidden to perform — **FIXED**
*(R3 B3)*

Correct, and it violated the spec's own rule 29. The only trace of a deny-list hit was a jsonb key no agent view surfaces.

**Fix:** a deny-list hit now writes a **conversation label** so the promise is true and agents can filter: `ai-ส่งต่อเจ้าหน้าที่` for money/legal/complaint/human/credential, `ai-เร่งด่วน` for crisis. Verified D6-safe (see C4). The copy is also softened to claim only what happens.

### C9 — crisis is detected and then ignored — **FIXED**
*(R3 B8; Appendix A item B is withdrawn as an owner-preference item)*

Shipping the crisis term list with no crisis response is worse than not detecting it, because detection creates the impression the case is handled.

**Fix:** a distinct `CRISIS_BODY` ships in v1 with a real 24-hour referral (Thai Department of Mental Health hotline **1323**), plus the `ai-เร่งด่วน` label. Wording needs owner (or Mahidol student-affairs) sign-off before go-live — Owner decision **O-2**. If nobody will own it, the `crisis` group is deleted entirely; detect-and-ignore is not an option.

### C10 — `JSON.parse(response.content)` raises `TypeError` on every successful classification — **FIXED**
*(R3 B1)*

Verified in the unpacked gem at `ruby_llm-1.15.0/lib/ruby_llm/chat.rb:172-177`: when a schema is set, ruby_llm already does `response.content = JSON.parse(response.content)`. So `response.content` is a **Hash**, and `JSON.parse(<Hash>)` raises `TypeError: no implicit conversion of Hash into String` — on 100% of matched traffic, escaping a rescue list that never mentioned `TypeError`.

**Fix:** `raw = response.content; raw = JSON.parse(raw) if raw.is_a?(String)`. And `Classifier#classify` now rescues **`StandardError`**, not an enumerated list — §6.6 is documentation, not a rescue clause. Stated explicitly so the next unlisted error class cannot do this again.

### C11 — the one reply gets burned on "สวัสดีครับ" — **FIXED**
*(R3 B2)*

Thai LINE users greet first and ask second. G7 fired on the greeting, claimed the 24-hour marker, and went permanently silent on the actual question — so the classifier would only ever see "สวัสดีครับ" and §8.4's whole learn-then-write-the-corpus argument collapsed.

**Fix, and it simplifies the gate:**
- **G7 (`messages.id <` first-inbound) is deleted.** Its concurrency job is already done atomically and correctly by G9's `SET NX`; its scoping job is done by G8. It only ever added the greeting bug.
- **New G7′ — noise deferral.** If the normalised message is ≤ 2 code points or matches a bare-greeting list (`สวัสดี · หวัดดี · ดีครับ · ดีค่ะ · ดีคับ · สอบถาม · ขอสอบถาม · ครับ · ค่ะ · โอเค · hi · hello · hey`), increment `MUTODAY_FAQ_REPLY::DEFER::<conversation_id>` (TTL 24 h) and **skip without claiming the marker**, so the next inbound message is treated as the first. After **2** deferrals we reply anyway with the plain acknowledgment, so a greeting-only customer is never left in silence. Precedent: jodjam's `isNoiseDm` (`src/lib/dm-commands.ts:105-108`), which exists because this exact bug shipped there.
- Non-text (photo-first) is **not** deferred — a photo is a complete attempt to reach us and waiting cannot improve it. It gets the acknowledgment, `route=non_text`.

### C12 — the AI disclosure is factually false on three of four paths, and on 100% of day-one traffic — **FIXED**
*(R3 B4)*

§8.4 says plainly that an empty corpus means "no model call, no API token used, no network at all"; same for `denylist` and `non_text`. Stamping "[ตอบอัตโนมัติด้วย AI]" on a static Ruby constant mislabels in the opposite direction, and E2 would have "proved" 100% disclosure coverage on a system containing no AI.

**Fix:** two constants, enforced identically in Ruby, chosen by the recorded route — never by the model:
- `AI_DISCLOSURE = '[ตอบอัตโนมัติด้วย AI]'` when the model actually ran (`model`, `model_low_confidence`, `model_no_match`, and every `model_*` failure route).
- `AUTO_DISCLOSURE = '[ข้อความอัตโนมัติ]'` when it did not (`no_corpus`, `non_text`, `denylist`, `crisis`, `noise_forced`).

This is **stronger** than D1, not a departure from it: when the AI speaks, the AI label still ships, unconditionally, from Ruby. E2 and success criterion 5 are rewritten to assert that the prefix **matches the recorded route**, which is the check that actually tests D1. An owner who wants a single label collapses the two constants to the same string — a one-line change (Owner decision **O-3**).

### C13 — the compliance property was asserted on the wrong string — **FIXED**
*(R2 B2)*

The specs tested `Copy.matched` and E2 tested `messages.content`; neither is what reaches the customer. The wire value is `message.outgoing_content` → `MessageContentPresenter` → `Messages::MarkdownRendererService#render_line`, which replaces every `\n{2,}` with a literal `{{PRESERVE_n_NEWLINES}}` token and then CommonMark-parses the result, so the label, the answer and the handoff line become one CommonMark paragraph and `LineRenderer` rewrites nodes inside it (`link` → bare URL, `list_item` → children with the marker dropped, `strong` → ` *x* `). Verified in `app/services/messages/markdown_renderer_service.rb:79-105` and `app/services/messages/markdown_renderers/line_renderer.rb`.

**Fix:** a spec builds a real `Message` and asserts `MessageContentPresenter.new(message).outgoing_content.start_with?(<expected prefix>)`, with fixtures whose FAQ answer contains a list, a markdown link and a code span. E2 and criterion 5 are additionally checked pre-render on `messages.content` (cheap, SQL-able) — both, not either.

### C14 — Redis unavailability is undefined behaviour on the path every guard funnels through — **FIXED**
*(R2 B3; R1 "Missing" #1)*

**Fix, written down:** `Eligibility` and `RateLimiter` rescue `Redis::BaseError` and **fail closed** — skip, `outcome=failed stage=redis`, Sentry under its own dedup key. The job declares `discard_on Redis::BaseError` so it cannot retry-storm into the dead set. Full job retry policy is now specified (see C17).

### C15 — the 3-per-hour contact limit fires in ordinary use — **FIXED**
*(R2 B6)*

With `lock_to_single_conversation = false` (P3, required), every agent resolve means the customer's next message opens a **new** conversation and earns a new reply, so a student asking four questions in an hour trips the breaker on the fourth. A3 requires limits set so generously that normal operation never touches them.

**Fix:** contact limit raised **3 → 12 per rolling hour**. The other three are re-derived from the LINE inbox's observed conversation-open rate during shadow, not from intuition, and the final numbers are set as part of the shadow gate (see §3, item G8).

### C16 — an inbox-scope breach silences an innocent customer — **PARTIALLY REJECTED**
*(R3 B9 second half)*

**REJECTED:** the proposal that an inbox-scope breach should still send the fallback. The failure the inbox breaker exists to contain is a loop that spans conversations; a breaker that still sends contains nothing and is decoration. Per-conversation and per-contact loops are already contained atomically by G2 + G9 + the contact cap, so the inbox breaker is the only thing left standing between a cross-conversation bug and a machine-gunned inbox. It withholds.

**FIXED, the legitimate half:** a trip is never quiet. Every scope — inbox included — now writes the Thai private note in the affected conversation (private notes cost no LINE push and create no reporting effect), on top of the `error` log and the Sentry capture. R1's worry about "hundreds of notes" is inverted: if the inbox breaker fires 500 times, 500 notes is exactly the alarm you want, and it is the only signal an agent sees without shell access.

### C17 — `MutodayFaqReplyJob` has no retry policy — **FIXED**
*(R1 nit #1, R2 "Missing" #1)*

Every idempotency and fail-closed argument in §4 rested on this and it was never written. **Fix, explicit:**

```ruby
queue_as :high
discard_on ActiveJob::DeserializationError   # inherited: the Message row is gone
discard_on Redis::BaseError                  # C14 — fail closed, never storm
retry_on ActiveRecord::RecordInvalid, attempts: 1   # i.e. do not retry; log and stop
# everything else: no retry_on → bubbles to Sidekiq (:max_retries: 3)
```
G8 makes a post-success retry safe (our own reply is a `template`, so the retry is blocked there), and G9's `Redis::Alfred.get(key) == message.id.to_s` fallback lets a retry of *this* message through while blocking a different message.

### C18 — `rake mutoday:faq:import` cannot do what §15.15 claims, and silently reverts live edits — **FIXED**
*(R3 B10)*

The mirror is baked into the image, there is no editor in the container, and after `./build.sh` the in-container file reverts to whatever is committed — so an import after a deploy silently overwrites entries someone added live. Same failure class as CLAUDE.md's invalid-index warning: reports success, destroys data.

**Fix:**
- `mutoday:faq:import[path]` takes a path argument, defaulting to the mirror. The documented workflow is `docker cp corpus.yml <container>:/tmp/ && rake "mutoday:faq:import[/tmp/corpus.yml]"`.
- New `mutoday:faq:diff` compares live `hook.settings['faq']` against a file and prints the delta; `doctor` calls it and warns on divergence.
- **`import` refuses to run when the hook holds ids the file lacks**, unless `FORCE=1`. That is the guard against post-deploy reversion.
- §15.15's acceptance step is rewritten to time that actual sequence on the server.

### C19 — remaining "Missing" and nit items — **all FIXED unless noted**

| Item | Verdict |
|---|---|
| E6 ("reporting untouched") has no query | **FIXED** — given SQL in §3 G5. |
| Duplicate corpus `id`s | **FIXED** — importer blocking validation with per-entry error text; `resolve` uses first match, which uniqueness makes unambiguous. |
| Distinguish "blocked by greeting" from "human answered" | **FIXED** — see C5, `guard=foreign_template` vs `guard=already_answered`. |
| LINE `status: failed` is counted but nothing acts on it | **PARTLY DEFERRED** — the query joins the standing checks and the weekly review; automated alerting is Deferred (§5). |
| LINE webhook redelivery | **FIXED** — `messages.source_id` has only a non-unique index, so a redelivery creates a second incoming row; G9's `SET NX` contains it, and a spec asserts two runs on two rows produce one reply. |
| Bad-import recovery | **FIXED** — `diff` + `FORCE=1` refusal + the git mirror's own history. |
| Liquid post-condition on stored `content` | **FIXED** — `Copy` strips `{{ }} {% %}` and a spec asserts the persisted `content` still starts with the expected prefix after `before_create` Liquid. |
| FormKit `'default'` is not a prop | **FIXED** — use `value`, and `shadow` is listed first so a fallback to option #1 is still safe. |
| Rake constants/methods leak onto `Object` | **FIXED** — wrapped in a `MutodayFaq` module in `lib/tasks/`. |
| `grep log/production.log` is vacuous under Docker | **FIXED** — `docker compose logs rails \| grep -c 'sk-'`. |
| `MAX_BODY` truncation unreachable (importer caps `a` at 1200 < 1800) | **FIXED** — `MAX_BODY` lowered to 1200 so the branch is reachable, and the spec fixture matches. |
| Redundant `ลิขสิทธิ์`/`ละเมิดลิขสิทธิ์` under `Regexp.union` | **FIXED** — both removed (C7). |
| `NON_MATCHING_FIXTURES` was prose, not a constant | **FIXED** (C7). |
| Factory `hook_type { :inbox }` is a dead line | **FIXED** — removed; `ensure_hook_type` overwrites it from apps.yml. `hook.rb:29`'s `validates :inbox_id, presence: true, if: hook_type == 'inbox'` is now called out in the design as the thing preventing G0a from degrading to all-inboxes. |
| `visible_properties: ['mode']` buys nothing (no settings UI) | **ACCEPTED, documented** — kept for API introspection; the runbook says `rake mutoday:faq:doctor` is how you read the live mode. |
| §15.16 "byte-identical" YAML round-trip | **FIXED** — assert semantic equality of parsed structures. |
| Criterion 20 claims 2 upstream files, table lists 5 | **FIXED** — restated as *2 upstream Ruby files* (`hook_job.rb`, `hook_listener.rb`) plus 3 append-only config/spec files. |
| Sidekiq queue-load model | **NOT FIXED — accepted as unquantified.** No throughput model is offered. Criterion 13 (5 s median / 12 s p95) is therefore treated as an *observation* during shadow, not a design guarantee; if shadow shows p95 > 12 s, the fix is a dedicated queue, and that is scoped in §5. |
| No agent-facing guidance | **FIXED** — task T14 ships a one-paragraph agent note. |
| Repeat-customer exposure (same canned line every resolved conversation, forever) | **DEFERRED** — §5, with the standing query to measure it during shadow. |
| Post-launch quality loop beyond E7 | **DEFERRED** — §5. |
| The LINE OA's own platform-level greeting (outside Chatwoot) | **FIXED** — added to `doctor`'s printed manual checklist and to T15. |

---

## 2. Ordered task list

Tags: **[CODE]** this repo · **[SERVER]** production configuration · **[OWNER]** content/curation the owner must do.

Ordering rule: the three things that could invalidate the design — the ruby_llm response shape, the rendered-output compliance property, and the untested `hook_type: inbox` + `allow_multiple_hooks: false` UI combination — are T1 and T2. Every commit after T3 leaves the repo shippable.

| # | Title | Tag | Files | Done means | Deps | Est |
|---|---|---|---|---|---|---|
| **T1** | Spike: prove the three uncertain mechanics | **[CODE]** (throwaway) | scratch spec, not committed | Three assertions pass in `rails console`/a scratch spec and are pasted into the PR: **(a)** with `.with_schema(<plain Hash>)`, `response.content` is a `Hash` (confirms C10); **(b)** a `message_type: :template, sender: nil` message on a LINE conversation leaves `waiting_since` unchanged, `first_reply_created_at` nil, and the conversation in `Conversation.unattended`; **(c)** `MessageContentPresenter#outgoing_content` on `"[X]\n\nbody\n\nhandoff"` still starts with `[X]`. Any failure re-opens the design before code is written. | — | 2h |
| **T2** | Register the integration app and prove the dashboard can create the hook | **[CODE]** | `config/integration/apps.yml`, `config/locales/en.yml`, `public/dashboard/images/integrations/mutoday_faq_reply{,-dark}.png` | On a local dev server the card appears under Settings → Integrations with a real name (no `translation missing`), Connect opens a form with **API Token**, **Mode** (Shadow first, via `value:` not `default:`) and an **inbox picker**, and saving against the local LINE inbox creates an `integrations_hooks` row with `hook_type: 'inbox'` and `inbox_id` set. `Inbox#active_bot?` is still `false` afterwards. | T1 | 2h |
| **T3** | Upstream wiring + job shell (logs only, sends nothing) | **[CODE]** | `app/listeners/hook_listener.rb` (+1), `app/jobs/hook_job.rb` (+1, +6), `app/jobs/mutoday_faq_reply_job.rb` (new), `spec/factories/integrations/hooks.rb` (new trait) | An inbound LINE message produces exactly one `[mutoday_faq_reply] outcome=noop` log line; a message on any other inbox produces none. `git diff develop --stat -- app/jobs/hook_job.rb app/listeners/hook_listener.rb` shows 2 files / +8 lines. Job declares the full C17 retry policy. | T2 | 1.5h |
| **T4** | `Copy` — the frozen Thai constants and the two disclosures | **[CODE]** | `lib/integrations/mutoday_faq_reply/copy.rb`, `spec/lib/integrations/mutoday_faq_reply/copy_spec.rb` | Specs pass: every builder starts with its **route-appropriate** prefix (C12); Liquid delimiters are stripped from a supplied answer; `AI_DISCLOSURE`/`AUTO_DISCLOSURE` contain none of `{{ }} {% %} ** # \``; a 3000-char answer truncates to `MAX_BODY = 1200` and still starts with the prefix; **and the rendered-output spec of C13 passes** — a real `Message` through `MessageContentPresenter` still leads with the prefix, with a fixture answer containing a list, a link and a code span. | T3 | 2h |
| **T5** | `DenyList` — corrected term groups + mechanical guardrails | **[CODE]** | `lib/integrations/mutoday_faq_reply/deny_list.rb`, `spec/lib/integrations/mutoday_faq_reply/deny_list_spec.rb` | Specs pass: 3+ phrasings per group return the right symbol; **all 15 `NON_MATCHING_FIXTURES` return `nil`** (the Thai word-boundary regression test); politeness particles strip (`ขอเงินคืนหน่อยครับ` → `:money`); ASCII terms respect `\b`; `nil`/`''` don't raise; **no term is a substring of any fixture**; **`ติดต่อทีมงาน MU Today ได้ช่วงเวลาไหน` returns `nil`** (the C7 regression); `เสียหาย` returns `:complaint` exactly once. | T3 | 3h |
| **T6** | `Eligibility` — the gate, the deferral counter, the Redis policy | **[CODE]** | `lib/integrations/mutoday_faq_reply/eligibility.rb`, `.../eligibility_spec.rb` | One spec per guard, each asserting its own rejection label: rejects `outgoing`; **rejects `template` (our own reply cannot re-trigger us)**; rejects `activity`; rejects blank `source_id`; rejects a `User` sender; rejects a non-LINE inbox with `misconfigured`; rejects `mode: off`; rejects when an outgoing or template message exists — and **distinguishes `foreign_template` from `already_answered`** (C5); accepts a clean first LINE text message; **defers a bare greeting without claiming the marker, and stops deferring after 2** (C11); `Redis::BaseError` fails closed with `stage=redis` (C14). | T3 | 4h |
| **T7** | `RateLimiter` — three-state reservation | **[CODE]** | `lib/integrations/mutoday_faq_reply/rate_limiter.rb`, `.../rate_limiter_spec.rb` | Specs pass: allows to the limit, returns `:limited` at limit+1; **a refused reservation does not increment**; TTL set on first increment; **two concurrent reserves both return `:ok` while capacity remains** (C3); a simulated WATCH abort returns `:contended` and is retried, never `:limited`. Contact limit is 12/h (C15). | T3 | 2.5h |
| **T8** | `Telemetry` — structured log, deduped Sentry, never raises | **[CODE]** | `lib/integrations/mutoday_faq_reply/telemetry.rb`, `.../circuit_breaker_tripped.rb` | The logger accepts only the fixed keyword set (no parameter can carry a content string); a raise inside Sentry capture does not propagate; the alert dedup slot is keyed per *kind*. Closed sets for `outcome` and `guard` are frozen constants. | T3 | 1.5h |
| **T9** | `ReplyService` — day-one path, no model, shadow-capable | **[CODE]** | `lib/integrations/mutoday_faq_reply/reply_service.rb`, `.../reply_service_spec.rb`, `app/jobs/mutoday_faq_reply_job.rb` | **This is the first shippable increment.** Specs pass, classifier absent: **D6 regression** (`inbox.active_bot?` false, status `open`, no `AgentBotInbox`); disclosure present and route-matched; `message_type == 'template'`, `sender_id` nil, `content_type == 'text'`, no `source_id`; **reporting untouched** (`waiting_since` unchanged, `first_reply_created_at` nil, still `unattended`) — this replaces `preserve_waiting_since`, which is deliberately not passed; empty corpus → reply created with `route == 'no_corpus'`; non-text → `route == 'non_text'`; **G8 re-checked immediately before create** (C2) with `guard=human_replied_during_classify`; idempotent (two runs → one row); shadow → `private == true`; telemetry lands in **`additional_attributes`** (C1); the customer's text never appears in a logged line. | T4, T5, T6, T7, T8 | 4h |
| **T10** | Deny-list routing: labels, crisis body, after-hours note | **[CODE]** | `reply_service.rb`, `copy.rb`, `apps.yml` (`after_hours_note` key), `.../reply_service_spec.rb` | Specs pass: a money term → `route == 'denylist'`, `deny_topic == 'money'`, routed body, no classifier call, **and the conversation carries `ai-ส่งต่อเจ้าหน้าที่`** (C8); a crisis term → `CRISIS_BODY` containing `1323` and the `ai-เร่งด่วน` label (C9); **`conversation.reload.status` is still `'open'` after both** (D6 with labels); with `after_hours_note` set and `inbox.out_of_office?` stubbed true, the note is appended (C6). | T9 | 3h |
| **T11** | `Classifier` — the only file that touches the network | **[CODE]** | `lib/integrations/mutoday_faq_reply/classifier.rb` | `request_timeout = 8`, `max_retries = 0`, `api_base` passed explicitly (never nil-ed), plain-Hash strict schema, `raw = response.content; raw = JSON.parse(raw) if raw.is_a?(String)` (C10), **`rescue StandardError` returning `nil`** so it can never raise into the job. Prompt and payload wrap both the corpus and the customer text in the untrusted-data delimiters; only `id`/`q`/`aliases` are sent, never `a`. **The rendered corpus payload is capped** (C19 nit) at 20 000 chars. Verified against the real API once, by hand, with the spike token. | T1, T9 | 3h |
| **T12** | Wire the classifier into `ReplyService` | **[CODE]** | `reply_service.rb`, `.../reply_service_spec.rb` | Specs pass with the classifier stubbed: matched → the corpus answer ships, `outcome == 'matched'`; confidence 0.4 → `model_low_confidence`; invented id → `model_invalid_id`; classifier returns `nil` → **a reply is still created** (the A2 no-silence guarantee); every `model_*` route carries `AI_DISCLOSURE`, every non-model route carries `AUTO_DISCLOSURE` (C12). `rubocop` clean — Cyclomatic ≤ 7 (split early; the guard chain is in `Eligibility`, body selection is one small `case`). | T11 | 2h |
| **T13** | Rake tasks: `doctor · export · import[path] · diff · mode` | **[CODE]** | `lib/tasks/mutoday_faq_reply.rake` | `doctor` exits non-zero on any of P1–P4, on a non-LINE inbox, on `active_bot?`, on an invalid corpus, on an unresolvable model id, on a Redis round-trip failure, and prints the **manual** checklist item for the LINE OA's own platform greeting. `import[path]` takes a path, validates every entry (id pattern, id uniqueness, plain-text `a` including line-leading `-`/`*`/`1.`/`>`, no Liquid, ≤1200 chars, **no deny term is a substring of any `q`/alias**), merges rather than replacing settings, and **refuses when the hook holds ids the file lacks unless `FORCE=1`** (C18). `diff` prints the delta. `mode[live\|shadow\|off]` prints old → new. Constants and helpers live in a `MutodayFaq` module, not on `Object`. | T12 | 3h |
| **T14** | Git mirror, runbook, agent-facing note | **[CODE]** | `config/mutoday_faq_corpus.yml`, `mu-support/README.md` (or the repo runbook) | `export` then `import` round-trips to semantic equality. The runbook covers: the `docker cp` + `import[path]` workflow, `doctor` as the only way to read the live mode, the standing SQL (all bounded by `created_at`, all run via `docker compose exec -T postgres psql -d chatwoot_production`), and **one paragraph for agents**: what the AI bubble looks like, that it is not a colleague's reply, that the conversation is still theirs to answer, and what the two labels mean. | T13 | 1.5h |
| **T15** | Pre-flight the production LINE inbox (read-only) | **[SERVER]** | none | Recorded from production: `greeting_enabled`, `greeting_message`, `out_of_office_message`, `working_hours_enabled`, `lock_to_single_conversation`, any `AgentBotInbox`, any enabled `dialogflow` hook, and **whether the LINE OA Manager's own platform greeting is on**. Plus the baseline the shadow gate compares against: 14 days of `reply_time` median and `unattended` count for the LINE inbox, and the conversation-open rate per hour and per day (this is what C15's breaker numbers are derived from). | T14 | 1h |
| **T16** | Deploy the code (no version bump, no migration) | **[SERVER]** | none | `rsync -av --exclude .git --exclude backups --exclude src <mu-support>/ root@<server>:/opt/mu-support/`, then `nohup ./build.sh <version>-mutoday > build.log 2>&1 &`, then `docker compose up -d`. Verified: `curl -s https://support.mutoday.com/api` reports `queue_services` and `data_services` both `ok`; `SELECT count(*) FROM pg_index WHERE NOT indisvalid` returns 0; the integration card appears in the dashboard. No `upgrade.sh` — the Chatwoot version has not moved. | T15 | 1h + build |
| **T17** | Blank the greeting / OOO and move the OOO text into settings | **[SERVER]** + **[OWNER]** sign-off | none | Owner has signed off on switching the inbox greeting off (**O-1**). `out_of_office_message` blanked, `working_hours_enabled` left **on**, the same Thai text stored in `hook.settings['after_hours_note']`. `rake mutoday:faq:doctor` exits 0. | T16, O-1 | 0.5h |
| **T18** | Connect the hook in Shadow mode | **[SERVER]** | none | Dashboard → Integrations → Connect, with the OpenAI token, Mode = **Shadow**, Inbox = the LINE OA. Then `rake mutoday:faq:doctor` exits 0 with the hook present, and `docker compose logs rails \| grep -c 'sk-'` returns 0 (C19 — the credential never hit a log). | T17 | 0.5h |
| **T19** | Write the crisis body and get it approved | **[OWNER]** | `copy.rb` (one constant) | The Thai crisis wording, including the 1323 referral, is approved by the owner or Mahidol student affairs, in writing. **Blocks go-live** (C9). | T4 | owner |
| **T20** | Write the real Thai corpus entries | **[OWNER]** | `config/mutoday_faq_corpus.yml` | ≥ 5 entries whose `a` text is real MUToday copy, each passing the T13 importer validations. Written **from what agents actually answered during the shadow window**, not guessed in advance (§8.4 argument 3). | T18, shadow week 1 | owner |
| **T21** | Import the corpus and re-run the shadow window | **[SERVER]** + **[OWNER]** | none | `docker cp` + `rake "mutoday:faq:import[/tmp/corpus.yml]"`, `doctor` exits 0, timed and recorded as the §15.15 acceptance step. The shadow clock restarts for the model-in-the-path evidence. | T20 | 0.5h |

**Total engineering: ~33 h** across T1–T16, plus owner time on T19–T21.

---

## 3. Shadow mode gate

The bot may not speak to a real customer until **every** item below is satisfied and recorded. All SQL runs as `docker compose exec -T postgres psql -U postgres -d chatwoot_production -c "..."` — never through Rails (14 s `statement_timeout`) — and every query is bounded by `created_at` because there is no index on `additional_attributes` (C1).

**G1 — Volume and duration.** ≥ 200 shadow replies over ≥ 7 consecutive days including a weekend, and — after T21 — ≥ 100 more with the corpus loaded.
```sql
SELECT count(*) FROM messages
WHERE created_at > now() - interval '30 days'
  AND additional_attributes -> 'mutoday_faq_reply' ->> 'shadow' = 'true';
```

**G2 — The disclosure shipped, and matched its route** (C12; this is the D1 proof). Must return 0:
```sql
SELECT count(*) FROM messages
WHERE created_at > now() - interval '30 days'
  AND additional_attributes ? 'mutoday_faq_reply'
  AND CASE WHEN additional_attributes -> 'mutoday_faq_reply' ->> 'route' LIKE 'model%'
           THEN content NOT LIKE '[ตอบอัตโนมัติด้วย AI]%'
           ELSE content NOT LIKE '[ข้อความอัตโนมัติ]%' END;
```
Plus the **rendered** check (C13): pick 10 rows at random, run `MessageContentPresenter.new(Message.find(id)).outgoing_content` in `rails runner`, confirm each still leads with its prefix.

**G3 — Never more than one per conversation.** Must return 0 rows:
```sql
SELECT conversation_id, count(*) FROM messages
WHERE created_at > now() - interval '30 days' AND additional_attributes ? 'mutoday_faq_reply'
GROUP BY conversation_id HAVING count(*) > 1;
```

**G4 — Never talked over a human.** Must return 0 rows (this is the C2 fix under test):
```sql
SELECT m.id, m.conversation_id FROM messages m
WHERE m.created_at > now() - interval '30 days'
  AND m.additional_attributes ? 'mutoday_faq_reply'
  AND EXISTS (SELECT 1 FROM messages p
              WHERE p.conversation_id = m.conversation_id
                AND p.message_type = 1 AND p.id < m.id);
```

**G5 — LINE only, never `pending`, reporting untouched.** Each must return 0 (the third is the C19 fix for E6's missing query):
```sql
SELECT count(*) FROM messages m JOIN inboxes i ON i.id = m.inbox_id
WHERE m.created_at > now() - interval '30 days'
  AND m.additional_attributes ? 'mutoday_faq_reply' AND i.channel_type <> 'Channel::Line';

SELECT count(*) FROM conversations c JOIN inboxes i ON i.id = c.inbox_id
WHERE i.channel_type = 'Channel::Line' AND c.status = 2;

SELECT count(*) FROM conversations c
WHERE c.id IN (SELECT conversation_id FROM messages
               WHERE created_at > now() - interval '30 days'
                 AND additional_attributes ? 'mutoday_faq_reply')
  AND c.first_reply_created_at IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM messages h WHERE h.conversation_id = c.id
                    AND h.message_type = 1 AND h.sender_type = 'User');
```
And, against T15's baseline: the LINE inbox's `reply_time` median and live-reports `unattended` count are within normal variance of the 14 days before the feature was enabled.

**G6 — The fork's type-9 notification still fires.** With `all_conversations_new_message` subscribed, a new LINE conversation produces a `notifications` row with `notification_type = 9`. Checked by hand, once, during shadow. This is the D6 acceptance test and it is not substitutable by G5's `status = 2` query.

**G7 — The feature is not silently dead.** Must return 0 — no eligible LINE conversation from the last 24 h without an AI reply, and no `guard=foreign_template` in the logs (C5):
```sql
SELECT count(*) FROM conversations c JOIN inboxes i ON i.id = c.inbox_id
WHERE i.channel_type = 'Channel::Line' AND c.created_at > now() - interval '24 hours'
  AND NOT EXISTS (SELECT 1 FROM messages m WHERE m.conversation_id = c.id
                    AND m.additional_attributes ? 'mutoday_faq_reply');
```
```
docker compose logs rails --since 24h | grep -c 'guard=foreign_template'   # must be 0
```

**G8 — The breaker numbers are re-derived, not inherited.** Using T15's observed conversation-open rate, each of the four limits is confirmed at ≥ 5× observed peak, and **zero** `outcome=refused_rate_limit` lines appeared during the whole shadow window. A limit that fired is investigated as a defect before any number is touched (A3, C15).

**G9 — Latency observed.** Median inbound→AI-reply < 5 s and p95 < 12 s, measured over the shadow window. If p95 exceeds 12 s the cause is queue starvation, not the model, and the dedicated-queue work in §5 is pulled forward before go-live.

**G10 — Human read of 50.** The owner reads 50 randomly sampled shadow notes and judges **at most 2** "would have been wrong to send". With the corpus loaded, additionally **zero** money / legal / crisis messages that received `route=model` instead of `route=denylist` — a deny-list gap is fixed before promotion, never after.

**G11 — Crisis wording approved** (T19) and the two labels appear on the right conversations.

Any failure: fix, reset the clock, run another 7 days.

**Promotion:**
```bash
docker compose exec rails bundle exec rake mutoday:faq:doctor      # must exit 0
docker compose exec rails bundle exec rake "mutoday:faq:mode[live]"
```

---

## 4. Rollback

**Under one minute, no rebuild, no restart, no deploy, no data loss.**

```bash
ssh root@<server>
cd /opt/mu-support
docker compose exec rails bundle exec rake "mutoday:faq:mode[off]"
```

`mode[off]` merges `{'mode' => 'off'}` into `hook.settings`; G6 in the eligibility gate reads it on the very next inbound message. Nothing is enqueued, nothing is sent, the corpus and the API token are untouched, and `rake "mutoday:faq:mode[shadow]"` or `[live]` restores it just as fast.

**Escalation ladder, in order:**

| Situation | Action | Time |
|---|---|---|
| Copy is wrong / replies are unhelpful | `rake "mutoday:faq:mode[shadow]"` — the bot keeps producing private notes so you can see what it *would* say, and the customer sees nothing | ~20 s |
| Anything at all is wrong | `rake "mutoday:faq:mode[off]"` | ~20 s |
| One FAQ answer is wrong | edit the corpus file, `docker cp`, `rake "mutoday:faq:import[/tmp/corpus.yml]"` — no restart | ~2 min |
| The rake task itself is unavailable | Dashboard → Integrations → MUToday FAQ First Reply → **Disconnect**. This works with no shell, but **destroys the hook row and the entire corpus** — export first if there is any chance you will want it back | ~30 s |
| Last resort | `docker compose stop sidekiq` — stops all background work, including everything else Chatwoot does. Only if the box is on fire | ~10 s |

**Not a rollback path:** rebuilding the image. `build.sh` is a full source build and takes tens of minutes with ~4 GB of RAM. If a rebuild is ever the proposed fix for a live incident, `mode[off]` first, then rebuild at leisure.

**What rollback does not undo:** messages already sent to LINE. There is no recall. That is what the shadow gate is for.

---

## 5. Deferred / not in v1

| Item | Why it waits |
|---|---|
| **A dashboard edit affordance for `hook.settings`** | Needs an `updateHook` API call, a store action and an Edit button — the first frontend code in the feature, and it breaks the zero-frontend Lark shape D7 asks us to keep. Revisit when the corpus is being edited weekly. |
| **Automated action on LINE `status: failed`** | The query joins the standing checks and the weekly review in v1. Alerting, retry, or an agent-visible note on a rejected push is v2. |
| **Repeat-customer suppression** | With `lock_to_single_conversation = false`, a frequent contact gets the identical acknowledgment on every new conversation, forever. Measure it during shadow (`GROUP BY contact_id HAVING count(*) > 5` over 30 days); decide on a "skip if acknowledged in the last N days" rule only if the numbers justify it. |
| **A dedicated Sidekiq queue** | Inbound LINE runs on `default`, strictly below the `medium` and `high` queues this feature adds work to. No throughput model exists (C19). If G9 shows p95 > 12 s, this is pulled forward; otherwise it waits for evidence. |
| **Scheduled monitoring posting to Lark** | The loop and pending queries are the two worth automating, weekly. Not in the first release — a query nobody has run by hand yet should not be automated. |
| **Deferring a photo-first message** | A photo gets the acknowledgment immediately (C11). Whether a photo-then-text customer would be better served by waiting for the text is a real question, and one shadow will answer. |
| **CSAT / handling-time measurement of the feature's actual value** | Every success criterion in v1 measures "did not break anything". Whether the acknowledgment reduced agent handling time or follow-up volume needs a second measurement pass after 30 days live. |
| **A GIN index on `messages.additional_attributes`** | Requires `CREATE INDEX CONCURRENTLY` on the largest production table — the exact hazard CLAUDE.md documents. Only if `created_at`-bounded queries prove too slow in practice. |
| **Multi-turn, deflection, resolution, assignment** | Out of scope by D3, permanently. |

---

## 6. Owner decisions still open

Each has a recommended default so nothing blocks.

| # | Decision | Recommended default | Consequence of the default |
|---|---|---|---|
| **O-1** | **Switch the LINE inbox's greeting message off?** Required for the feature to work at all (C5) — the greeting fires synchronously and permanently blocks our reply. | **Yes, switch it off.** The AI acknowledgment replaces it and says strictly more. The OOO text is preserved via `after_hours_note` (C6), so nothing is lost there. | Blocks T17 and therefore go-live. If the answer is no, the feature cannot ship and the plan stops at T16. |
| **O-2** | **The crisis reply's exact Thai wording**, including whether the 1323 hotline referral is acceptable to publish from a Mahidol channel. | Ship the referral. `รับเรื่องไว้แล้วครับ เจ้าหน้าที่จะติดต่อกลับโดยเร็วที่สุด` + `ถ้าต้องการคุยกับผู้เชี่ยวชาญทันที โทรสายด่วนสุขภาพจิต 1323 ได้ตลอด 24 ชั่วโมงครับ` | If nobody will own a crisis response, the `crisis` term group is **deleted** — detect-and-ignore is not an option (C9). |
| **O-3** | **One disclosure label or two?** (C12) `[ตอบอัตโนมัติด้วย AI]` only when the model ran, vs. the same label on every automated reply. | **Two.** On day one, one label would put "AI" on a system containing no AI, and a label that means "canned" stops disclosing anything by the time a real model answer arrives. | Collapsing to one is a one-line change (set both constants to the same string). |
| **O-4** | **Thai politeness register.** Announcement voice (no particle) vs. pinned `ครับ`. | **`ครับ`.** It is the safe institutional default; particle-free Thai from a university OA reads machine-translated, which undercuts exactly the trust the disclosure is meant to build. | Four constants in `copy.rb`, nothing else. |
| **O-5** | **The four circuit-breaker numbers**, once T15's baseline exists. | Conversation 1 (ever) · contact **12**/h · inbox 60/h · inbox 500/day, then re-derived at ≥ 5× observed peak during the shadow gate (G8). | A breaker that fires in normal operation trains everyone to ignore the alert (A3). Never tune down "to be safe". |
| **O-6** | **Promote to live with an empty corpus first**, then import (splits the two risks cleanly, costs one extra week), or import during shadow and promote once. | **Empty corpus first.** It is the sequence §8.4 already argues for: burn in the dangerous machinery — the gate, the loop guards, the marker, the disclosure — under real traffic while the payload is a fixed Thai sentence, and write the corpus from what agents actually answered rather than from guesses. | T20/T21 shift a week later. |
| **O-7** | **Which OpenAI-compatible endpoint.** Today the feature reads the shared `CAPTAIN_OPEN_AI_ENDPOINT` installation config. | **Keep sharing it.** A second endpoint key in `hook.settings` is one schema line whenever it is actually needed. | None until someone wants a different gateway. |