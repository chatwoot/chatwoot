# Session Handoff: `feature/plus-integration`

This file exists so the next agent can resume without relying on hidden chat history.

## Current Objective

Complete the fork integration on `feature/plus-integration` while preserving custom Plus/Omni-AI functionality and minimizing future merge conflicts with upstream Chatwoot.

Primary context files:

- `implementation_plan.md`
- `task.md`
- `old_conversation_history_with_AI/` contains previous AI-agent conversation history and research artifacts. It is currently untracked; do not commit it unless explicitly requested.

## Hard Rules From User

1. Each code-changing task must be committed and pushed before marking it complete.
2. Use proper subagents to save context; orchestrate instead of doing large audits inline.
3. Avoid unnecessary abstractions and “while we are here” changes.
4. Prefer evidence over speculation.
5. Keep changes minimal and decoupled from upstream Chatwoot where possible.
6. New frontend user-facing text should include pt-BR translation coverage.

## Repo State At Handoff

Expected working directory:

```text
C:/Users/vm_user/Downloads/chatwoot-plus
```

Expected branch:

```text
feature/plus-integration...origin/feature/plus-integration
```

Known untracked local-only directories:

```text
.lean-ctx/
old_conversation_history_with_AI/
```

Do not include these in feature commits unless the user explicitly asks.

Most recent important commits:

```text
f0067b0ca refactor: isolate message signature appender
021494930 chore: add unoapi production compose service
10d1e4636 feat(plus): core model/store/UI integrations, channel updates, and dependencies
f2c6cab76 feat(plus/providers): Baileys, ZAPI, UnoAPI channel providers and services
9a1036c57 feat(plus/m3): WhatsApp group conversations engine
248a8efaf feat(plus/m5): scheduled & recurring messages system
3c517582d feat(plus/m1): Facebook & Instagram comments handling (OmniAI)
```

Before continuing, verify:

```bash
git status --short --branch
git log --oneline -n 12
```

## What Was Already Done In This Session

### Completed code-changing tasks

1. Added UnoAPI service block to `docker-compose.production.yaml`.
   - Commit: `021494930 chore: add unoapi production compose service`
   - Pushed.

2. Extracted message signature appending from `Messages::MessageBuilder` into an isolated Plus hook.
   - Commit: `f0067b0ca refactor: isolate message signature appender`
   - Pushed.

### Completed audit-only work

Three subagents audited current implementation state:

1. `UnoDeletedAudit`
2. `GroupsCommentsAudit`
3. `ScheduledSignatureDockerAudit`

No audit-only work was committed.

## Current Implementation Status By Module

### Setup & Environment

Status: mostly complete.

Evidence:

- Branch exists and tracks `origin/feature/plus-integration`.
- `.env.example` has:
  - `UNOAPI_URL`
  - `UNOAPI_API_KEY`
  - Omni-AI comment variables.

Gap:

- Runtime code reads `UNOAPI_AUTH_TOKEN` in places while `.env.example` documents `UNOAPI_API_KEY`.

Next smallest patch:

- Align naming by either documenting `UNOAPI_AUTH_TOKEN` in `.env.example` or changing runtime fallback to read `UNOAPI_API_KEY` consistently.

### UnoAPI Channel Integration

Status: partial.

Complete evidence:

- `app/models/channel/whatsapp.rb` includes `unoapi` provider support.
- `app/jobs/webhooks/whatsapp_events_job.rb` dispatches `unoapi` to `Whatsapp::IncomingMessageUnoapiService`.
- `app/services/whatsapp/providers/unoapi_service.rb` exists.
- `app/services/whatsapp/unoapi_webhook_setup_service.rb` exists.
- `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Unoapi.vue` exists.
- `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/UnoapiConfiguration.vue` exists.

Gaps:

- `Whatsapp.vue` provider selection does not mount/import `Unoapi.vue`.
- `ConfigurationPage.vue` appears to use generic WhatsApp settings, not `UnoapiConfiguration`, for existing UnoAPI inboxes.
- New UnoAPI inbox creation payload does not set `connect: true`; webhook setup only runs when provider config `connect` is true.

Next smallest patch:

1. Mount UnoAPI in WhatsApp channel creation UI.
2. Render `UnoapiConfiguration.vue` for existing `provider === 'unoapi'` WhatsApp inboxes.
3. Ensure creation or explicit setup path triggers webhook registration.
4. Commit and push this patch before moving on.

### WhatsApp Groups Engine & Groups Tab

Status: mostly complete, with UI/count/translation gaps.

Complete evidence:

- Group migrations exist:
  - `db/migrate/20260426120000_add_group_fields_to_conversations.rb`
  - `db/migrate/20260426120100_create_group_contacts.rb`
- Models exist:
  - `app/models/group_contact.rb`
  - `app/models/group_member.rb`
- Normalizer exists:
  - `app/services/whatsapp/group_payload_normalizer.rb`
- UnoAPI participant sync exists:
  - `app/jobs/whatsapp/unoapi/group_participants_sync_job.rb`
  - `app/services/whatsapp/unoapi/group_participants_sync_service.rb`
- UI pieces exist for group conversations and group creation.

Gaps:

- `app/javascript/dashboard/i18n/locale/pt_BR/chatlist.json` lacks groups tab label.
- `app/services/conversations/filter_service.rb` returns only mine/assigned/unassigned/all counts; no `group_count` evidence found.

Next smallest patch:

1. Add pt-BR group tab label.
2. Add/verify `group_count` in conversation stats response if frontend expects `groupCount`.
3. Commit and push.

### Preserved Deleted Messages & Sync

Status: partial/missing.

Complete/partial evidence:

- `show_deleted_message_content` setting exists in:
  - `app/models/concerns/account_settings_schema.rb`
  - `app/models/account.rb`
  - `app/controllers/api/v1/accounts_controller.rb`
  - `app/javascript/dashboard/routes/dashboard/settings/account/components/DeletedMessageContent.vue`
- Inbound handling exists in `app/services/whatsapp/incoming_message_base_service.rb` around deleted statuses.
- Frontend notice exists in `app/javascript/dashboard/components-next/message/bubbles/Text/Index.vue` for preserved deleted content.

Gaps:

- Plan/task calls setting `preserve_deleted_message_content`; implementation uses `show_deleted_message_content`.
- No `deleted_by_sender` flag found; implementation uses `deleted_content_preserved`.
- Audit flagged suspicious stray lines in `app/services/whatsapp/incoming_message_base_service.rb` around lines 151-155. Inspect before editing.
- Outbound dashboard delete sync to WhatsApp/UnoAPI is missing. `messages_controller` only soft-deletes locally; no provider `delete_message` path found.

Next smallest patch:

1. Inspect/fix suspicious lines in `incoming_message_base_service.rb`.
2. Decide whether to keep `show_deleted_message_content` naming or add compatibility alias for `preserve_deleted_message_content`.
3. Add provider delete sync as a small service/job for WhatsApp messages with `source_id`.
4. Commit and push each patch separately if they are separate tasks.

### Facebook/Instagram Comments Handling

Status: backend/routes complete; frontend i18n partial.

Complete evidence:

- Middleware/job/initializer exist:
  - `app/middleware/omni_ai/facebook_comment_middleware.rb`
  - `config/initializers/omni_ai_middleware.rb`
  - `config/initializers/omni_ai_comments.rb`
  - `app/jobs/omni_ai/comment_forward_job.rb`
- Instagram webhook forwards comment events in `app/controllers/webhooks/instagram_controller.rb`.
- Proxy/reply/private reply controllers exist in `app/controllers/omni_ai/`.
- Routes exist in `config/routes.rb`.
- Frontend route mounted:
  - `app/javascript/dashboard/routes/dashboard/omniComments/routes.js`
  - `app/javascript/dashboard/routes/dashboard/dashboard.routes.js`
  - sidebar item in `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`

Gaps:

- `OmniCommentsIndex.vue` contains many hardcoded English UI strings.
- `app/javascript/dashboard/i18n/locale/pt_BR/settings.json` lacks `SIDEBAR.OMNI_COMMENTS` translation while English has it.

Next smallest patch:

1. Add missing `SIDEBAR.OMNI_COMMENTS` pt-BR translation.
2. Extract obvious hardcoded comments page labels into i18n keys only if necessary; avoid a large rewrite.
3. Commit and push.

### Inline Click-to-WhatsApp Ad Referrals

Status: likely implemented; still needs targeted verification.

Evidence already found:

- `app/javascript/dashboard/components-next/message/AdReferralCard.vue` exists.
- Prior commit history includes CTWA ad referral card work.

Next smallest verification:

- Inspect `AdReferralCard.vue` and message bubble mount.
- Verify rendering condition is based on referral content and does not show for standard 1-to-1 conversations without referral data.
- If no code changes, report evidence only.

### Scheduled Messages

Status: mostly implemented, but not exactly as original `Plus::ScheduledMessage` plan.

Evidence:

- Existing implementation uses core-style models/controllers/jobs:
  - `app/models/scheduled_message.rb`
  - `app/models/recurring_scheduled_message.rb`
  - `app/controllers/api/v1/accounts/conversations/scheduled_messages_controller.rb`
  - `app/controllers/api/v1/accounts/conversations/recurring_scheduled_messages_controller.rb`
  - `app/jobs/scheduled_messages/send_scheduled_message_job.rb`
  - `app/jobs/scheduled_messages/trigger_scheduled_messages_job.rb`
  - frontend scheduled message modal/list/API/store files.

Gap:

- Does not use `plus_scheduled_messages` table or `Plus::ScheduledMessage` namespace from the plan. Do not rewrite this unless user explicitly approves; rewriting would be large and conflict-prone.

Next smallest patch:

- Verify routes/schedule entry and run targeted model/job specs if available.
- Treat architecture mismatch as known residual risk rather than immediately rewriting.

### Per-Inbox Signatures

Status: partial.

Evidence:

- `Messages::MessageBuilder` calls `Plus::MessageSignatureAppender.call(...)`.
- `app/models/inbox_signature.rb` exists.
- `app/controllers/api/v1/profile/inbox_signatures_controller.rb` exists.
- Frontend signature helpers and UI button paths exist.

Gaps:

- Settings UI appears to write channel `additional_attributes.signature`, while separate `inbox_signatures` API/model exists.
- Audit did not find a no-duplication guard in signature append behavior.

Next smallest patch:

1. Inspect `Plus::MessageSignatureAppender` and add no-duplication guard if missing.
2. Align settings UI storage path with actual backend appender source.
3. Commit and push.

### Uno Premium Health Check

Status: complete.

Evidence:

- `app/jobs/internal/check_uno_premium_features_job.rb`
- Daily schedule entry in `config/schedule.yml`

Next smallest patch:

- None unless targeted specs fail.

### Docker UnoAPI Service

Status: partial.

Evidence:

- `docker-compose.production.yaml` has UnoAPI service, port, image/platform, and volume.

Gaps from plan:

- Missing explicit `WEBHOOK_URL` env var.
- Missing explicit `chatwoot_network` network configuration if the compose file expects named networks.

Next smallest patch:

- Add `WEBHOOK_URL` only if required by actual UnoAPI image/runtime. Avoid adding invented networks if existing compose does not use a custom network.
- Commit and push.

## Recommended Next Work Order

Use subagents for audit/verification, but code patches should be small and committed immediately.

1. Fix obvious low-risk i18n gaps:
   - pt-BR `SIDEBAR.OMNI_COMMENTS`
   - pt-BR groups chatlist label
   - Commit + push.

2. Fix UnoAPI UI mount/config path:
   - Mount `Unoapi.vue` in WhatsApp channel creation flow.
   - Render `UnoapiConfiguration.vue` for existing UnoAPI inboxes.
   - Ensure webhook registration can be triggered.
   - Commit + push.

3. Inspect and fix deleted-message inbound suspicious code:
   - Read `app/services/whatsapp/incoming_message_base_service.rb` around the deleted handler.
   - Patch only if there is concrete syntax/logical breakage.
   - Commit + push.

4. Add missing outbound delete sync only after confirming provider APIs:
   - Small service/job preferred.
   - Avoid deep core pipeline changes.
   - Commit + push.

5. Verify CTWA card behavior:
   - If no code change, just report evidence.
   - If small missing condition, patch and commit + push.

6. Decide on scheduled-message architecture mismatch:
   - Current implementation is extensive and likely functional.
   - Do not rewrite to `Plus::ScheduledMessage` unless user explicitly approves.

## Verification Guidance

Prefer targeted checks only:

```bash
bundle exec ruby -c app/services/whatsapp/incoming_message_base_service.rb
bundle exec ruby -c app/builders/messages/message_builder.rb
bundle exec rspec spec/models/inbox_signature_spec.rb
bundle exec rspec spec/jobs/scheduled_messages/trigger_scheduled_messages_job_spec.rb
```

Only run checks that correspond to the files changed in the current task. Do not run project-wide test/lint/format unless the user asks.

## Commit Discipline

After each code-changing task:

```bash
git status --short
git add <only files changed for that task>
git commit -m "<clear conventional message>"
git push
```

Then verify clean branch except known untracked local-only directories.
