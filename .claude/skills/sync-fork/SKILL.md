---
name: sync-fork
description: Use this skill when syncing one of our forks with its upstream — either pulling chatwoot/chatwoot into fazer-ai/chatwoot, OR pulling fazer-ai/chatwoot `main` into fazer-ai/chatwoot-pro (its `main`, checked out locally as `chatwoot-pro-main`). Covers per-file decision framework (KC/AI/CO/delete), recurring patterns (SaveBang, signature architecture, schema.rb regen, WhatsApp service, installation_config, Pro-only overrides), validation flow, and pre-commit/CI pitfalls specific to this repo. Trigger when the user asks to merge develop/main from chatwoot upstream, resolve merge conflicts on a merge branch, bump the fork to a new chatwoot version, or merge CE `main` into Pro. **Never assume the sync direction — always confirm with the user which side is upstream and which is the receiving fork before doing anything.**
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# Sync fork — (chatwoot → fazer-ai CE) and (fazer-ai CE → fazer-ai Pro)

> **Direction is never implicit.** Before reading any further, confirm with the user which sync flow this is: `chatwoot/chatwoot → fazer-ai/chatwoot` (CE merge) or `fazer-ai/chatwoot → fazer-ai/chatwoot-pro` (Pro merge). Both flows share most patterns but diverge on branch names, push targets, and which side is HEAD. Picking the wrong flow silently inverts the KC/AI decisions in every recurring pattern below — do not infer from context, ask.

The fazer-ai CE fork diverges from chatwoot upstream on real features (Baileys, Zapi, per-inbox signatures, scheduled messages, group conversations, internal chat). fazer-ai Pro further extends CE with Pro-only features (kanban, integrity reporting, protected subscription keys, configurable super-admin paywall URL, etc.). Every few releases we pull each level of upstream in to stay current. This skill captures the recurring patterns and footguns for **both** sync flows so the next merge doesn't rediscover them from scratch.

## Two merge flows this skill covers

### A) chatwoot/chatwoot → fazer-ai/chatwoot (CE merge)

Branch from our fork's `main`, merge `upstream/develop` (or a release tag like `chatwoot/develop`) into it via a `chore/merge-upstream-X.Y.Z` branch and PR.

- HEAD = fork (`main`), MERGE_HEAD = upstream.
- Same number of conflicts either way — git is symmetric.
- What differs: the `--first-parent` chain. Merging upstream into a fork-based branch keeps our main's first-parent history "our work", with upstream as a side merge. Easier to answer "what's ours" later with `git log --first-parent`.
- If the current in-progress merge already went the other direction, finish it as-is. Standardize on next merge.

### B) fazer-ai/chatwoot → fazer-ai/chatwoot-pro (Pro merge)

Switch to the local `chatwoot-pro-main` branch, pull it even with `chatwoot-pro/main`, then `git merge main --no-ff -m "Merge branch 'main' into chatwoot-pro-main"`. This is done directly on the Pro trunk (no PR), then pushed with `git push chatwoot-pro HEAD:main` along with the new `vX.Y.Z-fazer-ai-pro.N` tag.

⚠️ Pro's trunk is `main` on the `chatwoot-pro` remote; `chatwoot-pro-main` is only the local branch name, so it does not collide with CE's `main` (see **Pro repo gotchas** in `AGENTS.md`). **Never push the local branch by name**: `git push chatwoot-pro chatwoot-pro-main` recreates a stray remote `chatwoot-pro-main`, which is what collected every push for a month in 2026-08 while `main` went stale. Always `HEAD:main`.

- HEAD = Pro's trunk, MERGE_HEAD = CE (`main`).
- Pro is a strict superset of CE: every conflict is either "CE changed something we overrode" (usually KC/CO to preserve Pro behavior) or "CE added new code next to our additions" (usually CO).
- Recurring patterns below tagged **[Pro]** list files that conflict on almost every CE→Pro merge.

## How to use this skill (checklist)

When triggered on a merge, don't just read the file and wing it — walk the full flow:

1. Run the **Pre-flight** block.
2. For every conflicted file: apply the **Per-file decision framework**, cross-referencing the **Recurring patterns** subsection for that file when one exists.
3. Resolve and `git add` each file. Keep a running list of the KC/AI/CO/DEL decision per file (useful for the commit message and PR body).
4. Run the **Validation flow** end-to-end (it is mandatory, not optional). Do not commit if any step fails.
5. Run the **Mandatory subagent review** (see section below) — it is a required gate, not optional. Address every FAIL before merging.
6. Trigger the upstream CI on the branch (**Validate on upstream CI** section) and wait for green before merging.
7. Merge the CE sync PR with a **merge commit, never squash** (**Merging the sync PR** section), then verify the upstream tag is an ancestor of `main`.
8. For Pro merges, recall that pushing to `chatwoot-pro/main` is directly followed by tagging `vX.Y.Z-fazer-ai-pro.N` and cutting a release — coordinate with the `release-user-notes` skill (and its `PRIVACY.md` companion) before writing the release body.

## Pre-flight

**Before creating the sync branch (CE), check that the last synced upstream tag is still an ancestor of `main`:**

```bash
git merge-base --is-ancestor <last-synced-tag> main && echo "ancestry ok" || echo "ANCESTRY BROKEN — see below"
git merge-base main <new-tag> | xargs git log -1 --format='%h %s'   # this is the base the merge will use
```

If it says BROKEN, a previous sync PR was squashed and the merge you're about to run will base on a much older tag — replaying a whole version's diff and fabricating conflicts on every file the fork touched since. Restore the lost parent on the sync branch first (see **Repairing a squashed sync** below), then merge.

> **Precedent: v4.16.2 (PR #348), already repaired.** That PR was merged with `--squash`, so `v4.16.2` stopped being an ancestor of `main` — the merge base fell back to `00a50dd79c` (`Merge branch 'release/4.16.0'`), 52 commits behind, and GitHub reported `main` as 197 commits behind `chatwoot:develop`. Repaired on 2026-08-17 by commit `590ca10ebf`, which recorded the PR head `2efdd58b30` as a second parent with the recipe below (the squashed commit `0a29032c9f` had a byte-identical tree, so nothing on disk changed). `git rev-list --count main..v4.16.2` is now 0.

### Repairing a squashed sync

```bash
git checkout -b chore/merge-upstream-X.Y.Z main
git diff --stat <squashed-pr-head> <squash-commit>   # MUST be empty — proves the tree already contains that sync
git merge -s ours <squashed-pr-head> -m "chore: restore upstream vA.B.C ancestry (squashed in #NNN)"
git merge-base --is-ancestor vA.B.C HEAD && echo "link restored"
git merge vX.Y.Z    # now bases on vA.B.C instead of the stale tag
```

`-s ours` records the second parent without touching a single file — it does not re-apply anything, it only tells git what the tree already contains. If the `git diff --stat` above is NOT empty, stop: the squash and the branch diverged, and `-s ours` would permanently hide the difference. Resolve that by hand before merging.

After `git merge upstream/develop` (CE) or `git merge main` (Pro), before touching anything:

```bash
# list conflicted files
git diff --name-only --diff-filter=U

# confirm direction — who is HEAD (ours) vs MERGE_HEAD (theirs)
cat .git/MERGE_HEAD
head -5 .git/MERGE_MSG
git log --oneline HEAD -3
git log --oneline MERGE_HEAD -3

# for Pro merges, confirm the branch and remote before doing anything destructive
git branch --show-current   # should be chatwoot-pro-main (the local name of chatwoot-pro/main)
git remote -v               # should show `chatwoot-pro` remote pointing at fazer-ai/chatwoot-pro
```

> **PR/CI base-repo gotcha.** This repo is a fork of `chatwoot/chatwoot`, so `gh` defaults the PR base (and `gh workflow run` target) to the **parent (upstream)** unless a default is pinned — the CE merge's `chore/merge-upstream-X.Y.Z` PR can silently land on `chatwoot/chatwoot`. Pin it before pushing/PRing:
>
> ```sh
> gh repo set-default fazer-ai/chatwoot       # CE merge → PR/CI on the CE fork
> ```
>
> Or pass `--repo` explicitly on every `gh pr create` / `gh workflow run`. The Pro repo is on the Forgejo (`git.fazer.ai`) since 2026-11-05, so `gh` does not reach it at all: for the Pro merge use `forja` (fazer-ai-tools plugin, same syntax as `gh`) with `--repo git.fazer.ai/fazer-ai/chatwoot-pro` on every command.

Terminology used in this skill:
- **HEAD / current / ours** = the branch you're sitting on (the one receiving the merge).
- **MERGE_HEAD / incoming / theirs** = the branch being merged in.

If you're on a fork-based branch pulling upstream in: `HEAD` = fork, `MERGE_HEAD` = upstream.
If you're on an upstream-based branch pulling fork in (the less-preferred direction): `HEAD` = upstream, `MERGE_HEAD` = fork.

Read carefully which side is which before labeling decisions.

## Per-file decision framework

For each conflicted file, pick one of:

| Code | Meaning |
|------|---------|
| **KC** | Keep current (HEAD) — drop the incoming side |
| **AI** | Accept incoming (MERGE_HEAD) — drop the HEAD side |
| **CO** | Combination — merge both sides manually |
| **DEL** | Accept deletion — `git rm` (modify/delete conflict where one side deleted) |

Process:

1. Read the conflict markers to see what each side does.
2. `git log --oneline HEAD -5 -- <path>` and `git log --oneline MERGE_HEAD -5 -- <path>` — understand WHY each side changed it.
3. For modify/delete: `git ls-files -u <path>` shows which stages are present (1=base, 2=ours, 3=theirs).
4. For complex hunks: `git show HEAD:<path>` and `git show MERGE_HEAD:<path>` to see each full file.
5. Decide KC/AI/CO/DEL based on intent, not just diff.

**`enterprise/` and `spec/enterprise/` in an upstream → CE sync are always AI.** They stay byte-identical to the upstream release (`bin/validate_enterprise_parity`, run by CI and the pre-commit hook); the fork does not change Enterprise code, there or from outside it. After the merge, `git diff v<new> HEAD -- enterprise spec/enterprise` must be empty, and `bin/validate_enterprise_isolation` plus `bundle exec rspec spec/lint/enterprise_isolation_spec.rb` must pass: a new Enterprise method can land under a CE module that already wraps that class, and the runtime check is what notices. In a CE → Pro sync these paths cannot conflict at all, since neither side edits them.

## Recurring patterns in this repo

### Style/SaveBang noise

Our fork has `Rails/SaveBang: Enabled: true` in `.rubocop.yml`. Upstream doesn't enforce it as strictly. Consequence: when upstream touches any line near a persistence call, we see a conflict where our side says `save!`/`update!`/`destroy!`/`create!` and theirs says the non-bang version.

The cop flags more than just `save`. Full list it tries to add `!` to: `save`, `update`, `update_attributes`, `destroy`, `create`, `create_or_find_by`, `find_or_create_by`, `find_or_initialize_by`, `first_or_create`, `first_or_initialize`. Any of these can appear in a conflict.

- Most are **trivial** style churn from our fork's rubocop autofix, no semantic change.
- **Never blindly accept the bang rewrite (or run `rubocop -A`) without evaluating each offense individually.** The cop doesn't check the receiver's class — it matches by method name alone. Non-ActiveRecord receivers (POROs, service objects with their own `save`/`update`/`destroy` method, third-party libraries like Stripe, Kredis, OpenStruct wrappers, CSV/IO objects with `update`, filesystem objects with `destroy`) will raise `NoMethodError` at runtime. Caught by CI if there's a spec, silently broken in prod if not.
- For each SaveBang offense, read the surrounding code: what class is the receiver? If it's an ActiveRecord model, the autocorrect is safe. If it's anything else, either add the receiver to `.rubocop.yml`'s `Rails/SaveBang.AllowedReceivers` list (currently Stripe::Subscription, Stripe::Customer, Stripe::Invoice) or add a targeted `rubocop:disable Rails/SaveBang` comment.
- Safe workflow: run `bundle exec rubocop <files>` (without `-A`) first to see the offenses listed, evaluate each individually, then apply `-A` only once you've confirmed every receiver is an ActiveRecord object. Always review the diff before committing.
- **Specs trap (4.14.2 merge):** receiver class is not enough — check INTENT. Upstream specs often call non-bang `update(...)` on purpose to assert validation failures right after (`expect(portal).not_to be_valid`). `rubocop -A` rewrites them to `update!` and the test now raises instead of failing validation. For those, keep `update` with an inline `# rubocop:disable Rails/SaveBang` (existing fork pattern in `spec/models/portal_spec.rb`).

### Signature architecture (PR #79)

We deliberately removed upstream's editor-side signature manipulation (`addSignature`, `removeSignature`, `toggleSignatureInEditor`, signature-in-draft logic) and moved signature application to **send-time** (`getMessagePayload`). This prevents signature duplication, persistence in drafts, and position-toggle bugs.

When upstream adds or tweaks any signature-related code in:
- `app/javascript/dashboard/components/widgets/WootWriter/Editor.vue`
- `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue`
- `app/javascript/dashboard/routes/dashboard/settings/profile/MessageSignature.vue`

→ Usually **AI (accept incoming = our fork)**, preserving the send-time architecture. Upstream's "fixes" may be rebuilding exactly what we tore out.

One exception worth porting as follow-up (NOT during merge): upstream's inline-image sanitization (`stripInlineBase64Images` + `INLINE_IMAGE_WARNING` i18n key) is orthogonal to architecture and would be a nice safety net in our send-time code.

### WhatsApp incoming message service

`app/services/whatsapp/incoming_message_base_service.rb` is the other frequent conflict zone. Our fork has two-layer locking (source_id lock + contact phone lock) plus a contact-level re-check for slow networks. Upstream evolves its simpler dedup logic.

Decision: **CO (combination)**. Keep the fork's `acquire_message_processing_lock` + `with_contact_lock` + explicit `clear_message_source_id_from_redis` in `ensure`. Layer upstream's improvements in (e.g., the `@contact.blocked? && !outgoing_echo` check) at the equivalent point inside the contact lock.

Adjacent file that may need follow-up: `app/services/whatsapp/incoming_message_service_helpers.rb` typically auto-merges to our version. That's correct. If upstream's `Whatsapp::MessageDedupLock` class becomes orphaned after a merge, `git rm` it (and its spec).

**Known regression hiding here:** `acquire_message_processing_lock` in our fork checks `@processed_params.try(:[], :messages).blank?`, which skips `:message_echoes` payloads. Echoes from WhatsApp Cloud native-app sends were being silently dropped. Fixed in the 4.13.0 merge by changing to `messages_data.blank?` and picking `:to` vs `:from` for the contact phone based on `outgoing_echo`. Keep that fix on future merges.

**`unprocessable_message_type?` (4.14.2):** the list is now `%w[ephemeral request_welcome]`. `reaction` stays OUT (fork processes reactions, incl. `reaction_removal?`); `unsupported` stays OUT (upstream's `create_unsupported_message` persists a placeholder instead of dropping). If a future merge re-adds either to the list, that's upstream churn — keep them out.

### Voice notes meta keys: `is_voice_message` (canonical) vs `is_recorded_audio` (legacy)

The fork's dashboard voice-note pipeline was upstreamed by us as #14606 with the meta key renamed to `is_voice_message`. Decision made in the 4.14.2 merge: **converge the dashboard flow to upstream's key, keep the backend reading BOTH keys** — `is_recorded_audio` is still written by Baileys/Zapi PTT handlers, by the `transcode_audio` API pipeline, and exists on all historical messages.

- Frontend (`ReplyBox.vue`, `message.js`): only `isVoiceMessage`/`is_voice_message`. The fork's `removeRecordedAudio` re-record race fix (#91) and computed `hasRecordedAudio` are preserved on top of upstream's flow — keep them on future merges.
- Backend readers accept both: `Whatsapp::Providers::WhatsappCloudService#voice_message?` and `WhatsappBaileysService#voice_note_attachment?`. Baileys sets `content[:ptt] = true` only when voice (`compact` semantics — don't emit `ptt: false`, a spec pins this).
- `Messages::MessageBuilder` keeps the fork-only params (`is_recorded_audio`, `transcode_audio`, `attachments_metadata`) for external API consumers, plus upstream's `is_voice_message`/`tag_voice_message`. Do NOT assign `attachment.meta = nil` — upstream specs expect the jsonb default `{}` to survive (assign only when `metadata.present?`).

### Opus normalization lives in the model, not the provider service (PR #223)

Fork architecture: `Attachment#normalize_opus_blob_content_type!` (lazy, called from `download_url`, uses `update_column`) + `config/initializers/active_storage_opus_fix.rb` (normalizes at identification time). Upstream still carries a service-level `normalize_opus_content_type` in `whatsapp_cloud_service.rb` whose `blob.update` **fails silently on validation** — that's why #223 moved to `update_column`. On every merge: **delete the service-level method + its call** if upstream re-introduces it (it did in 4.14.2).

### Portal custom HTML injection (custom_head_html / custom_body_html)

Upstream 4.14.x extracted the public portal layout into shared partials `app/views/layouts/_portal_head.html.erb` and `_portal_scripts.html.erb`, used by both `portal.html.erb` and the new `portal.html+documentation.erb` variant. The fork's `custom_head_html`/`custom_body_html` injection lives at the END of those partials (guarded by `!@is_plain_layout_enabled`). If upstream rewrites the layouts again, re-attach the injection to whatever shared partial both variants render. Also: `show_author` must stay in `Portal::CONFIG_JSON_KEYS`, and the fork's `merged_portal_params` controller helper is GONE — upstream's model-level `normalize_config` (merges `persisted_config`) replaced it.

### Feature flags went multi-column (4.16.0)

Upstream 4.16.0 rearchitected `Featurable`: `FEATURE_FLAG_COLUMNS = ['feature_flags', 'feature_flags_ext_1']`, max 63 flags per bigint column **validated at boot** (`validate_feature_count!` raises), and `features.yml` entries pick their column via `column:`. The default column is FULL (63/63). Decisions locked in the 4.16.0 merge:

- The fork's `Featurable.feature_flag_value` two's-complement helper was **removed on CE** (zero CE call sites). NOTE: it had **6 call sites on Pro** (`account_dashboard`, `features_helper`, `fazer_ai` account concern, `reconcile_subscription_service`, `fazer_ai_hub`) — don't assume "zero call sites" holds on Pro when you write CE-side notes; grep both trees.
- Keep `save!` in `enable_features!`/`disable_features!` (upstream uses non-bang `save`).
- CE `main` made no features.yml changes, so the file stays byte-identical to upstream — verify with `git diff <merge>^2 HEAD -- config/features.yml` (must be empty). Any fork-side reorder shifts persisted bits.
- ⚠️ **CE→Pro merge landmine (RESOLVED via a preparatory PR — do this BEFORE the 4.16.0 CE→Pro merge):** Pro inserts `kanban` + `internal_chat_pro` mid-list in the DEFAULT column → 65 flags → boot raises `ArgumentError: ... supports up to 63 features`. The fix that shipped (chatwoot-pro#74) does NOT move them to `feature_flags_ext_1` (still bitmask, still drifts, still needs the 6 queries rewritten). Instead it moves both Pro-only toggles to the **`settings` jsonb column** (the fazer.ai `store_accessor :settings` pattern), so `config/features.yml` becomes byte-identical to CE and never conflicts/drifts again. Recipe: (1) remove the two entries from `config/features.yml`; (2) in `FazerAi::Concerns::Account` add `store_accessor :settings, :kanban_enabled, :internal_chat_pro_enabled` + boolean-cast writers and override `feature_enabled?`/`enable_features`/`disable_features`/`enabled_features` to route those names through settings (so frontend `json.features` and callers are unchanged); leave `all_features` bitmask-only (super-admin grid); (3) add `Field::Boolean` entries to `account_dashboard.rb` + the two keys to `account_settings_schema.rb`; (4) rewrite the 6 bit queries to `where("settings @> ?", {kanban_enabled: true}.to_json)`; (5) a data migration copies old bits 60/61 → settings and shifts the three CE flags (captain_tasks/conversation_required_attributes/advanced_assignment) from bits 62/63/64 down to 60/61/62 — read bits unsigned (`& ((1<<64)-1)`) and clamp writes to 64 bits so `down` doesn't overflow; (6) do NOT add a `before_create` default — new-account `internal_chat_pro` stays on via `ACCOUNT_LEVEL_FEATURE_DEFAULTS` (ConfigLoader is additive, so removing it from features.yml doesn't drop it from an existing install's config; forcing it in `before_create` instead breaks CE specs that assert minimal defaults). After this PR ships, the actual 4.16.0 CE→Pro merge has a features.yml with zero conflicts.

### WhatsApp embedded signup: fork API rename + new upstream HTTP calls (4.16.0)

- **JS API rename trap:** the fork renamed `whatsappChannel.reauthorizeWhatsApp` → `postEmbeddedSignupAuthorization` (same body). Upstream keeps the old name and **adds new callers with it** (4.16.0: `ConfigurationPage.vue`'s `reconfigureWhatsApp()`). Auto-merges cleanly, fails at runtime with a swallowed TypeError (no spec covers it; frontend CI stays green — only the semantic-breakage sweep caught it). After every merge: `git grep -n 'reauthorizeWhatsApp' app/javascript` must return zero hits.
- `Whatsapp::Providers::WhatsappCloudService#validate_provider_config?` now makes **two** Meta calls: GET `message_templates` + (when `provider_config_changed?`) GET `phone_numbers` to verify the phone_number_id belongs to the WABA. Fork specs that save a cloud channel must stub BOTH (return the expected id in `data: [{ id: ... }]`).
- `Whatsapp::WebhookTeardownService` now also clears the phone-level override: POST `graph.facebook.com/<ver>/<phone_number_id>` with `webhook_configuration.override_callback_uri: ''`. Fork specs stubbing teardown need this stub next to the `subscribed_apps` DELETE one.
- Controller gate: `can_reconfigure_channel?` (upstream name, our body) accepts any `Channel::Whatsapp` (fork conversion flow) and requires the `whatsapp_reconfigure` feature flag only when `provider_config['source'] == 'embedded_signup'`. Keep that shape.
- Enterprise's new `Inbox#ensure_create_permitted` runs `account.inboxes.count` in `before_create` — fork specs that `instance_double` the `account.inboxes` relation must materialize factory records BEFORE installing the double (lazy `let` inside the `allow(...).with(baileys_inbox.id)` line fires mid-stub otherwise).

### WhatsApp session providers (`native`, `uazapi`)

The provider-neutral layer for the QR/pairing family. Nearly all of it is fork-only code in
paths upstream has never had, so it does not conflict: `app/services/whatsapp/session/**`,
`app/jobs/whatsapp/session/**`, `app/controllers/webhooks/whatsapp/**`,
`app/controllers/api/v1/accounts/whatsapp/**`, `app/javascript/dashboard/helper/whatsappSession.js`,
`.../inbox/channels/session/**`, `.../inbox/settingsPage/SessionProviderConfiguration.vue`,
`lib/tasks/whatsapp_session.rake`. Merge conflicts there mean someone edited our tree, not upstream.

What it *does* touch upstream is deliberately small, and every one is **KC** on a CE merge
(upstream has no idea these providers exist):

| File | Ours |
|---|---|
| `app/models/channel/whatsapp.rb` | `prepend Whatsapp::Session::ChannelExtension` and `PROVIDERS = (%w[...] + Whatsapp::Session::PROVIDERS)`. Every behavior override lives in the module, so upstream changing a method body usually merges clean. |
| `app/services/whatsapp/send_on_whatsapp_service.rb` | `persist_source_id` goes through `Session::Outbound::SourceIdReservation.assign`, and `recipient_id` branches on `channel.session_family?`. |
| `app/services/conversations/message_window_service.rb` | one line: `session_family?` instead of a provider list. |
| `app/views/api/v1/models/_inbox.json.jbuilder` | `json.capabilities resource.channel.try(:session_capabilities)` inside the whatsapp block. If upstream restructures this file, re-attach it: the dashboard gates features on it, and a missing key reads as "provider supports nothing". |

`app/services/whatsapp/incoming_message_base_service.rb` is **untouched** by this layer, on
purpose: it is the worst conflict zone in the repo and the session layer has its own inbound
path (`Session::Inbound::Dispatcher`). Keep it that way; if a merge tempts you to add a
session branch there, it belongs in the dispatcher instead.

**The literal trap, and the one check to run after every merge.** `%w[baileys zapi]` used to be
how the fork asked "is this a paired session?", and the answer is now `channel.session_family?`.
Upstream does not write those literals, but *our own* older code did, and a merge that resurrects
one silently gives `native`/`uazapi` a 24-hour messaging window or the wrong recipient id, and no
spec fails, because the literal is still true for the two legacy providers. After every merge:

```sh
git grep -nE "%w\[baileys zapi\]|['\"]baileys['\"].{0,40}['\"]zapi['\"]" app/ lib/ \
  | grep -v "whatsapp/session/" | grep -vE "native|uazapi" | grep -vE ":[0-9]+:\s*#"
```

It prints nothing on a healthy tree (verified on `wa/08-provider-catalog`). The filters are what
make it worth running: the session layer's own files name both providers legitimately, the
canonical `SESSION_PROVIDERS` list names all four, and annotate_rb writes both into the schema
comment block. Anything that survives all three is a runtime branch that forgot the new
providers, and it should be `session_family?`, `session_provider?` or a capability check.

Two constants deliberately still name the legacy pair and are **not** hits to fix:
`Channel::Whatsapp::PROVIDERS` (a declaration, and it concatenates `Whatsapp::Session::PROVIDERS`)
and `REACTION_SUPPORTED_PROVIDERS` (only reached through `supports_reactions?`, which returns
early for session providers via the capability list).

**The legacy providers are frozen, not maintained.** `whatsapp_baileys_service.rb`,
`whatsapp_zapi_service.rb`, `baileys_handlers/**`, `zapi_handlers/**`, `BaileysWhatsapp.vue`,
`ZapiWhatsapp.vue` and their ~9k lines of specs are a deliberate safety net: do not refactor them
during a merge, even when a cop or a rename makes it tempting. Take upstream's change only if it
fixes a real bug in them.

**Pro side.** `Session::Inbound::Dispatcher` and `Session::Outbound::MessageSender` carry
`prepend_mod_with`, so Pro extends them without editing CE. Before merging CE into Pro, check
whether Pro overrides `Channel::Whatsapp` or the inbox jbuilder: both are on the touched list above.

### db/schema.rb

Always conflicts because both sides have different migration versions. Resolution is mechanical but has traps:

1. Resolve the version-number conflict first so Ruby can parse the file (`ActiveRecord::Schema[7.1].define(version: ...)`). Pick the later timestamp.
2. Resolve every other Ruby conflict file (`installation_config.rb`, any model conflicts) so Rails can boot.
3. **Prefer the git-merge schema over a dump.** Both HEAD and MERGE_HEAD commit their own migration's schema changes, so the 3-way merge of `db/schema.rb` ALREADY contains the correct, kanban-free result (fork tables from HEAD + the new upstream tables/columns from MERGE_HEAD). Just resolve the two conflict hunks (version + the new foreign-key/table blocks) by hand and you are done — **you usually do NOT need to dump at all.** If you already clobbered the file, recover the conflicted merge version from the index with `git checkout -m -- db/schema.rb` and re-resolve.
4. Run `bundle exec rails db:migrate` only to apply the pending migrations to your **DB** (so specs run). ⚠️ **`db:migrate` auto-runs `db:schema:dump` at the end**, which silently overwrites `db/schema.rb` from your (probably polluted) local DB. So after migrating, restore the hand-resolved schema: `git checkout -m -- db/schema.rb` and re-resolve, OR `git show :2:db/schema.rb`/manual fix. Do not trust the post-migrate working-tree schema.

**Traps to remember:**

- **Local dev DB has tables from other branches** (kanban, Pro features) because dev DBs are shared across branches. `db:schema:dump` (including the implicit one inside `db:migrate`) will dump those stray tables into `db/schema.rb`. The fork CE `main` schema must be **kanban-free**. Validate with a hard check, EVERY merge:
  ```bash
  grep -ic kanban db/schema.rb        # MUST be 0 on the CE fork
  diff <(git show HEAD:db/schema.rb) db/schema.rb | grep '^[<>]'   # should show ONLY this merge's upstream additions
  ```
  The ONLY valid baseline for that diff is `git show HEAD:db/schema.rb` / `git show MERGE_HEAD:db/schema.rb` — **never a local copy made after `db:migrate`** (it is already polluted, so the diff comes back empty and hides the strays — this is a real footgun that has shipped kanban refs into a CE merge). If strays are present, recover the clean merge schema via `git checkout -m -- db/schema.rb` (step 3) instead of hand-deleting 90+ lines.

- **Custom SQL functions aren't dumpable.** `db:schema:dump` strips our `execute <<~SQL CREATE OR REPLACE FUNCTION f_unaccent(text)` block. Automated re-injection is wired via the `Rakefile` + `lib/tasks/internal_chat_search.rake` (`db:internal_chat:inject_schema_functions` runs as an `enhance` hook after `db:schema:dump`). If you see the block missing after a dump, the hook didn't run — check the Rakefile wiring and the task for a warning line like `Could not find insertion point ...`. The function itself is created by migration `20260410170003_add_unaccent_search_to_internal_chat.rb`.

- **Schema version may be stamped with a migration from another branch.** `db:schema:dump` uses `MAX(schema_migrations.version)`. If the dev DB has a kanban/other-branch migration with a higher timestamp, that version ends up in `schema.rb`. Manually set the version to the highest timestamp among migrations *present in this merge's `db/migrate/`*.

- **Quick integrity diff** (in Python — sed-free): parse HEAD's schema + MERGE_HEAD's schema + merged schema, compare column/index sets per table. Any table with columns outside HEAD∪MERGE_HEAD is a stray from another branch.

### annotate_rb vs auto_annotate_models

Upstream migrated `.annotaterb.yml` + `lib/tasks/annotate_rb.rake` and deleted the old custom `lib/tasks/auto_annotate_models.rake`. Our fork did a similar migration earlier with different config style.

- `.annotaterb.yml`: **KC** for CE merge (upstream's format is more complete, symbol-key style).
- `lib/tasks/auto_annotate_models.rake`: **DEL** (`git rm`). Replacement is `lib/tasks/annotate_rb.rake` from upstream.

For **CE→Pro merges**, `.annotaterb.yml` is **CO**: adopt CE's newer format but keep the Pro-only `fazer_ai/app/models` entry in `model_dir`. Pro scans fazer-ai-specific models living under `fazer_ai/app/models`; dropping that path silently stops annotation for those models.

### Pro-only UI overrides

Pro deliberately patched a few CE components to widen access or make URLs configurable. On every CE→Pro merge CE's changes near these points re-conflict:

- **`app/javascript/dashboard/routes/dashboard/settings/components/BasePaywallModal.vue`** — Pro removed CE's `!isOnChatwootCloud` guard (so super admins see the CTA on cloud too) and added a `superAdminUrl` prop with a default so Pro instances can point to their own admin panel. → **KC**: keep Pro's `v-else-if="isSuperAdmin"` + `:href="superAdminUrl"`.

### Pro automation composables

Pro extended the automation composables to feed conditions/actions state into dropdown builders (used by kanban and other Pro-only conditions). When CE upstream touches the same functions, the signatures diverge.

- **`app/javascript/dashboard/composables/useAutomationValues.js`** — Pro signature is `getActionDropdownValues(type, conditions = [], actions = [])`. CE sometimes changes the signature (4.13.0 added `last_responding_agent` injection in the body). → **CO**: keep Pro's signature, layer CE's body changes in. If CE introduced a local variable like `agentsList`, let the returned `agents:` key read from it — pass Pro's `conditions` and `actions` through unchanged.

- **`app/javascript/dashboard/composables/useEditableAutomation.js`** — Pro recomputes `getConditionDropdownValues(condition.attribute_key, automation.conditions)` inside the filter (conditions affect dropdown content). CE reuses the pre-computed `dropdownValues` without conditions. → **KC**: keep Pro's recompute-with-conditions pattern; dropping it silently breaks kanban-related automation dropdowns.

### InstallationConfig serialize

Upstream simplified to `serialize :serialized_value, coder: YAML, type: ActiveSupport::HashWithIndifferentAccess, default: {}.with_indifferent_access`. Our fork had a custom `SerializedValueCoder` handling both YAML strings and native jsonb hashes.

Test before choosing: create a legacy `InstallationConfig` where `serialized_value` is a YAML string inside the jsonb column, then confirm upstream's simpler version can still load it. If it works (it did in 4.13.0 merge with all 3 legacy formats: tagged YAML, symbol-key YAML, native hash), go **KC**. Otherwise keep the custom coder.

Pro adds `PROTECTED_SUBSCRIPTION_KEYS` constant + `protected_subscription_key_check` validator on top of CE's version. On a CE→Pro merge the serialize block and the PROTECTED_SUBSCRIPTION_KEYS block may conflict as one hunk.

- **[Pro] CE→Pro merge:** **CO** — accept CE's simplified serialize (already validated against legacy data in 4.13.0), keep Pro's `PROTECTED_SUBSCRIPTION_KEYS`, `protected_subscription_key_check` validate, and related tests. Verify with `bundle exec rspec spec/models/installation_config_spec.rb` — both the `describe 'new record defaults'` (CE) and `describe 'protected fazer.ai config keys'` (Pro) blocks must stay.

### i18n files

**This section changed with the i18n split (PR #364). The old advice was to merge both key sets under the right parent; doing that now fails CI.**

Upstream's locale files (`config/locales/<locale>.yml`, `app/javascript/dashboard/i18n/locale/**`) no longer carry a single fork key. Everything we translate lives in `app/javascript/dashboard/i18n/fazer-ai/locale/<locale>/` and `config/locales/fazer_ai.<locale>.yml`, deep-merged on top at runtime. So:

- Conflicts in an upstream locale file are **TU**, wholesale. Take upstream's side and do not carry anything of ours across. The `drift` check compares those files byte-for-byte against the tracked tag and fails on any difference.
- A conflict there at all means the fork side still has a stray key. Resolve as TU, then run `check` to find where it should have lived.
- Our own files (`fazer_ai.*.yml`, `fazer-ai/locale/**`) are ours alone. Upstream never touches them, so they only conflict on a CE → Pro merge, resolved as **CO** like any other fork file.
- After the merge, bump `UPSTREAM_BASE` in `scripts/i18n/fork_translations.rb` to the new tag and run `check` and `drift`.

Upstream adding an `en.yml` key without the `pt_BR.yml` counterpart is still upstream's business: match their scope and do not invent translations for their files. Our own three languages are a different rule, and `check` enforces them (see **Fork translations** in `AGENTS.md`).

### New features from both sides

Controllers (`inboxes_controller`, `conversations_controller`), policies, routes, store modules, automation_rule action whitelist, spec describe-blocks — when both sides added net-new methods/endpoints/actions, the resolution is always **CO**. Keep both additions ordered sensibly.

## Validation flow

**This flow is mandatory — do not commit the merge without running it.** Reading the skill is not enough; past merges have reached commit/push with silently broken state (class autoload issues, missing f_unaccent function, stray tables in schema.rb, rubocop offenses in upstream-only files) because validation steps were skipped.

After staging all resolved files and before commit:

```bash
# 1. parse sanity (catches stray conflict markers / bad YAML / bad Ruby)
ruby -c app/models/installation_config.rb
ruby -c db/schema.rb
grep -l '<<<<<<<\|=======\|>>>>>>>' $(git diff --name-only --cached) || echo "no leftover markers"

# 2. rails boots (catches broken autoload, bad requires, missing constants)
bundle exec rails runner 'puts "ok"'

# 3. migrations all apply (catches missing f_unaccent, bad schema.rb, stray tables)
bundle exec rails db:migrate

# 4. specs for each changed area at minimum (scale up for CE merges, keep targeted for Pro merges)
bundle exec rspec spec/models spec/policies
bundle exec rspec spec/services/whatsapp  # only when WA service touched
bundle exec rspec spec/controllers/api/v1/accounts/inboxes_controller_spec.rb \
                  spec/controllers/api/v1/accounts/conversations_controller_spec.rb \
                  spec/controllers/api/v1/accounts/conversations/messages_controller_spec.rb

# 5. targeted specs for files we actually resolved (always run)
bundle exec rspec spec/models/installation_config_spec.rb  # both CE and Pro describe blocks must pass
# Pro-only specs live under fazer_ai/spec/, NOT spec/lib/fazer_ai/ — rspec silently returns 0 examples on the wrong path
bundle exec rspec fazer_ai/spec/lib/fazer_ai/integrity_report_spec.rb fazer_ai/spec/lib/fazer_ai_hub_spec.rb  # run when Pro-specific Ruby touched

# 6. rubocop project-wide (Husky only lints staged diff; upstream files with offenses slip past)
bundle exec rubocop --parallel

# 7. smoke: exercise serialize/legacy-data paths and anything else the merge touched
bundle exec rails runner 'InstallationConfig.find_each { |c| c.value }; puts "legacy configs load ok"'

# 8. targeted JS specs for changed composables / Vue components
# `pnpm test` wraps vitest with `--no-cache` which OOMs the runner on WSL. Use vitest directly
# with a bigger Node heap when testing composables / big dashboards:
NODE_OPTIONS="--max-old-space-size=4096" npx vitest run \
  app/javascript/dashboard/composables/spec/useEditableAutomation.spec.js \
  app/javascript/dashboard/composables/spec/useAutomation.spec.js \
  --no-coverage --reporter=verbose
```

Keep the output around until after push — if CI fails, being able to compare local vs CI run saves a round trip.

## Mandatory subagent review

After the validation flow passes and the merge is committed, **spawn a panel of read-only subagents to independently verify the merge** before merging the PR. This is a required gate. Run them in parallel (one message, multiple `Agent` calls), each with a distinct lens, each returning a structured PASS/FAIL verdict with evidence. Hard constraints to put in EVERY agent prompt:

- READ-ONLY: do not modify any file.
- **Do NOT run `rails db:migrate` or `rails db:schema:dump`** — both auto-dump `db/schema.rb` from the local dev DB and would re-introduce kanban/Pro strays.
- Tell each agent that HEAD may be one or more docs/follow-up commits ahead of the merge commit, so it should locate the actual merge commit and use its real parents (`^1` = fork side, `^2` = upstream side) rather than assuming `HEAD` is the merge.

Minimum panel (scale up for big merges):

1. **Schema integrity** — `grep -ic kanban db/schema.rb` is 0; `diff <(git show <merge>^1:db/schema.rb) db/schema.rb` shows ONLY this version's intended upstream additions (no stray tables); version stamp correct; fork tables + `f_unaccent` present; parses; no markers.
2. **Per-file resolution correctness** — for each conflicted file, confirm both sides' intent is preserved per the directive (default: prefer fork, pull upstream improvements), `ruby -c`/parse passes, and a repo-wide `git grep` finds zero leftover conflict markers.
3. **High-risk-area deep-dive** — the trickiest CO of this merge (often the WhatsApp incoming service / referral architecture): no orphaned or duplicated methods, all callers consistent, specs assert the fork's shape. Let this agent run the one or two light specs for that area.
4. **Auto-merge semantic-breakage sweep** — THE class of bug the per-file review misses, because the break is in a file that auto-merged cleanly. Upstream renames/moves/removes a symbol, file, or component on its side; a fork file that auto-merged still references the old name → green textual merge, broken build. Have this agent hunt for: imports that no longer resolve (Vue/JS `import ... from` and Ruby `require`/constant refs), components/helpers/i18n keys referenced but renamed upstream, and method calls whose definition moved. Grep the merge diff for files upstream renamed/deleted, then grep the fork tree for stale references to them.

> Real example (4.15.0): upstream #14741 renamed `shared/components/emoji/EmojiInput.vue` → `EmojiPicker.vue` and swapped its `:on-click` prop for a `select` event. The fork's `EmojiReactionPicker.vue` auto-merged with the stale import + prop. Zero conflict markers, clean rubocop/eslint-on-changed-files, all backend specs green — but the Vite transform broke every frontend spec that transitively imported it. Neither manual review nor a per-resolved-file subagent caught it; **only the frontend CI job did.** This is exactly why lenses #4 and the CI gate are both mandatory.

The subagent panel COMPLEMENTS but never REPLACES the CI gate below — agents reason over source, CI actually builds and runs everything. Treat any agent FAIL as blocking, and never merge on a green panel with a red CI.

### Validate on upstream CI (GitHub Actions) before merging

Local specs cover the resolved files, but the authoritative gate is the fork's own CI. After committing the merge and pushing the `chore/merge-upstream-X.Y.Z` branch, **trigger the CE spec workflow on the branch and wait for green before merging the PR** (the `Run Chatwoot CE spec` workflow, `run_foss_spec.yml`, fires on pushes to main and tags plus `workflow_dispatch`, so a branch push alone does NOT run it):

```bash
git push -u origin chore/merge-upstream-X.Y.Z
gh workflow run run_foss_spec.yml --ref chore/merge-upstream-X.Y.Z -f full=true   # full=true: a sync touches everything, the default dispatch runs only the specs the diff maps to
gh run list --workflow=run_foss_spec.yml --branch chore/merge-upstream-X.Y.Z --limit 1   # grab the run id
gh run watch <run-id>                                                                    # or poll with `gh run view <run-id>`
```

For a CE→Pro merge, the Pro CI lives in the `chatwoot-pro` repo on the Forgejo and runs on the Forgejo runners (`.forgejo/workflows/`), on a staging branch before `main` moves: push the merge to the `chatwoot-pro` remote as `sync/ce-<tag>`, then dispatch both suites on it, since a branch push alone triggers neither (`forja workflow run run_foss_spec.yml --repo git.fazer.ai/fazer-ai/chatwoot-pro --ref sync/ce-<tag> -f full=true` and `forja workflow run run_ee_spec.yml --repo git.fazer.ai/fazer-ai/chatwoot-pro --ref sync/ce-<tag>`; the second is the only CI that runs `spec/enterprise`). Follow them with `forja run list --repo git.fazer.ai/fazer-ai/chatwoot-pro --workflow <file> --branch sync/ce-<tag> --limit 1` and `forja run view <id> --repo git.fazer.ai/fazer-ai/chatwoot-pro --json status,conclusion` (`forja` has no `run watch`), and read a failure with `forja run view <id> --repo git.fazer.ai/fazer-ai/chatwoot-pro --log-failed`. Only after both are green, `git push chatwoot-pro HEAD:main` (push goes to the `chatwoot-pro` remote — see the push-target feedback memory). CI green is a pre-condition for merge, not authorization to merge — still wait for explicit user OK.

## Merging the sync PR: merge commit, NEVER squash

This fork's default PR strategy is `--squash`. **Sync PRs are one of the two exceptions** (the other is a PR already merged into Pro's `main` — see **Merge strategy** in `AGENTS.md`), and it is not a style preference: squashing `chore/merge-upstream-X.Y.Z` flattens it into a single-parent commit, so the upstream tag stops being an ancestor of `main` even though every line of it landed. Two consequences, both permanent:

- GitHub shows `main` as "N commits behind chatwoot:develop" forever, and the count only grows with each squashed sync (after the squashed 4.16.2 sync it read 197).
- The NEXT sync's merge base falls back to the last non-squashed tag, so git replays an entire version's diff and manufactures conflicts on every file the fork changed in between.

```bash
gh pr merge <n> --merge --admin --repo fazer-ai/chatwoot   # sync PRs ONLY — every other PR stays --squash
```

Verify the link immediately after merging — this is the check that catches a wrong strategy while it is still cheap to fix:

```bash
git checkout main && git pull origin main
git merge-base --is-ancestor vX.Y.Z main && echo "upstream tag is an ancestor: ok"
git rev-list --count main..vX.Y.Z      # MUST be 0
```

If it isn't 0, the PR was squashed: repair it right away with the `-s ours` recipe in **Repairing a squashed sync** (using the PR head commit, still reachable via `git fetch origin refs/pull/<n>/head`) rather than leaving it for the next sync.

`git rev-list --count main..upstream/develop` stays non-zero — that's just `develop` moving past the tag we synced, which is expected. What must be zero is the count against the tag we actually merged.

## Pre-commit pitfalls

1. **Husky rubocop check only inspects files with staged diff.** Upstream files merged as-is don't appear in the diff, so their offenses slip past the hook and blow up in CI. Before commit:
   ```bash
   bundle exec rubocop --parallel
   ```
   Run the full thing. Fix anything that comes up (most are `Rails/SaveBang` in upstream migrations/specs — safe to `rubocop -A` after receiver check).

2. **Frontend lint error vs warning.** `pnpm-lint-staged` eslint runs with `--max-warnings=0` in some configs; a warning appears as an error in the hook. Check the actual error line in the hook output, not the warning count.

3. **Missing imports after removing conflict hunks.** When resolving AI (accept incoming) conflicts in JS/Vue files, you can accidentally delete imports you still need. Example from 4.13.0: `replaceVariablesInMessage` in `ReplyBox.vue` — the `replaceText` method came in from main but its import was above the conflict. After keeping `replaceText`, add the import.

4. **Duplicate `defineExpose` / `setup()` returns.** Same category: when combining both sides of a Vue component, watch for duplicate `defineExpose({ ... })` calls or duplicate keys in the `setup()` return object. Consolidate.

5. **Orphan closing markers after partial hunk edits.** Editing a conflict by rewriting only the top of the hunk leaves the trailing `>>>>>>> vX.Y.Z` in place — and a sweep that greps only `<<<<<<<` reports clean (real case: 4.16.0, both `conversation.json` locales, staged and committed; caught later by a Vite JSON parse error in vitest). Sweep with all three patterns anchored at line start: `git grep -nE '^(<{7}|>{7})( |$)'` plus `^={7}$` (evaluate markdown-heading false positives), and JSON-validate every resolved .json (`python3 -c "import json; json.load(open(...))"`).

6. **`gh run watch --exit-status` can lie.** In the 4.16.0 merge it exited 0 while the run concluded `failure` (frontend job). Don't trust the watch exit code — poll `gh run view <id> --json status,conclusion` and read the actual conclusion string.

## What this skill deliberately does NOT cover

- CI flakiness from shard redistribution (pre-existing test pollution involving `perform_enqueued_jobs` in `before_all`, test-prof `let_it_be`, and rspec-mocks interaction). Track separately.
- Frontend build pipeline issues unrelated to the merge.
- Upstream feature rollouts that need product decisions (e.g., adopting a new captain model in our UI).
