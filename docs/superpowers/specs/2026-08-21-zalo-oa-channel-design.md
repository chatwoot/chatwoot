# Zalo OA Channel — Design Spec

- Date: 2026-08-21
- Branch: `feature/zalo-oa-channel`
- Status: Draft — pending user review

## 1. Goal

Add Zalo Official Account (OA) as a native Chatwoot channel (`Channel::ZaloOa`),
following the same architecture as existing channels (WhatsApp Cloud, Telegram).
No sidecar service, no external database — Chatwoot core owns OAuth, webhook
verification, message send/receive, and media handling directly.

Target audience: intended as an upstream OSS contribution, so code, tests, and
i18n must follow existing Chatwoot conventions closely enough to be PR-ready.

## 2. Reference implementation

A working, unofficial reference exists at `zca-bridge/src/zalo-oa/` (TypeScript
sidecar, same author's separate project, not part of this repo). It implements
OAuth, webhook verify, send (text/image/file), image compression, backfill,
consultation-window tracking, and an info-request flow against the real Zalo OA
API. It is **not deployed and not reused directly** — the Ruby implementation
is a fresh port of the *protocol logic* (API shapes, error codes, window rules),
not the code.

## 3. Non-goals (confirmed out of scope)

- **Reactions and message recall/undo** — the Zalo OA REST API has no
  equivalent endpoint. These exist only for Zalo personal accounts (`zca-js`,
  unofficial), which is a separate integration not covered here.
- **Outbound sticker/video/audio** — Zalo OA's send API only supports
  text/image/file for OA→user messages. Users can still *send* those types
  inbound; the channel cannot send them back out.
- Zalo personal-account channel (`zca-js`-based) — a different, unofficial API
  surface with account-ban risk; explicitly not part of this spec.

## 4. Architecture — component mapping

Modeled primarily on `Channel::Whatsapp` (WhatsApp Cloud provider), since Zalo
OA shares its shape: app credentials + OAuth-like connect, signed webhooks, a
time-boxed free-messaging window.

| Layer | New file | Pattern reference |
|---|---|---|
| Model | `app/models/channel/zalo_oa.rb` + migration `channel_zalo_oa` | `channel/whatsapp.rb` |
| Webhook inbound | `app/controllers/webhooks/zalo_oa_controller.rb` | `webhooks/whatsapp_controller.rb` + `MetaTokenVerifyConcern` |
| Inbound job | `app/jobs/webhooks/zalo_oa_events_job.rb` (queue `low`, mutex per user) | `webhooks/whatsapp_events_job.rb` |
| Inbound service | `app/services/zalo_oa/incoming_message_service.rb` | `whatsapp/incoming_message_whatsapp_cloud_service.rb` |
| Outbound service | `app/services/zalo_oa/send_on_zalo_oa_service.rb` < `Base::SendOnChannelService`, registered in `SendReplyJob::CHANNEL_SERVICES` | `whatsapp/send_on_whatsapp_service.rb` |
| OAuth connect | `app/services/zalo_oa/oauth_client.rb` + `app/controllers/api/v1/accounts/zalo_oa/authorizations_controller.rb` | `whatsapp/embedded_signup_service.rb`, `whatsapp/token_exchange_service.rb` |
| Token refresh | `app/jobs/channels/zalo_oa/token_refresher_job.rb` (scheduled) | `channels/whatsapp/health_sync_scheduler_job.rb` |
| Media/send provider | `app/services/zalo_oa/providers/zalo_oa_service.rb` (upload + compress) | `whatsapp/providers/whatsapp_cloud_service.rb` |
| Frontend tile | Entry in `ChannelList.vue` | Existing Telegram/Line tiles |
| Frontend setup form | `channels/ZaloOa.vue`, registered in `ChannelFactory.vue` | `channels/WhatsappEmbeddedSignup.vue` |
| i18n | `en.json` (frontend), `en.yml` (backend) only | — |

## 5. Data model

`channel_zalo_oa` table (draft columns):

- `account_id` (FK, indexed)
- `oa_id` (string, unique per account) — Zalo's OA identifier
- `app_id`, `app_secret` (encrypted via `encrypts`, matches WhatsApp's pattern —
  no custom crypto module)
- `access_token`, `refresh_token` (encrypted)
- `token_expires_at` (datetime) — drives the refresher job
- `provider_config` (jsonb) — anything non-critical/extensible
- `name` (string)

`Channel::ZaloOa` includes `Channelable`, defines `EDITABLE_ATTRS`, validates
`oa_id` uniqueness, calls `prepend_mod_with('Channel::ZaloOa')` for future
Enterprise hooks (audit log already applies automatically via the
`Channelable` enterprise prepend — no extra work needed there).

## 6. Inbound flow

1. Zalo POSTs to `/webhooks/zalo_oa` (exact URL scoping — one endpoint shared
   across OAs vs. per-account path — is an open item, see §10).
2. Controller verifies the `mac` signature using the OA's `secret_key`
   (mirrors `zca-bridge/src/zalo-oa/verify.ts`), enqueues
   `Webhooks::ZaloOaEventsJob`, returns `200` immediately (durable-path
   pattern, same as WhatsApp).
3. Job resolves the channel by `oa_id`, locks per-user (Redis mutex, same as
   `MutexApplicationJob`), hands off to `IncomingMessageService`.
4. Service classifies the event (port of `classify.ts`): text, image, gif,
   sticker, audio, video, file, location → Google Maps link fallback, unknown
   → text fallback. Creates/finds contact (`sender.id`), conversation,
   message + attachment.
5. Quoted replies: `quote_msg_id` on the Zalo event maps to
   `in_reply_to`/content-index on the Chatwoot message, same as the existing
   quote-reply pattern used elsewhere.

## 7. Outbound flow

1. `Message#dispatch_create_events` → `SendReplyJob` → `SendOnZaloOaService`.
2. Text: POST to `/v3.0/oa/message/cs` with `quote_message_id` if replying; on
   rejection of the quote (permanent or transient upload error), retry once
   without the quote (matches the reference implementation's fallback
   behavior).
3. Image: upload via `/v2.0/oa/upload/image` (png/jpeg/gif/webp only),
   compress first if payload exceeds ~900KB using Chatwoot's existing
   `image_processing`/vips pipeline (not `sharp` — that's Node-only, no
   Ruby equivalent needed since Chatwoot already has an attachment
   processing pipeline).
4. File: upload via `/v2.0/oa/upload/file`, send as `file` attachment.
5. Error handling — map Zalo's numeric error codes to three buckets:
   - **Retryable** (`-32` rate limit, `-100` expired attachment id) → let
     Sidekiq retry.
   - **Window-closed** (`-213/-217/-227/-230/-232/-234/-244`) → do not retry;
     post a private note explaining why delivery failed (window expired,
     blocked, banned, night curfew 22:00–06:00, etc.), matching Chatwoot's
     existing dead-letter-note pattern for WhatsApp 24h-window failures.
   - **Permanent/unknown** → dead-letter, private note with raw error.

## 8. OAuth / provisioning flow

1. Admin clicks "Zalo" tile → `ZaloOa.vue` form (App ID, App Secret, or a
   Connect button if Zalo supports full OAuth redirect — confirm during
   implementation which flow Zalo OA's dev console actually offers).
2. Backend exchanges code for access/refresh token via `OauthClient`, creates
   `Channel::ZaloOa` + `Inbox`, redirects into the normal "Add agents" step
   (same UX as every other channel).
3. `TokenRefresherJob` runs on a schedule (Sidekiq-cron equivalent to
   `templates_sync_scheduler_job.rb`), refreshes before `token_expires_at`.

## 9. Testing

Mirror existing coverage shape:

- `spec/models/channel/zalo_oa_spec.rb`
- `spec/services/zalo_oa/incoming_message_service_spec.rb`
- `spec/services/zalo_oa/send_on_zalo_oa_service_spec.rb`
- `spec/controllers/webhooks/zalo_oa_controller_spec.rb`
- `spec/requests/api/v1/accounts/inboxes_spec.rb` — extend existing spec for
  the new channel type rather than duplicating it.

Per CLAUDE.md: no custom spec helpers unless they remove real repeated
complexity; prefer `let` + per-example setup.

## 10. Open items to confirm during implementation (not blocking spec approval)

- Whether Zalo's dev console offers a redirect-based OAuth flow or only
  manual App ID/Secret + webhook URL registration (changes the shape of
  step 8.1).
- Exact webhook URL scoping (per-account path vs. shared endpoint keyed by
  `oa_id` in payload).
- Whether Chatwoot's existing `image_processing` pipeline can hit the same
  compression targets `imageCompress.ts` does, or needs tuning.

## 11. Phased delivery

1. **Foundation** — migration + model + inbox-type registration.
2. **OAuth connect** — token exchange, inbox creation, refresh job.
3. **Inbound** — webhook verify → job → classify → message creation.
4. **Outbound** — send service, window/error-code handling, image compression.
5. **Frontend** — channel tile, setup form, i18n.
6. **Tests** — full spec coverage mirroring WhatsApp/Telegram.
7. **Post-MVP (separate follow-up spec)** — startup backfill, info-request
   card flow.

Phases 1–4 constitute a working channel via API; 5–6 are required before this
is mergeable; 7 is deliberately deferred to keep the first PR reviewable.
