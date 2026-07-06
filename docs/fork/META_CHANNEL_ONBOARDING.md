# Meta channel onboarding (Facebook · Instagram · WhatsApp)

How vendors connect Meta channels in this multi-vendor SaaS, and the one-time
platform setup that makes it possible. **The short version: one platform-owned Meta
app + OAuth. Vendors never create their own Meta developer app or paste tokens.**

> **Authenticity & recency.** Every step below is cross-checked against (a) the
> official Meta for Developers docs, (b) the official Chatwoot self-hosted docs, and
> (c) this fork's own code/config. Sources are listed in §8 with the retrieval date
> (**2026-07-06**). Meta changes app-review requirements, permission names, and Graph
> API versions **often** — treat §8's links as the source of truth and re-verify
> before a production submission. Claims marked **[code]** are verified against this
> repository; **[meta]** / **[chatwoot]** are from the linked official docs.

---

## 1. The model — one platform app, vendors OAuth in

- **You (the SaaS operator)** register and own **one Meta app** (Business type). You
  add the products (Messenger / Instagram / WhatsApp + Facebook Login), set the
  instance-level credentials **once**, and take the app through Meta **App Review /
  Advanced Access / Business Verification**.
- **Each vendor** connects their own Facebook Page / Instagram professional account /
  WhatsApp Business Account by clicking a **"Login with Facebook" / "Connect with
  WhatsApp"** button inside their Chatwoot workspace. Chatwoot runs the OAuth flow
  against *your* app, exchanges the token **server-side** (using `*_APP_SECRET`, never
  exposed to the vendor), lists their assets, and creates the inbox. **[code][chatwoot]**
- A single approved Meta app can be authorized by **unlimited** external Pages / IG
  accounts / WABAs — that is exactly the multi-tenant model. The per-vendor "make your
  own developer app + do your own review" path is strictly worse and is **not** used.

In this fork, all of the vendor-facing connection happens **inside Chatwoot**, reached
through the meta-saas SSO bounce — see §6 (`CHANNELS_VIA_CHATWOOT`).

---

## 2. Prerequisites (platform, one-time)

1. A **Meta Business** (Business Manager) that you control.
2. **Business Verification** for that Business — required before Advanced Access to
   messaging permissions is granted. **[meta]**
3. A public **HTTPS** Chatwoot URL (Meta webhooks + OAuth redirects must be reachable
   and TLS). Have it behind your real domain.
4. Super Admin access to set instance config (`/super_admin/app_config` or env +
   `InstallationConfig`). See `SUPER_ADMIN.md`.

---

## 3. Part A — Platform setup, per channel

Create the app first: **[developers.facebook.com/apps](https://developers.facebook.com/apps/)
→ Create App → "Other" → "Business" → name + email.** Grab **App ID** and **App
Secret** from **Settings → Basic**. **[chatwoot]**

Set instance config after each section and **restart Rails** (env is read at boot; or
set it in `/super_admin/app_config` which persists to `InstallationConfig`). **[code]**

### 3.1 Facebook Messenger

**Products to add:** *Messenger* + *Facebook Login*. **[chatwoot]**

**Facebook Login settings:** enable **Web OAuth Login** and **Login with JavaScript
SDK**; add your Chatwoot domain to **Allowed Domains for the JavaScript SDK**; set it as
the **App Domain** under Settings → Basic. **[chatwoot]** (Chatwoot loads
`connect.facebook.net/en_US/sdk.js` and calls `FB.login(...)` in the vendor's browser.
**[code]** `useFacebookPageConnect`.)

**Instance config:**

| Key | Value |
| --- | --- |
| `FB_APP_ID` | App ID (Settings → Basic) |
| `FB_APP_SECRET` | App Secret (Settings → Basic) |
| `FB_VERIFY_TOKEN` | a unique secret string you choose (used for webhook verification) |
| `FACEBOOK_API_VERSION` | a currently-supported Graph API version (this fork's send path defaults to **v25.0**; Chatwoot's older doc references v17.0 — use a current one) **[code]** |

**Messenger webhook** (Messenger → Settings → Webhooks):
- **Callback URL:** `{CHATWOOT_URL}/bot` **[chatwoot]**
- **Verify Token:** your `FB_VERIFY_TOKEN`
- **Subscribe fields:** `messages`, `messaging_postbacks`, `message_deliveries`,
  `message_reads`, `message_echoes` **[chatwoot]**

**Permissions to request in App Review (Advanced Access):** `pages_messaging` (message
as the page), `pages_show_list` (list the vendor's pages), `pages_manage_metadata`
(subscribe webhooks per page), `pages_read_engagement`, and `business_management`.
**[chatwoot][code]** (`FACEBOOK_PAGE_SCOPES` in `facebookScopes.js`.)

### 3.2 Instagram

Chatwoot supports **two** Instagram paths. Prefer the newer one for new setups.

**(a) Instagram API with Instagram Login — recommended, direct.** The vendor logs in
with their **Instagram professional account** directly (no linked Facebook Page
required). This fork implements it — `Api::V1::Accounts::Instagram::AuthorizationsController`
follows Meta's *instagram-api-with-instagram-login / business-login* flow. **[code][meta]**

- Add the **Instagram** product / Instagram Business Login to the app.
- **Instance config:** `INSTAGRAM_APP_ID`, `INSTAGRAM_APP_SECRET`,
  `INSTAGRAM_VERIFY_TOKEN`. **[code]** (`config/installation_config.yml`.)
- Webhook: the Instagram webhook endpoint verified with `INSTAGRAM_VERIFY_TOKEN`.
- Scopes: `instagram_business_basic`, `instagram_business_manage_messages` (Meta's
  Instagram-Login scope names). **[meta]**

**(b) Instagram via Facebook Login — legacy, being deprecated.** Messages flow through
a Facebook Page linked to the Instagram professional account. **[chatwoot]**

- Products: **Instagram Graph API** (+ Instagram Basic Display for testing).
- **Instance config:** `FB_APP_ID`, `FB_APP_SECRET`, `IG_VERIFY_TOKEN`. **[chatwoot]**
- **Webhook callback:** `{CHATWOOT_URL}/webhooks/instagram`; verify with `IG_VERIFY_TOKEN`.
  Subscribe: `messages`, `message_reactions`, `messaging_seen`. **[chatwoot]**
- Permissions: `instagram_basic`, `instagram_manage_messages`, plus the page perms
  (`pages_show_list`, `pages_manage_metadata`, `pages_messaging`,
  `pages_read_engagement`) and `business_management`. **[chatwoot][code]** (`INSTAGRAM_SCOPES`.)

> Meta deprecated the older Instagram-via-Facebook-Login scope names; the legacy path
> is on Meta's deprecation track. New tenants should use path (a). **[chatwoot][meta]**

### 3.3 WhatsApp (Cloud API via Embedded Signup)

WhatsApp uses Meta's **Embedded Signup**, which is **Facebook Login for Business** with
a **configuration id**. The vendor completes Meta's in-popup wizard (create/select a
WhatsApp Business Account + phone number) without leaving Chatwoot. **[code][chatwoot][meta]**

**Requirements:** you must be a registered **Meta Tech Provider** (Business Verification
+ accept the relevant terms). Onboarded vendors add their own payment method to their
WABA (Tech Provider model), or you share a line of credit (Solution Partner model).
**[meta]**

**Products to add:** *WhatsApp* + *Facebook Login for Business*. **[chatwoot]**

**Create the Embedded Signup configuration** (Facebook Login for Business →
Configuration): set login variation to **WhatsApp Embedded Signup**, add the WhatsApp
Business Account asset with **manage** permission, add the required permissions, save,
and **copy the Configuration ID**. **[chatwoot]**

**Instance config** (Super Admin → `/super_admin/app_config?config=whatsapp_embedded`):
`WHATSAPP_APP_ID`, `WHATSAPP_APP_SECRET`, `WHATSAPP_CONFIGURATION_ID` (the config id).
**[chatwoot]**

**Permissions:** `whatsapp_business_management`, `whatsapp_business_messaging`,
`business_management`. **[chatwoot]** Webhooks are **registered automatically** during
the embedded-signup flow. **[chatwoot]**

### 3.4 App Review, Advanced Access & Business Verification (the multi-tenant gate)

This is what turns "only my own pages" into "any vendor's pages".

- **Standard Access** (default for a new app) only lets Pages / IG accounts / WABAs
  that have a **role on your app** (you, your devs, or added test users) connect. Good
  for testing; **not** multi-tenant. **[meta]**
- **Advanced Access** is required for every external vendor to connect, and it requires
  **App Review + Business Verification**. **[meta]**
- `business_management` is a **dependency** of `pages_messaging`, `pages_show_list`, and
  `instagram_manage_messages` — call it out in the submission. **[meta]**
- Submit each messaging permission with a screencast of the real connect + reply flow.
  Expect Meta to require a working demo and a privacy policy URL. **[meta]**

Until approval, test end-to-end with **test users / test Pages** added in the app
dashboard. **[meta]**

---

## 4. Part B — What the vendor does (in Chatwoot)

No developer console, no tokens. Inside their Chatwoot workspace:

1. **Settings → Inboxes → Add Inbox** → choose the channel (Facebook / Instagram /
   WhatsApp). **[code][chatwoot]**
2. **Facebook / Instagram:** click **Login with Facebook** (or Instagram) → authorize
   in the Meta popup → **pick the Page / Instagram account** → inbox created. **[code]**
   (`register_facebook_page` server-side exchanges the token and lists pages.)
3. **WhatsApp:** click **Connect with WhatsApp Business** → complete Meta's Embedded
   Signup wizard (select/create WABA + number) → inbox created, webhooks auto-registered.
   **[code][chatwoot]** A manual fallback exists if the popup is blocked.
4. **Re-authorize** when a token expires or scopes change: Chatwoot surfaces a
   *Reauthorize* action that re-runs `FB.login` for that inbox. **[code]** `Reauthorize.vue`.

The vendor's Page/WABA **access token is stored per-inbox, encrypted, server-side**;
they never see the app secret.

---

## 5. Permissions reference (verified against `facebookScopes.js`)

| Scope | Channel | Purpose |
| --- | --- | --- |
| `pages_messaging` | Messenger | Send/receive as the page **[chatwoot]** |
| `pages_show_list` | Messenger/IG | List the vendor's pages to pick **[chatwoot]** |
| `pages_manage_metadata` | Messenger/IG | Subscribe webhooks per page **[chatwoot]** |
| `pages_read_engagement` | Messenger/IG | Read page/follower data **[chatwoot]** |
| `business_management` | all | Dependency for the messaging perms **[meta]** |
| `instagram_basic` / `instagram_business_basic` | Instagram | Read the IG professional account **[meta]** |
| `instagram_manage_messages` / `instagram_business_manage_messages` | Instagram | Send/receive IG DMs **[meta]** |
| `whatsapp_business_management` | WhatsApp | Manage the WABA **[chatwoot]** |
| `whatsapp_business_messaging` | WhatsApp | Send/receive WhatsApp messages **[chatwoot]** |

---

## 6. `CHANNELS_VIA_CHATWOOT` — the meta-saas tie-in

**Decision:** channels are managed **inside Chatwoot**, not re-implemented in the
meta-saas dashboard. Chatwoot already provides the audited OAuth connect flows above,
so the control plane defers to them rather than building a parallel path (the
"Chatwoot-first, no parallel features" principle).

**The flag.** `CHANNELS_VIA_CHATWOOT` (meta-saas `@repo/config`) defaults to **`true`**.
**[code]** `packages/config/src/env.ts`. When on:

- The meta-saas **channel-connect** endpoint returns **`410 Gone`** with a "manage in
  Chatwoot" message instead of persisting a parallel Meta token — the client redirects
  the vendor to their Chatwoot workspace. **[code]** `apps/api/src/tenant/channels.controller.ts`.
- The meta-saas **Chatwoot inbox/team create** endpoints likewise **`410 Gone`**.
  **[code]** `apps/api/src/chatwoot/chatwoot-resource.controller.ts`.
- The web **Channels** page is read-only + an **"Open Chatwoot workspace"** SSO button.

**How the vendor gets in.** Vendors are provisioned as **Chatwoot `administrator`** and
land in their own account via a Platform-minted, single-use **SSO link** (the meta-saas
sidebar "Open Chatwoot workspace" → `/console` → `GET /chatwoot/handoff/sso-link`). They
never touch the Chatwoot admin login or the Meta developer console. See
`SUPER_ADMIN.md` and `../../../meta-saas/docs/operations/chatwoot-access-lockdown.md`.

**Where the Meta-app credentials live.** In **Chatwoot's** `InstallationConfig` /
Super Admin (`FB_APP_ID`, `INSTAGRAM_APP_ID`, `WHATSAPP_CONFIGURATION_ID`, …) — **not**
in meta-saas. There is one platform Meta app shared by all tenants; meta-saas holds no
per-vendor Meta channel tokens under this flag. **[code]**

**Plan limits still apply.** The number of inboxes a vendor can create in Chatwoot is
capped by the plan: the control plane pushes `accounts.limits` (incl. `inboxes =
maxInboxes + 1` reserved for the system AI-Handoff inbox) via the Platform API, and the
fork's `QuotaGuard` blocks over-cap inbox creation natively (see `ENTITLEMENTS.md`).
So the vendor connects channels freely **up to their plan**, with no gating code in
meta-saas. **[code]**

**Source of truth / routing.** The inbox + channel live in Chatwoot; meta-saas maps the
Chatwoot `account.id → tenant` in `channel_mapping`, and inbound customer messages
arrive over Chatwoot's signed **account webhook** into the orchestrator. Conversations
and inboxes are **out of scope** for the control plane's own limits — they are the
delivered product surface (see `docs/backlog/13-*` guardrail). **[code]**

**To turn it off** (run the pre-Chatwoot native connect path instead): set
`CHANNELS_VIA_CHATWOOT=false` in meta-saas. The 410s become live connect endpoints
again. Not recommended — it reintroduces a parallel Meta integration Chatwoot already
owns.

---

## 7. Troubleshooting

- **Webhook verify fails / 404:** Messenger callback is `{CHATWOOT_URL}/bot`; Instagram
  (legacy) is `/webhooks/instagram`. Confirm the verify token matches the configured
  one and the URL is public HTTPS. **[chatwoot]**
- **`Invalid appsecret_proof provided`:** `FB_APP_SECRET` mismatch between the app and
  Chatwoot config, or a per-channel secret override drift — re-set the secret and
  reauthorize. **[chatwoot issue #12935]**
- **Vendor sees no Pages / can't connect:** the app is still in **Standard Access** —
  either add them as a test user or finish App Review for Advanced Access. **[meta]**
- **Graph API version errors:** align `FACEBOOK_API_VERSION` with a currently-supported
  Meta Graph API version. **[code]**
- **Token expired:** use the inbox **Reauthorize** action. **[code]**

---

## 8. Sources & authenticity (retrieved 2026-07-06)

Official Meta:
- Messenger Platform overview — https://developers.facebook.com/documentation/business-messaging/messenger-platform/overview
- Messenger/IG messaging policy — https://developers.facebook.com/documentation/business-messaging/messenger-platform/policy
- Instagram API with Instagram Login (messaging) — https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api/
- Instagram Platform overview — https://developers.facebook.com/docs/instagram-platform/overview/
- WhatsApp Embedded Signup — https://developers.facebook.com/documentation/business-messaging/whatsapp/embedded-signup/overview
- Become a Tech Provider (WhatsApp) — https://developers.facebook.com/documentation/business-messaging/whatsapp/solution-providers/get-started-for-tech-providers
- App Review (Responsible Platform Initiatives) — https://developers.facebook.com/docs/resp-plat-initiatives/appreview/

Official Chatwoot:
- Facebook channel setup — https://developers.chatwoot.com/self-hosted/configuration/features/integrations/facebook-channel-setup
- Instagram channel setup — https://developers.chatwoot.com/self-hosted/configuration/features/integrations/instagram-channel-setup
- WhatsApp Embedded Signup — https://developers.chatwoot.com/self-hosted/configuration/features/integrations/whatsapp-embedded-signup

This repository (code-verified): `app/javascript/dashboard/helper/facebookScopes.js`,
`.../composables/useFacebookPageConnect.js`, `.../channels/whatsapp/utils.js`,
`app/controllers/api/v1/accounts/callbacks_controller.rb`,
`app/controllers/api/v1/accounts/instagram/authorizations_controller.rb`,
`app/controllers/api/v1/accounts/whatsapp/authorizations_controller.rb`,
`config/installation_config.yml`; meta-saas `packages/config/src/env.ts`,
`apps/api/src/tenant/channels.controller.ts`,
`apps/api/src/chatwoot/chatwoot-resource.controller.ts`.

> Meta's requirements and permission/scope names change frequently. Before a
> production App Review, re-verify every permission name, product name, and required
> access level against the Meta links above — this doc reflects the state on
> 2026-07-06.

## 9. Related

- `ENTITLEMENTS.md` (inbox caps via `accounts.limits`), `PROVISIONING.md`, `SUPER_ADMIN.md`
- `ROLES_AND_CONTROL.md`, `../../../meta-saas/docs/operations/chatwoot-access-lockdown.md`
</content>
