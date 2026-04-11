# LINE Core v2 and Canonical Identity Design

## Goal

Upgrade Chatwoot's native LINE channel to the v2 SDK and make its 1:1 identity model strong enough to replace the current custom LINE merge pipeline for real users.

## Problem statement

The current native LINE channel is not sufficient for the target state:

- it uses `line-bot-api` v1 APIs
- it manually verifies signatures and parses webhook payloads
- it only models canonical LINE identity as `source_id` plus `social_line_user_id`
- it does not natively model `custom_attributes.line_handle`
- it does not provide deterministic behavior for pre-customers that already exist with only `line_handle`

The first phase must solve that foundation before PNP or group support are layered on top.

## Goals

- move native LINE 1:1 behavior to SDK v2
- preserve current 1:1 product behavior where possible
- formalize canonical LINE identity fields
- support migration-friendly lookup of existing contacts that only have `line_handle`
- avoid creating duplicate contacts, contact inboxes, conversations, or messages for the same LINE user and message

## Non-goals

- LINE Notification Messages / PNP sending
- PNP delivery completion events
- LINE group or room support
- manual backfill scripts for historical data

## Existing implementation

### Channel

`Channel::Line` currently builds a single `Line::Bot::Client` instance using:

- `line_channel_id`
- `line_channel_secret`
- `line_channel_token`

### Inbound

Inbound LINE handling currently:

- receives the raw request in `Webhooks::LineController`
- passes the body and signature into `Webhooks::LineEventsJob`
- validates the signature manually
- treats `event['source']['userId']` as required
- calls `get_profile(userId)`
- creates or finds a contact inbox by LINE `userId`
- stores `social_line_user_id` in `additional_attributes`

### Outbound

Outbound LINE handling currently:

- uses `contact_inbox.source_id` as the LINE recipient id
- uses `push_message`
- handles text, input_select converted to flex messages, and image or video attachments

## Required target behavior

### Identity rules

For 1:1 native LINE contacts:

- `contact_inboxes.source_id` remains the inbox-scoped canonical active LINE id
- `additional_attributes.social_line_user_id` remains the explicit full LINE identity field
- `custom_attributes.line_handle` becomes a mirrored compatibility key

### Lookup rules

When an inbound LINE 1:1 message arrives for `line_user_id`, resolution must happen in this order:

1. existing contact inbox in the inbox with `source_id == line_user_id`
2. existing contact in the account whose `additional_attributes.social_line_user_id == line_user_id`
3. existing contact in the account whose `custom_attributes.line_handle == line_user_id`
4. create a new contact and contact inbox

If rule 2 or 3 matches a contact but no inbox contact inbox exists yet, create the inbox-scoped `contact_inbox` for that matched contact instead of creating a new contact.

### Enrichment rules

Once a LINE user is matched successfully:

- ensure `additional_attributes.social_line_user_id` is set to `line_user_id`
- ensure `custom_attributes.line_handle` is set to `line_user_id`
- preserve any pre-existing contact attributes that came from other systems unless the native LINE profile is clearly authoritative for that field

This allows a line-handle-only pre-customer to become a native LINE contact without requiring a separate merge job in the hot path.

## Design

### 1. Replace the v1 LINE client with explicit v2 clients

`Channel::Line` should expose separate SDK v2 helpers:

- messaging client for send and profile APIs
- blob client for attachment download
- webhook parser for signature verification and typed event parsing

Phase 1 should keep the existing persisted channel fields and admin UI field names intact. `line_channel_token` can continue to store the LINE channel access token even if the SDK v2 constructor names it differently.

This minimizes schema churn while moving the integration to supported APIs.

### 2. Move webhook validation and parsing to the v2 parser

`Webhooks::LineEventsJob` should stop manually recomputing the HMAC and instead:

- load the channel from the webhook path parameter
- instantiate the v2 webhook parser with `line_channel_secret`
- parse the raw body and signature into typed events
- pass parsed events into the LINE inbound service

This removes custom verification logic and aligns with the official SDK path.

### 3. Keep the 1:1 inbound service focused on message events

Phase 1 should continue to process 1:1 message events only.

Expected supported event handling:

- text messages
- sticker messages
- media and file messages that can be downloaded through the blob client

Expected skipped or deferred handling:

- group and room message sources
- PNP delivery completion events
- other non-message events unless already required for current 1:1 behavior

### 4. Introduce canonical LINE identity resolution

The inbound service should no longer assume "no contact inbox means create a new contact."

Instead it should:

- resolve the `line_user_id`
- try to find the inbox-scoped contact inbox
- if not found, try account-scoped contact matches through `social_line_user_id`
- if not found, try account-scoped contact matches through `line_handle`
- create the missing contact inbox for the resolved contact when necessary
- enrich the matched contact with the canonical LINE fields

This replaces the need for an external merge pipeline in the normal inbound path.

### 5. Mirror LINE identity onto `line_handle`

For native LINE 1:1 contacts, `custom_attributes.line_handle` should always mirror the canonical LINE user id.

Reasons:

- this keeps native LINE compatible with existing real-world lookup behavior
- it gives filters and automations a stable custom attribute without requiring them to inspect `additional_attributes`
- it lets line-handle-only contacts resolve cleanly into the native channel model

### 6. Harden idempotency and dedup

Phase 1 should explicitly prevent duplicate inbound messages when the same webhook event is delivered more than once.

Rules:

- the LINE message id remains the message `source_id`
- inbound message creation must first check whether a message with that `source_id` already exists for the inbox
- duplicate webhook deliveries must no-op instead of creating another message

This is more important during migration because duplicate deliveries may be misinterpreted as pipeline conflicts.

### 7. Preserve current outbound recipient semantics

Outbound sending should continue to use the inbox-scoped `contact_inbox.source_id` as the LINE user id for 1:1 messages.

This is compatible with the canonical model because Phase 1 defines that `source_id` remains the active inbox-scoped LINE identity.

## Files expected to change

Primary files:

- `app/models/channel/line.rb`
- `app/jobs/webhooks/line_events_job.rb`
- `app/services/line/incoming_message_service.rb`
- `app/services/line/send_on_line_service.rb`
- `app/controllers/webhooks/line_controller.rb`
- `spec/jobs/webhooks/line_events_job_spec.rb`
- `spec/services/line/incoming_message_service_spec.rb`
- `spec/services/line/send_on_line_service_spec.rb`
- `spec/controllers/webhooks/line_controller_spec.rb`

Possible supporting changes:

- factories for LINE contacts and channels
- contact lookup helpers if the matching logic deserves extraction
- strong parameter or serialization behavior only if `line_handle` needs explicit handling in contact surfaces

## Data model implications

Phase 1 should avoid schema changes if possible.

Assumptions:

- `custom_attributes` already supports storing `line_handle`
- `additional_attributes` already supports storing `social_line_user_id`
- `contact_inboxes.source_id` remains the inbox-scoped unique channel identifier

If a custom attribute definition for `line_handle` is needed for filtering or UI discoverability, that should be handled deliberately but should not block the core identity plumbing.

## Risks and mitigations

### Risk: ambiguous contact match

If multiple contacts in the same account match `line_handle` or `social_line_user_id`, the service could enrich the wrong contact.

Mitigation:

- define deterministic winner rules
- log and fail safely when multiple matches exist instead of silently choosing an arbitrary record

### Risk: overwriting richer contact data

Native LINE profile data may be lower quality than existing CRM or Shopline data.

Mitigation:

- only update LINE-specific fields automatically
- avoid overwriting core contact profile fields unless the current value is blank

### Risk: webhook parser migration changes event shapes

The v2 SDK yields typed events instead of the old raw hash access pattern.

Mitigation:

- isolate event-to-internal-params translation in one place
- keep business logic tests focused on the normalized internal shape

## Acceptance criteria

- native LINE uses SDK v2 clients and parser
- 1:1 inbound messages still create and update conversations correctly
- a contact that already has `line_handle == line_user_id` is enriched and reused instead of duplicated
- native LINE contacts always end up with both `social_line_user_id` and mirrored `line_handle`
- duplicate webhook deliveries do not create duplicate messages
- outbound 1:1 sending continues to work for text, input_select/flex, and supported attachments

## Explicitly deferred to later phases

- PNP send and delivery workflow
- migration backfill scripts and cutover runbook
- group and room modeling
- generalized external participant infrastructure
