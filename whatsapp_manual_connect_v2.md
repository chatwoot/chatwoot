# WhatsApp Manual Connect V2

## Goal

Replace the current single-screen WhatsApp Cloud API form with a guided manual connection flow that helps non-technical administrators connect an already-onboarded WhatsApp number, validates the supplied Meta assets before creating the inbox, and confirms that Chatwoot can receive webhooks before continuing to agent assignment.

This plan covers new manual WhatsApp inbox creation. It does not replace the separate flow for migrating or reconnecting an existing inbox.

## Confirmed Product Decisions

- Ask for only:
  - WhatsApp Business Account ID (WABA ID).
  - Phone Number ID.
  - Permanent system-user access token.
- Do not ask for or store the Meta App ID.
- Do not ask for or store the Meta App Secret in this iteration.
- Do not ask the user to type the WhatsApp display phone number.
- Resolve the phone number and verified business name from Meta.
- Use the verified business name as the default inbox name, with the resolved phone number as the fallback.
- Let the user optionally edit the generated inbox name during review.
- Configure the webhook automatically.
- Add a real webhook verification step before the user continues to agent assignment.
- Keep manual callback URL and verify-token instructions as a recovery path only when automatic setup fails.

## Important Security Boundary

Manual V2 will continue the current manual-flow behavior of accepting WhatsApp webhook payloads without validating `X-Hub-Signature-256`, because Chatwoot will not have the customer's Meta App Secret.

The webhook verification described in this plan proves that Meta can reach the Chatwoot callback and that the app is subscribed to the required WhatsApp events. It does not prove the authenticity of every later webhook payload. Signature verification for customer-owned Meta apps is deferred work and should not be implied as complete in the UI.

## Experience Structure

Manual Connect V2 lives inside the standard `Create inbox` stage so the existing `Choose channel`, `Create inbox`, `Add agents`, and `Finish` wizard remains visible and consistent with other channel setups. The WhatsApp content pane uses its own focused five-step progress header, then continues to the existing `Add agents` and `Finish` stages after verification.

The experience follows the task sequence used in Meta rather than presenting every field at once. Every administrator follows the Meta app step so the prerequisites are clear and the flow remains consistent. Guidance is built from Chatwoot-native instructions, direct links, and short walkthrough media; it does not copy another product's visual identity.

### Step 1: Create Or Select A Meta App

Guide the administrator to:

- Open Meta Developers.
- Create a new app or select the app already used by the number.
- Enable the WhatsApp use case.
- Select the business portfolio that owns or will own the number.

Primary action: `My Meta app is ready`.

### Step 2: Add The Phone Number And Get IDs

Guide the administrator through the Meta app's WhatsApp API Setup screen:

- Select or add the production phone number.
- Complete the WhatsApp business profile.
- Complete OTP verification.
- Copy the Phone Number ID and WABA ID.

Fields:

- WABA ID.
- Phone Number ID.

Field behavior:

- Use neutral placeholders such as `Enter WABA ID` and `Enter Phone Number ID`.
- Explain where each value is found immediately below its field.
- Keep entered values when validation fails.

Primary action: `Next`.

### Step 3: Generate A Permanent Access Token

Guide the administrator through Meta Business Settings:

- Create or select an admin system user.
- Assign the Meta app and WhatsApp Business Account.
- Grant full control for the assigned WhatsApp assets.
- Generate a token that never expires.
- Select `whatsapp_business_messaging` and `whatsapp_business_management`.

Render the token as a password field with an explicit show/hide control and remind the administrator that Meta displays it only once.

- Keep the entered value when validation fails.
- Never place the access token in a query string, URL, analytics event, or client-side log.

Primary action: `Verify details`.

### Step 4: Review And Connect

After validation, show Meta-resolved information:

- Verified business name.
- Display phone number.
- Phone Number ID.
- WABA ID.
- Phone-number verification status.
- Template access status.

Inbox naming:

- Default to `<verified business name> WhatsApp`.
- Fall back to `<display phone number> WhatsApp` when Meta does not return a verified name.
- Allow the administrator to edit the inbox name here.
- Do not introduce a separate `WhatsApp number name` field.

Primary action: `Connect number`.

### Step 5: Verify Connection

Create the inbox, configure the webhook, and show concrete connection checks:

- `Number access` — Chatwoot can retrieve the exact Phone Number ID under the supplied WABA.
- `Messaging access` — the token can access the APIs required for WhatsApp messaging.
- `Template access` — the token can access WABA templates.
- `Webhook callback` — Meta completed the callback challenge against Chatwoot.
- `Webhook subscription` — the app is subscribed to at least `messages` and `smb_message_echoes`.

Required checks before continuing:

- Number access.
- Messaging access.
- Webhook callback.
- Webhook subscription.

Template access is required for the initial V2 scope because Chatwoot depends on template sync and template messaging. If product requirements later allow messaging-only inboxes, this can become a warning through a separate decision.

Actions:

- `Retry webhook setup` when callback or subscription setup fails.
- `View manual instructions` as a recovery option after automatic setup fails.
- `Continue to add agents` only after the required checks pass.

Do not show a fully connected success state while a required check is red. Do not use optimistic green checkmarks before the corresponding backend verification completes.

## Backend Validation

Introduce a manual-setup validation service that is shared by the preview and create operations.

Required validation sequence:

1. Require WABA ID, Phone Number ID, and access token.
2. Fetch `GET /{waba_id}/phone_numbers` using `Authorization: Bearer <token>`.
3. Follow pagination until the requested Phone Number ID is found or all pages are exhausted.
4. Match the requested Phone Number ID exactly.
5. Do not fall back to the first number in the WABA.
6. Normalize the returned display phone number to Chatwoot's canonical E.164 representation.
7. Require `code_verification_status == VERIFIED` for this already-onboarded-number flow.
8. Check that no other `Channel::Whatsapp` uses the same normalized phone number.
9. Check that no other `Channel::Whatsapp` has the same `provider_config.phone_number_id`.
10. Verify template access with `GET /{waba_id}/message_templates` using the authorization header.
11. Return a sanitized preview containing only the resolved number metadata and validation results.

Do not return or echo the access token in the validation response.

### Blockers

- The token cannot access the WABA.
- The requested Phone Number ID is not present under the WABA.
- The phone number has not completed code verification.
- The phone number is already connected to another Chatwoot inbox.
- The Phone Number ID is already connected to another Chatwoot inbox.
- The token cannot access messaging or templates.

### Actionable Error Copy

Prefer errors that tell the administrator what to fix:

- `We could not access this WhatsApp Business Account with the provided token. Confirm that the system user has access to this WABA.`
- `This Phone Number ID does not belong to the WABA ID you entered.`
- `This WhatsApp number has not completed verification in Meta.`
- `This WhatsApp number is already connected to another inbox.`
- `This Phone Number ID is already used by another WhatsApp inbox.`
- `The token can access the number but cannot access message templates. Generate a token with whatsapp_business_management permission.`

Raw Meta errors may be logged for diagnostics, but the primary UI message should remain concise and actionable.

## Connection API Shape

Add account-scoped endpoints under the existing WhatsApp API namespace.

### Preview

`POST /api/v1/accounts/:account_id/whatsapp/manual/preview`

Request:

```json
{
  "waba_id": "...",
  "phone_number_id": "...",
  "access_token": "..."
}
```

Response:

```json
{
  "verified_name": "Acme",
  "display_phone_number": "+15551234567",
  "phone_number_id": "...",
  "waba_id": "...",
  "code_verified": true,
  "template_access": true,
  "suggested_inbox_name": "Acme WhatsApp"
}
```

### Connect

`POST /api/v1/accounts/:account_id/whatsapp/manual/connect`

Request:

```json
{
  "waba_id": "...",
  "phone_number_id": "...",
  "access_token": "...",
  "inbox_name": "Acme WhatsApp"
}
```

The connect operation must repeat the full validation. Do not trust the earlier browser preview as proof that the identifiers are still valid.

Connection behavior:

1. Re-run strict validation.
2. Create the `Channel::Whatsapp` and inbox with source `manual_setup_v2`.
3. Generate the webhook verify token through the existing channel behavior.
4. Subscribe the token's app to the WABA.
5. Configure the phone-level callback override.
6. Return the created inbox and individual connection-check results.

The V2 source must skip the existing automatic `after_commit` webhook callback so the explicit connection operation is the only setup attempt. This avoids duplicate Meta calls and lets the API return the real result to the UI.

If database creation succeeds but webhook setup fails, retain the inbox in an incomplete state and return its ID with the failed checks. Do not delete a newly created channel after making Meta-side changes. Keep the user on the verification step and allow a safe retry.

### Retry Webhook Setup

`POST /api/v1/accounts/:account_id/inboxes/:inbox_id/whatsapp/webhook/setup`

- Restrict the action to administrators.
- Restrict it to WhatsApp Cloud API inboxes created through Manual V2.
- Re-run WABA subscription and phone callback setup idempotently.
- Return each webhook check independently.
- Do not mutate unrelated inbox settings.

### Webhook Status

`GET /api/v1/accounts/:account_id/inboxes/:inbox_id/whatsapp/webhook/status`

Return:

- Callback challenge observed.
- WABA subscription configured.
- Required subscribed fields configured.
- Last setup error in a sanitized form, if available.

## Recording Webhook Verification

Add `webhook_verified_at` to `channel_whatsapp`.

When `Webhooks::WhatsappController#verify` receives the correct verify token:

1. Return Meta's challenge as it does today.
2. Record `webhook_verified_at` for the matched channel without triggering remote provider validation.

The connection screen should not mark the callback as verified until this timestamp is present. A successful outbound Graph API call by itself is not enough evidence that Meta reached the Chatwoot endpoint.

Use the existing WABA subscription and phone-level callback APIs rather than asking the user to configure the callback manually in the normal path.

## Frontend Implementation

- Replace `CloudWhatsapp.vue` for `provider=whatsapp_manual` with a new Composition API component such as `WhatsappManualSetup.vue`.
- Render the manual guide inside the standard `Create inbox` content pane while preserving the existing provider picker and legacy component for unrelated providers.
- Store field state in the component only; do not persist the access token to local storage.
- Use existing `components-next` inputs, buttons, alerts, and status patterns.
- Use Tailwind utility classes only.
- When walkthrough media is available, prefer short muted MP4/WebM clips with a poster image and text instructions as the accessible fallback. Avoid GIFs because they are larger and provide weaker playback controls.
- Add frontend copy only to `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`.
- Route successful webhook verification to the existing `settings_inboxes_add_agents` page.
- Update `FinishSetup.vue` so Manual V2 inboxes show the normal completed state instead of asking users to configure the callback again.
- Preserve the current callback URL and verify-token display for legacy manual inboxes and as the V2 recovery view.

## Backend Implementation Areas

Expected files or responsibilities:

- A manual setup controller under `Api::V1::Accounts::Whatsapp`.
- A strict manual validation service.
- Reuse or extend `Whatsapp::PhoneInfoService` without changing legacy fallback behavior for unrelated callers.
- Reuse `Whatsapp::ChannelCreationService` where practical, while allowing the Manual V2 source and user-reviewed inbox name.
- Reuse `Whatsapp::WebhookSetupService` for the actual subscription and callback override.
- Extend `Whatsapp::FacebookApiClient` for paginated phone lookup and webhook-status reads where required.
- Add account-scoped routes.
- Add `webhook_verified_at` to the WhatsApp channel schema.
- Check Enterprise overlays for affected controllers, serializers, routes, and inbox behavior before editing shared code.

## Out Of Scope

- Meta Embedded Signup changes.
- Migrating or reconnecting an existing WhatsApp inbox.
- Creating a new WABA or provisioning a new phone number inside Chatwoot.
- Fresh WhatsApp Business App Coexistence onboarding.
- Collecting Meta Business Portfolio ID.
- Collecting or storing Meta App ID.
- Collecting or storing Meta App Secret.
- HMAC validation for customer-owned manual Meta apps.
- Automatically repairing Meta business verification, billing, payment, quality, or restriction problems.
- Changing agent assignment or the final inbox setup screens beyond the Manual V2 routing and success copy.

## Rollout

1. Test with an internal WABA and one already-onboarded production-like number.
2. Verify inbound messages, outbound session messages, outbound templates, media, template sync, and webhook retry behavior.
3. Pilot with one assisted customer.
4. Compare setup completion and support-failure rates against the legacy form.
5. Keep the existing Help Center article until the new screenshots and Meta navigation are verified against the released flow.

## Acceptance Criteria

- A user can complete setup without typing the display phone number.
- A user does not need to invent an inbox name.
- Meta App ID and App Secret are never requested or stored.
- A mismatched WABA ID and Phone Number ID are blocked before inbox creation.
- A duplicate Phone Number ID is blocked even when the display number differs.
- The phone lookup never silently selects the first number in the WABA.
- The access token is sent to Meta only through the authorization header.
- Webhook setup happens automatically and its result is visible.
- The user cannot continue to agent assignment until callback verification and required subscriptions pass.
- A webhook failure can be retried without recreating the inbox.
- The UI does not claim that webhook payload signatures are verified.
- Legacy manual inboxes continue to work and retain their existing recovery instructions.
