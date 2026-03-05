# Fork Changelog (Behavioral Changes)

This file tracks fork-specific changes that affect runtime behavior compared to `upstream/develop`.

Baseline reviewed on: `2026-03-05`  
Current branch: `feature/evolution-chatwoot-devprod-setup`

Included fork commits:
- `628700917` feat: update dashboard integrations and dev/prod docker setup
- `071d0d776` chore(fork): commit staged customization changes
- `2ce497c6f` feat(fork): update auth branding and login flow
- `860bdecc5` fix(fork): escape i18n email placeholders
- `3b6086f42` Refine Russian business hours copy
- `15033e583` Improve WhatsApp Web inbox integration
- `d6d67df4d` chore: apply local chatwoot updates

## 0) Latest staged updates (`2026-03-05`)

Behavioral summary:
- `WhatsappWeb::ConnectorClient` now sends a normalized `Origin` header for Evolution API requests.
  - Source priority: `WHATSAPP_WEB_EVOLUTION_ORIGIN` → `FRONTEND_URL` → `WIDGET_URL`.
  - Invalid URLs are ignored; only `http/https` origins are used.
- Dashboard i18n text for WhatsApp Web ignored JIDs now escapes `@` as `{'@'}` to avoid interpolation/parser issues in frontend rendering.

Key files:
- `app/services/whatsapp_web/connector_client.rb`
- `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`
- `app/javascript/dashboard/i18n/locale/ru/inboxMgmt.json`

## 1) WhatsApp Web (Evolution API) Integration

Behavioral summary:
- Added a full API inbox integration for WhatsApp Web with provisioning, setup, auth, status, reconnect/logout/cancel, device removal, and sync controls.
- Added connector client error handling and payload normalization.
- Added WhatsApp Web specific webhook delivery mode with destination validation and optional signed headers.
- Added uniqueness and immutability constraints for WhatsApp Web phone numbers in an account.
- Added masking for stored Evolution API key in inbox API responses.

Key files:
- `config/routes.rb`
- `app/controllers/api/v1/accounts/inboxes/whatsapp_web_controller.rb`
- `app/services/whatsapp_web/connector_client.rb`
- `app/listeners/webhook_listener.rb`
- `lib/webhooks/trigger.rb`
- `app/views/api/v1/models/_inbox.json.jbuilder`
- `app/javascript/dashboard/api/channel/whatsappWebChannel.js`
- `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/WhatsappWeb.vue`
- `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/components/WhatsappWebConfiguration.vue`
- `app/javascript/dashboard/routes/dashboard/settings/inbox/FinishSetup.vue`
- `app/javascript/shared/mixins/inboxMixin.js`
- `app/javascript/dashboard/helper/inbox.js`

## 2) Embedded External App (Calendar/Kassa)

Behavioral summary:
- Added new embedded app routes (`/calendar`, `/kassa`, `/external-app`) behind feature flag `calendar_kassa_access`.
- Added sidebar entries for embedded apps.
- Added signed context endpoint for iframe consumers (account/agent/conversation/route + HMAC signature).
- Added auto-provisioning for dashboard iframe app for accounts when account users are created.

Key files:
- `config/routes.rb`
- `app/controllers/api/v1/accounts/external_app_contexts_controller.rb`
- `app/javascript/dashboard/routes/dashboard/externalApp/routes.js`
- `app/javascript/dashboard/routes/dashboard/externalApp/Index.vue`
- `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`
- `app/javascript/shared/store/globalConfig.js`
- `app/services/dashboard_apps/front_embed_provisioner.rb`
- `app/models/account_user.rb`

## 3) Authentication and Signup Flow Changes

Behavioral summary:
- Removed business/disposable/blocked domain checks from signup email validation flow.
- Removed OAuth callback guard that blocked non-business accounts.
- Changed `/app/login/sso` to redirect to `/app/login` (no dedicated SAML login route page in router).
- Login UI no longer renders SAML entry point button directly.

Key files:
- `app/services/account/sign_up_email_validation_service.rb`
- `app/controllers/devise_overrides/omniauth_callbacks_controller.rb`
- `app/javascript/v3/views/routes.js`
- `app/javascript/v3/views/login/Index.vue`
- `app/javascript/v3/views/auth/signup/components/Signup/Form.vue`

## 4) Feature, Plan, and Enterprise Gating Overrides

Behavioral summary:
- Added env-based global unlock: `UNLOCK_ALL_FEATURES` enables all account features by default.
- Added UI flags from env: `DISABLE_PREMIUM_FEATURES`, `IS_ALL_FEATURES_UNLOCKED`.
- Added plan override: `OVERRIDE_PRICING_PLAN` affects pricing plan and quantity behavior.
- Added stricter enterprise disable handling through `DISABLE_ENTERPRISE`.
- Allowed enterprise cloud account endpoint behavior when `UNLOCK_ALL_FEATURES=true`.
- Replaced deprecated feature `twilio_content_templates` with `calendar_kassa_access`.

Key files:
- `app/models/concerns/featurable.rb`
- `app/controllers/dashboard_controller.rb`
- `lib/chatwoot_hub.rb`
- `lib/chatwoot_app.rb`
- `enterprise/app/controllers/enterprise/api/v1/accounts_controller.rb`
- `config/features.yml`

## 5) Notification Push Registration Compatibility

Behavioral summary:
- Browser push registration now sends wrapped payload shape (`notification_subscription`).
- Controller now accepts both nested and flat payload styles.
- VAPID key is converted to `Uint8Array` before subscription call (browser compatibility fix).

Key files:
- `app/javascript/dashboard/helper/pushHelper.js`
- `app/controllers/api/v1/notification_subscriptions_controller.rb`

## 6) API/Integration Surface Adjustments

Behavioral summary:
- Integration apps endpoint now hides selected app IDs (`dialogflow`, `dyte`, `leadsquared`) from index/show.

Key files:
- `app/controllers/api/v1/accounts/integrations/apps_controller.rb`

## 7) Locale and Language Behavior

Behavioral summary:
- Locale fallback now defaults to `ru` when no explicit locale is resolved.
- Added `kk` to enabled languages.
- Locale selector exposure is limited to `ru`, `kk`, and `en`.

Key files:
- `app/controllers/concerns/switch_locale.rb`
- `config/initializers/languages.rb`
- `app/helpers/application_helper.rb`
- `app/javascript/dashboard/routes/dashboard/settings/account/Index.vue`

## 8) Widget Runtime Behavior

Behavioral summary:
- Default web widget color changed to `#2781F6`.
- Widget avatar source now prefers connected agent bot avatar over inbox avatar.

Key files:
- `app/models/channel/web_widget.rb`
- `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Website.vue`
- `app/views/api/v1/widget/configs/create.json.jbuilder`
- `app/views/widgets/show.html.erb`

## 9) Runtime/Deployment Topology Changes

Behavioral summary:
- Added Evolution API and Evolution Manager services to compose configs.
- Added WhatsApp Web related env variables to sample env files.
- Added `script/dev-light` workflow for lightweight local stack.

Key files:
- `docker-compose.yaml`
- `docker-compose.production.yaml`
- `.env.example`
- `.env.dev.example`
- `.env.prod.example`
- `script/dev-light`
- `script/sync-front-dashboard-app`

## Update Rule

When a fork change modifies behavior (API contract, auth flow, webhook delivery, feature gating, runtime defaults, background jobs, data model assumptions, infra wiring), update this file in the same PR/commit.
