# Phase 1 Inventory — Resource Creation Paths

Snapshot taken 2026-07-02 on branch `develop` (63b23b2). Line numbers are
anchors; re-verify after upstream merges. Seeder paths
(`lib/seeders/`, `lib/test_data/`) are listed once here and **exempt from
quota** (dev/super-admin tooling): `lib/seeders/account_seeder.rb`,
`lib/seeders/inbox_seeder.rb`, `lib/seeders/reports/report_data_seeder.rb`,
`lib/test_data/inbox_creator.rb`.

## Agents (capacity = confirmed agent `account_users`)

| Create path | Location | Guarded today? |
| --- | --- | --- |
| API create | `app/controllers/api/v1/accounts/agents_controller.rb:12` (via `AgentBuilder`) | ✅ `validate_limit` (`:4`) |
| API bulk create | `agents_controller.rb:40` (via `AgentBuilder`) | ✅ `validate_limit_for_bulk_create` (`:5`) |
| Builder itself | `app/builders/agent_builder.rb` (+ `enterprise/app/builders/enterprise/agent_builder.rb` overlay) | ❌ no internal check — any new caller bypasses |
| **Platform API** | `app/controllers/platform/api/v1/account_users_controller.rb:9` creates `AccountUser` directly | ❌ **bypass** |
| Signup first admin | `app/builders/account_builder.rb:65` (`AccountUser.create!`, administrator) | ❌ — policy: exempt (account bootstrap) |

## Teams

| Create path | Location | Guarded today? |
| --- | --- | --- |
| API create | `app/controllers/api/v1/accounts/teams_controller.rb` `#create` | ❌ |

Only path outside seeders. No clone flow found.

## Inboxes (most bypass-prone resource — 10 non-seed paths)

| Create path | Location | Guarded today? |
| --- | --- | --- |
| API create | `app/controllers/api/v1/accounts/inboxes_controller.rb:36` | ✅ `validate_limit` via `app/helpers/api/v1/inboxes_helper.rb:118` |
| Facebook callback | `app/controllers/api/v1/accounts/callbacks_controller.rb:14` | ❌ |
| Instagram callback | `app/controllers/instagram/callbacks_controller.rb:138` | ❌ |
| TikTok callback | `app/controllers/tiktok/callbacks_controller.rb:99` | ❌ |
| Twitter callback | `app/controllers/twitter/callbacks_controller.rb:52` | ❌ |
| Email OAuth (MS/Google) | `app/controllers/oauth_callback_controller.rb:79` | ❌ |
| Twilio channel | `app/controllers/api/v1/accounts/channels/twilio_channels_controller.rb:59` | ❌ |
| WhatsApp embedded signup | `app/services/whatsapp/channel_creation_service.rb:62` | ❌ |
| Onboarding web widget | `app/services/onboarding/web_widget_creation_service.rb:29` | ❌ — policy: likely exempt (account bootstrap), decide in Phase 3 |
| Platform email migration | `app/controllers/platform/api/v1/email_channel_migrations_controller.rb:74` | ❌ — installation-level; decide whether model guard applies |

Conclusion: **model-level guard on `Inbox` is mandatory**; the helper guard
alone covers 1 of 10 paths.

## Agent bots

| Create path | Location | Guarded today? |
| --- | --- | --- |
| Account API | `app/controllers/api/v1/accounts/agent_bots_controller.rb:13` | ❌ |
| Platform API | `app/controllers/platform/api/v1/agent_bots_controller.rb:12` (`AgentBot.new` — may be account-scoped or global) | ❌ — quota applies only when `account_id` present |

## Webhooks

| Create path | Location | Guarded today? |
| --- | --- | --- |
| API create | `app/controllers/api/v1/accounts/webhooks_controller.rb:10` | ❌ |

Single path. Remember: AI-loop provisioning consumes one webhook slot per
tenant (see AI_REPLY_LOOP.md) — plan defaults accordingly.

## Labels

| Create path | Location | Guarded today? |
| --- | --- | --- |
| API create | `app/controllers/api/v1/accounts/labels_controller.rb:13` | ❌ |

Note: conversation tagging (`update_labels`, acts-as-taggable) creates *tags*,
not `Label` rows — quota applies to `Label` records only.

## Custom attribute definitions

| Create path | Location | Guarded today? |
| --- | --- | --- |
| API create | `app/controllers/api/v1/accounts/custom_attribute_definitions_controller.rb:12` | ❌ |

## Automation rules

| Create path | Location | Guarded today? |
| --- | --- | --- |
| API create | `app/controllers/api/v1/accounts/automation_rules_controller.rb:13` | ❌ |
| **Clone** | `automation_rules_controller.rb:48` (policy: `automation_rule_policy.rb:18`) | ❌ — must hit the same quota |

## Integrations (`Integrations::Hook`)

| Create path | Location | Guarded today? |
| --- | --- | --- |
| API create | `app/controllers/api/v1/accounts/integrations/hooks_controller.rb:6` | ❌ |
| Slack OAuth | `lib/integrations/slack/hook_builder.rb:11` | ❌ |
| Shopify callback | `app/controllers/shopify/callbacks_controller.rb:26` | ❌ |
| Notion callback | `app/controllers/notion/callbacks_controller.rb:15` | ❌ |

Model-level guard on `Integrations::Hook` required (4 paths).

## Jobs / listeners

No background job creates quota resources directly (checked `app/jobs`,
`enterprise/app/jobs` — hits are conversations/messages/captain content).
`Internal::SeedAccountJob` → `Seeders::AccountSeeder` is the seeder exemption
above.

## UI entry points (Phase 6 targets)

Settings routes under `app/javascript/dashboard/routes/dashboard/settings/`:
`agents/` (AddAgent.vue), `teams/`, `inbox/`, `agentBots/`, `integrations/`
(webhooks live here: Integrations → Webhook), `labels/`, `attributes/`,
`automation/`. Channel onboarding UI additionally reaches the inbox paths via
`inbox/` wizard and OAuth redirects.

## Existing limit plumbing (reuse in Phases 2/3/6)

- Backend guards: agents (`agents_controller.rb:90-101`), inboxes
  (`inboxes_helper.rb:118-121`), both → `render_payment_required`
  (`request_exception_handler.rb:38-40`, 402 `{ error: }`).
- Limits read API: `GET /enterprise/api/v1/accounts/:id/limits`
  (`config/routes.rb:530`, enterprise accounts controller).
- Frontend: store action `limits` in
  `app/javascript/dashboard/store/modules/accounts.js:155`; API client
  `app/javascript/dashboard/api/enterprise/account.js`; current consumers:
  `composables/useCaptain.js`, `routes/dashboard/upgrade/UpgradePage.vue`.
  Agents/inbox settings pages do **not** currently render limits — Phase 6
  adds the shared `useQuota` composable there.

## Risky paths summary (must-have bypass specs in Phase 3)

1. Platform API `account_users#create` — agent quota bypass.
2. All 7 channel/OAuth inbox paths — inbox quota bypass.
3. Automation rule `clone` — automation quota bypass.
4. Slack/Shopify/Notion OAuth callbacks — integrations quota bypass.
5. Platform `agent_bots#create` with `account_id` — bot quota bypass.

## Policy decisions to confirm before Phase 3

- Exempt: signup first admin (`account_builder.rb:65`), onboarding web widget
  inbox (`web_widget_creation_service.rb:29`), seeders. Proposed: yes, all
  three (account bootstrap / internal tooling).
- Platform email-channel migration inbox: installation-admin action — proposed
  to still enforce the model guard (migration should consume tenant capacity).
