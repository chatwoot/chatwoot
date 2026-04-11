# LINE Modernization Roadmap Design

## Goal

Modernize Chatwoot's native LINE channel so it can replace custom LINE ingestion and merge pipelines, support LINE Messaging API SDK v2, add LINE Notification Messages / PNP, and leave a clean path for later LINE group and room support.

## Why this is split into phases

The current Chatwoot LINE integration is a narrow 1:1 implementation built on `line-bot-api` v1 patterns. The requested target state combines four separate concerns:

- core SDK and webhook modernization
- canonical LINE identity and merge behavior
- Notification Messages / PNP
- multi-party group and room support

These concerns have different risk profiles. Group and room support requires new conversation and participant modeling that does not exist in Chatwoot's current LINE or Instagram channels. PNP has a separate API surface and delivery webhook behavior. Identity and merge compatibility must be stable before either of those can safely build on top of it.

For that reason, the roadmap is foundation-first and phase-gated.

## Current state

### Native LINE

- Uses `line-bot-api` v1-style `Line::Bot::Client`.
- Verifies webhook signatures manually.
- Assumes 1:1 `userId` sources.
- Stores canonical LINE identity in `contact_inboxes.source_id`.
- Also stores `social_line_user_id` in contact `additional_attributes`.
- Does not model `line_handle` as a first-class custom attribute.

### Existing custom pipeline requirements

The current external LINE merge flow depends on:

- `custom_attributes.line_handle` as a dedup and lookup key
- `additional_attributes.social_line_user_id` as the "full LINE contact" signal
- migration-safe behavior for pre-customers that have `line_handle` but do not yet have `social_line_user_id`

If native LINE is intended to replace the custom pipeline, Chatwoot must absorb that identity model instead of treating it as deployment-specific glue.

### Instagram as a comparison point

Instagram is useful as a reference for single-user social identity plumbing, not for multi-party messaging:

- It uses `contact_inboxes.source_id` for the external user id.
- It stores additional social metadata on the contact.
- It does not provide a reusable multi-party conversation model in Chatwoot.

This makes Instagram a useful pattern for canonical identity storage, but not a template for LINE group or room support.

## Phase roadmap

### Phase 1: Native LINE core and canonical identity model

Purpose:

- move native LINE to SDK v2
- stabilize inbound and outbound 1:1 behavior
- make LINE identity merge-compatible with current real-world usage

Deliverables:

- SDK v2 client and webhook parser adoption
- deterministic 1:1 contact resolution rules
- mirrored `custom_attributes.line_handle`
- preserved `additional_attributes.social_line_user_id`
- message idempotency and dedup hardening

Non-goals:

- PNP sending
- PNP delivery webhooks
- group or room conversations

Success criteria:

- native 1:1 LINE can replace custom LINE identity hacks for new traffic
- pre-customer contacts with `line_handle` can be upgraded into real LINE contacts without duplication

### Phase 2: LINE Notification Messages / PNP

Purpose:

- support programmatic LINE notification sends
- support delivery tagging and delivery completion events
- ensure users reached via PNP can reply into the native 1:1 LINE pipeline

Deliverables:

- PNP send service layer
- templated and flexible endpoint support strategy
- delivery tag persistence
- delivery completion webhook processing
- account and inbox-level eligibility and configuration rules

Non-goals:

- generalized campaign orchestration
- group messaging

Success criteria:

- Chatwoot can send approved LINE notification messages and observe delivery completion
- if the contacted user replies, native LINE receives and routes the reply normally

### Phase 3: Migration and cutover from the custom merge pipeline

Purpose:

- move existing data and workflows safely from the custom pipeline to native Chatwoot LINE

Deliverables:

- backfill and reconciliation strategy for existing contacts
- migration-safe lookup and enrichment rules
- duplicate prevention rules for in-flight conversations and messages
- operational cutover runbook

Non-goals:

- adding new channel capabilities

Success criteria:

- no contact fragmentation during cutover
- existing `line_handle`-only contacts can resolve into the canonical native LINE model

### Phase 4: LINE groups and rooms architecture

Purpose:

- design proper support for LINE multi-party conversation sources

Deliverables:

- group and room identity model
- shared-thread conversation rules
- per-message sender attribution model
- participant membership event handling
- UI requirements for multi-party channels

Non-goals:

- forcing group support into the 1:1 foundation phases

Success criteria:

- a design that can support LINE groups cleanly without distorting the 1:1 data model
- a decision on whether to build a LINE-specific solution or a generalized external participant framework

## Phase dependencies

- Phase 1 is required before any other phase.
- Phase 2 depends on Phase 1 because reply capture and identity normalization must already be correct.
- Phase 3 depends on Phase 1 and should be informed by Phase 2 if PNP recipients are part of the migration path.
- Phase 4 is intentionally independent of the first three phases from a delivery standpoint, but should reuse the canonical identity model introduced in Phase 1.

## Design decisions

### 1. Canonical LINE identity must be native

Native Chatwoot LINE must own the following identity model:

- `contact_inboxes.source_id` remains the inbox-scoped canonical external id for active LINE users
- `additional_attributes.social_line_user_id` remains the explicit full LINE identity marker
- `custom_attributes.line_handle` is added and mirrored as the compatibility lookup key

This is a product-level identity decision, not just a migration shim.

### 2. PNP delivery events should not create conversations

Delivery completion events are delivery state, not user-authored conversation messages. They should update status and observability, not create synthetic user threads.

### 3. PNP replies belong in the native LINE message pipeline

If a user who received a notification message replies, that reply should enter the same native inbound LINE path as any other 1:1 message.

### 4. Group and room support is a separate architecture problem

LINE group and room webhooks involve shared thread identity plus per-message sender identity. That is materially different from the current 1:1 model and should not be smuggled into the same phase as the SDK v2 migration.

## Risks

### Identity ambiguity

Matching by `line_handle` can bind native LINE traffic to existing contacts that were created outside the native channel. This is desired for migration, but the precedence rules must be explicit and deterministic.

### Data drift during cutover

If both the custom pipeline and native LINE process the same inbound traffic during transition, duplicate contacts or conversations are possible. Phase 3 needs explicit operational sequencing.

### SDK coverage gaps

The upstream Ruby SDK provides SDK v2 support for the Messaging API, but Notification Messages endpoint coverage is incomplete for the newer templated surfaces. Phase 2 must allow a small native HTTP client where the SDK does not cover the needed endpoint.

### Group scope creep

Trying to solve group and room support inside the first three phases will slow or destabilize the work that replaces the custom 1:1 pipeline.

## Acceptance gate for moving between phases

Do not begin the next implementation plan until the previous phase is complete and verified:

- Phase 1 gate: native 1:1 LINE identity is stable
- Phase 2 gate: PNP sending and reply capture are stable
- Phase 3 gate: custom pipeline can be retired safely
- Phase 4 gate: only after the 1:1 foundation is proven

## Documents produced from this roadmap

- Phase 1 design: `2026-04-11-line-core-v2-identity-design.md`
- Phase 2, 3, and 4 designs are intentionally gated and should only be written after the preceding phase is reviewed and accepted

## Out of scope for this roadmap

- non-LINE channel refactors not required by the LINE work
- generalized cross-channel participant architecture in the first pass
- campaign UI or productization beyond the PNP surfaces needed for Chatwoot to send and track notification messages
