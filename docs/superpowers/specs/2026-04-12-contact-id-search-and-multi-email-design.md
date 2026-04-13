# Contact ID Search And Multi-Email Design

## Summary

This change adds two related contact-management improvements to Chatwoot:

1. Contact merge search should support exact contact ID lookup in addition to the existing text-based contact search fields.
2. Contacts should support multiple email addresses while preserving Chatwoot's current contact and email-channel behavior.

The recommended implementation keeps `contacts.email` as the primary cached email for compatibility, but introduces a new `contact_emails` table as the source of truth for contact email identities. This gives us account-scoped uniqueness, direct lookup for inbound email matching, safer merge behavior, and a path to evolve the UI and API without rewriting every `contact.email` callsite in one PR.

Twenty's local implementation was reviewed for inspiration. Twenty models multiple emails as a composite field with `primaryEmail` plus `additionalEmails`. That data shape is useful conceptually, but Chatwoot has stronger identity and routing requirements than a CRM-only record store. Because Chatwoot must do account-scoped uniqueness, relational merge reassignment, and inbound email lookup under concurrency, a dedicated table is the better fit here than a JSON array on `contacts`.

## Goals

- Let agents find merge targets by typing an exact contact ID into the merge combobox.
- Allow a single contact to own multiple email addresses.
- Treat every stored contact email as a real identity for:
  - inbound email matching
  - contact search
  - contact merge
  - email continuity and reply addressing
- Preserve backward compatibility for the majority of existing code that reads `contact.email`.

## Non-Goals

- Full replacement of every `contact.email` reference in the codebase.
- A broad redesign of contact editing UI beyond what is needed to create, edit, and display multiple emails.
- A generalized polymorphic identity system for phone numbers, social handles, or external IDs.
- Bulk migration of all filters and integrations to expose new secondary-email semantics in one pass, unless required by the paths touched in this feature.

## Current State

### Merge Search

The merge UI in `app/javascript/dashboard/components-next/Contacts/ContactsSidebar/ContactMerge.vue` uses `ContactAPI.search(query)`. The backend `GET /contacts/search` endpoint in `Api::V1::Accounts::ContactsController#search` currently matches:

- `name ILIKE`
- `email ILIKE`
- `phone_number ILIKE`
- `contacts.identifier LIKE`

It does not match `contacts.id`, which is why numeric contact IDs such as `133741` are not discoverable from the merge picker today.

### Email Identity

Chatwoot currently stores one email directly on `contacts.email` and enforces account-scoped uniqueness there. Email-specific behavior is spread across:

- `Contact.from_email`
- `ContactInboxWithContactBuilder`
- `Mailbox::ConversationFinderStrategies::NewConversationStrategy`
- `Imap::ImapMailbox`
- `DataImport::ContactManager`
- `ContactMergeAction`
- `ConversationReplyMailer`
- dashboard contact CRUD/search UI
- enterprise services that derive company or prompt data from `contact.email`

This works for single-email contacts, but it prevents one contact from legitimately owning more than one email identity.

## Proposed Design

### 1. New `contact_emails` table

Add a new model:

- `ContactEmail`
- columns:
  - `id`
  - `account_id`
  - `contact_id`
  - `email`
  - `primary` boolean
  - timestamps

Constraints and indexes:

- unique index on normalized email per account
- unique partial index on one primary email per contact
- foreign keys to `accounts` and `contacts`

Rules:

- all emails are normalized to lowercase before validation and persistence
- each stored email must match `Devise.email_regexp`
- each contact may have zero emails, or one or more emails with exactly one primary when any email rows exist
- `contact_emails.account_id` must match `contact.account_id`

### 2. Keep `contacts.email` as a compatibility mirror

`contacts.email` remains in place for now, but it becomes a cached mirror of the primary contact email.

Behavior:

- when a contact has a primary `contact_email`, `contacts.email` must equal that primary email
- when a contact has no email rows, `contacts.email` is `nil`
- existing serializers and untouched code paths can continue reading `contact.email`

This lets us ship the identity change without an all-at-once API break.

### 3. Contact model helpers

Extend `Contact` with helpers along these lines:

- `has_many :contact_emails`
- `has_one :primary_contact_email, -> { where(primary: true) }, class_name: 'ContactEmail'`
- `primary_email`
- `all_emails`
- `email?`
- updated `from_email`

`Contact.from_email(email)` should resolve via `contact_emails` rather than the legacy column.

For search and preload efficiency, this query should join or subquery against `contact_emails` instead of scanning JSON or Ruby-side collections.

### 4. Migration strategy

The migration should backfill one primary `contact_emails` row from each non-null `contacts.email`.

Steps:

1. Create `contact_emails`.
2. Backfill one primary row per existing `contacts.email`.
3. Add or update model callbacks/service sync so primary changes keep `contacts.email` mirrored.
4. Move targeted lookup/search/merge flows to the new table.

The existing unique constraint on `contacts.email` stays in place for this PR. Because `contacts.email` mirrors only the primary contact email, and primary emails remain unique per account through `contact_emails`, the legacy constraint remains compatible with the rollout.

## Feature 1: Merge Search By Contact ID

### Backend

Update `Api::V1::Accounts::ContactsController#search` so a numeric query can match exact `contacts.id`.

Recommended behavior:

- preserve existing fuzzy text search behavior for name/email/phone/identifier
- add exact `contacts.id = ?` matching when the trimmed query is fully numeric

Why exact numeric match instead of `ILIKE` on casted ID:

- avoids broad accidental matches on large result sets
- aligns with how users think about contact numbers as an exact identifier
- keeps query behavior predictable

### Frontend

Update merge picker UI copy so the user can discover the capability:

- placeholder/search hint should explicitly say `Search by name or ID`
- result labels can continue showing `(ID: <id>) <name>`

No API shape change is required for feature 1.

## Feature 2: Multi-Email Contact Identity

### Contact create/update API

Augment the contacts API to accept a multi-email payload while staying backward compatible.

Recommended request contract:

- continue accepting legacy `email`
- add `emails`, shaped as an array of strings or an object with explicit primary and additional values

For this PR, the safest server contract is:

- `email`: optional string for legacy clients
- `emails`: optional array of strings

Server-side normalization:

- deduplicate case-insensitively
- preserve first email as primary unless the client explicitly indicates another primary in a future enhancement
- if only `email` is provided, treat it as a single primary email
- if `emails` is provided, derive `contacts.email` from the chosen primary

This keeps the API simple while the dashboard is the only writer.

### Dashboard contact UI

Update the contact edit/create form to support multiple emails:

- show one primary email input and an editable list of additional email inputs
- keep the primary email visually distinct
- normalize and dedupe client-side where convenient, but rely on server validation as the authority

Display:

- contact sidebar and contact profile should show the primary email prominently
- secondary emails should also be visible where an agent expects to verify contact identity

### Lookup and inbound email matching

These flows must use `contact_emails` instead of only `contacts.email`:

- `Contact.from_email`
- `ContactInboxWithContactBuilder#find_contact_by_email`
- `DataImport::ContactManager#find_contact_by_email`
- `Mailbox::ConversationFinderStrategies::NewConversationStrategy#find_or_create_contact`
- `Imap::ImapMailbox#find_or_create_contact`
- `ContactIdentifyAction` email-based merge path

Matching rule:

- any normalized email owned by the contact should resolve the contact

### Email continuity and reply addressing

A contact may have multiple valid email identities. For outbound continuity, the reply should prefer the actual address tied to the current email conversation when available, not blindly the primary email.

Recommended behavior:

- if the current conversation is an email conversation and `conversation.contact_inbox.source_id` is one of the contact's emails, use that as the first `to` address
- otherwise fall back to the contact's primary email
- if explicit `to_emails` exist in message content attributes, they still take precedence

This preserves continuity when the contact wrote from a secondary email address.

### Merge behavior

`ContactMergeAction` must merge email identities, not just scalar `contacts.email`.

Rules:

- reassign all `contact_emails` from mergee to base contact
- if both contacts own overlapping normalized emails, collapse duplicates safely
- preserve the base contact's primary email if present
- if the base has no primary and mergee does, promote one merged email to primary
- after merge, sync `contacts.email` from the resulting primary

This is the core reason to prefer rows over JSON arrays: merge is a relational reassignment problem.

### Search behavior

Contact search should match:

- contact name
- any `contact_emails.email`
- phone number
- identifier
- exact numeric `contacts.id` when query is numeric

The response payload remains backward compatible by returning:

- `email` as the primary email
- `emails` as the full ordered list for the contact endpoints used by the dashboard

For this PR, `show`, `index`, and `search` contact payloads include `emails`.

## Enterprise Compatibility

Enterprise code currently reads `contact.email` in several places, including company association and LLM prompt helpers. Because `contacts.email` remains mirrored from the primary email, those paths should continue to work without enterprise-specific overrides for the first PR.

Still, touched areas should be reviewed for:

- direct email lookup logic that should move to `Contact.from_email`
- places where showing only the primary email would be misleading

## Testing Strategy

Follow TDD with focused request/model/service specs first.

### Backend

- `ContactsController` search spec:
  - exact contact ID search returns the correct contact
  - email search matches secondary emails
- `ContactsController` create/update/show spec:
  - accepts `emails`
  - mirrors the primary email to `contacts.email`
  - returns `emails` in payloads
- `ContactEmail` model spec:
  - normalization
  - uniqueness per account
  - one-primary rule
  - account/contact consistency
- `Contact` model or service spec:
  - `from_email` resolves primary and secondary emails
  - primary email mirrors to `contacts.email`
- `ContactMergeAction` spec:
  - merged contacts keep all unique emails
  - primary precedence is correct
  - duplicates collapse
- mailbox/contact builder specs:
  - inbound email from a secondary email resolves the correct existing contact
- mailer/service spec:
  - email replies prefer the current email conversation address before primary fallback

### Frontend

- contact API spec for `emails` request and response payloads
- contact form/component tests for multi-email editing behavior
- merge component test for copy/search intent if practical

## Risks

### Legacy uniqueness drift

If `contacts.email` keeps a unique database index while secondary emails are added in `contact_emails`, the old constraint can become a rollout blocker or create redundant invariants. The migration and validation plan must explicitly reconcile this.

### Conversation reply target ambiguity

Once multiple emails exist, defaulting all outbound email continuity to `contact.email` can send replies to the wrong address. The conversation-specific email identity must be preferred when present.

### Partial adoption bugs

If some lookup paths are migrated and others still rely directly on `contacts.email`, behavior will feel inconsistent. The implementation plan should group all email-identity entry points into the first backend slice.

## Recommended Implementation Slices

1. Add `contact_emails`, backfill, model helpers, and primary mirroring.
2. Add exact numeric contact ID search for merge and general contact search.
3. Migrate backend identity lookups and merge logic to `contact_emails`.
4. Add dashboard multi-email form support and payload updates.
5. Update email reply continuity to prefer the conversation's actual email identity.
6. Expand any remaining touched serializers/views with `emails` where required.

## Open Decisions Resolved

- Use exact numeric match for contact ID search.
- Use a dedicated `contact_emails` table rather than JSON on `contacts`.
- Keep `contacts.email` as a mirrored primary email for compatibility.
- Treat all stored emails as first-class identities for inbound matching, search, merge, and email continuity.
