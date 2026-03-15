# Multi-Email Contacts Design

## Problem

Chatwoot currently treats `contacts.email` as a single account-scoped identifier. That works for a single sender address, but it breaks the core "one customer, many conversations/inboxes" model when the same person writes from multiple email addresses. A customer using `bob@gmail.com` and `bo@myworkplace.com` is reconciled as two different contacts unless an agent merges them manually later.

This gap has already been raised publicly in [chatwoot/chatwoot#3079](https://github.com/chatwoot/chatwoot/issues/3079), and the current code still reflects the single-email assumption:

- `Contact` stores one `email` string and enforces account-scoped uniqueness.
- inbound email flows resolve contacts with `from_email`.
- contact identify/import/build flows merge only against one stored email.
- contact search only searches `contacts.email`.

## Goals

- Allow one contact to own multiple email addresses within an account.
- Keep one primary email for display, sorting, and outbound-email defaults.
- Reconcile inbound email, identify flows, and imports against any stored contact email.
- Preserve backward compatibility for existing API consumers that only send a single `email` field.
- Keep Enterprise behavior compatible, especially company association based on the primary email.

## Non-Goals

- Multi-phone support in the same change.
- A generic cross-channel identity system for phone/email/social handles.
- Automatic fuzzy matching by name, domain, or message heuristics.
- Cross-account deduplication.
- A large contact-management UI redesign.

## Approaches Considered

### 1. Store alias emails in `additional_attributes`

Add something like `additional_attributes['email_aliases']` and keep `contacts.email` as primary.

Pros:

- Smallest schema change.
- Minimal disruption to existing serializers.

Cons:

- Case-insensitive uniqueness across contacts becomes awkward and fragile.
- Lookup and search require JSON queries instead of indexed relational lookups.
- Merge logic, validation, and API ergonomics get messy quickly.
- This pushes an identity problem into an unstructured attributes bucket.

### 2. Add a normalized `contact_emails` child table and keep `contacts.email` as the primary cache

Introduce a first-class model for contact email addresses. Every contact email lives in the child table, exactly one child row can be primary, and `contacts.email` mirrors the current primary email for backwards compatibility.

Pros:

- Clean uniqueness guarantees at the database level.
- Fast account-scoped lookup and search using indexed rows.
- Existing code that still reads `contact.email` keeps working.
- Leaves room to generalize later without forcing a generic identity model now.

Cons:

- Broader backend touch surface than a JSON approach.
- Requires sync rules between the child table and `contacts.email`.

### 3. Build a generic `contact_identities` table

Create one table for all identifiers (`email`, `phone_number`, social handles, future identifiers) and route contact resolution through it.

Pros:

- Most extensible long-term.
- Could unify phone and email reconciliation patterns later.

Cons:

- Too much scope for the current problem.
- Forces immediate rewrites of phone logic and identifier flows that are not broken.
- Higher review and regression risk for an MVP.

## Recommendation

Choose approach 2.

It matches the actual problem size: email needs first-class normalization and uniqueness, but Chatwoot does not need a full identity-platform rewrite to ship it. Keeping `contacts.email` as the primary cache sharply lowers compatibility risk because serializers, sort logic, and Enterprise hooks can continue reading the primary email from the same column while the lookup paths move to the new table.

## Proposed Data Model

### New table: `contact_emails`

Columns:

- `id`
- `contact_id` `integer`, not null, foreign key
- `account_id` `integer`, not null, foreign key
- `email` `string`, not null
- `primary` `boolean`, not null, default `false`
- `created_at`
- `updated_at`

Indexes and constraints:

- unique index on `lower(email), account_id`
- unique partial index on `contact_id` where `primary = true`
- non-unique index on `contact_id`
- non-unique index on `account_id, primary`

Model rules:

- lowercase and trim email before validation
- validate email format with the same regexp used today
- ensure `account_id` matches `contact.account_id`
- if a contact has any email rows, it must have exactly one primary row

### Existing table: `contacts`

`contacts.email` remains in place and becomes the denormalized primary-email cache.

That preserves:

- existing JSON payload shape
- existing sort behavior on primary email
- existing Enterprise company-association hook keyed off `saved_change_to_email?`
- compatibility for public/widget clients that still send one email string

## Read Path Changes

### Contact lookup

All email-based contact resolution should use the child table instead of the single `contacts.email` column.

Affected paths:

- inbound email conversation creation
- IMAP mailbox processing
- `ContactIdentifyAction`
- `ContactInboxWithContactBuilder`
- `DataImport::ContactManager`
- any search or API helper that currently assumes one email per contact

Implementation direction:

- keep the `from_email` API at the relation/model level for compatibility
- change it to join `contact_emails` and resolve by normalized child-row email

This keeps call sites simple while moving the source of truth out of `contacts.email`.

### Inbound inbox reconciliation

For inbound email channels, email reconciliation must be account-scoped, not inbox-scoped.

Behavior:

- find the contact by account and normalized email alias
- if the matched contact already has a `ContactInbox` for the target inbox, reuse it
- if the matched contact does not yet have a `ContactInbox` for that inbox, create one and continue the conversation under the same contact

This is the piece that actually preserves "one customer across many inboxes" for email channels.

### Contact search

Contact search should match:

- `contacts.name`
- `contacts.phone_number`
- `contacts.identifier`
- primary email
- alias emails

Implementation direction:

- use a `LEFT JOIN` or `EXISTS` against `contact_emails`
- keep the result distinct at the contact level
- continue returning the contact with primary email in the top-level `email` field
- cover both account contact search and omnisearch surfaces backed by `SearchService`
- cover Enterprise email-based contact search helpers that currently filter on contact email
- for conversation search, use `EXISTS` or `DISTINCT conversations.id` so alias matches do not duplicate conversations

## Write Path Changes

### Backwards-compatible single-email writes

Existing create/update APIs that only send `email` should keep working.

Behavior:

- legacy single-email writes are primary-email operations only; they must not delete non-primary aliases
- if `email` is blank, remove the current primary row; if aliases remain, auto-promote the oldest remaining alias to primary, otherwise clear `contacts.email`
- if `email` is present and matches an existing email row on the same contact, mark it primary and sync `contacts.email`
- if `email` is present and is new for the contact, create a new primary child row, demote the previous primary row to a non-primary alias, and sync `contacts.email`
- if the email belongs to another contact in the same account, fail with the same duplicate-style validation error

This makes legacy write paths additive and non-destructive, which is the safest behavior for imports, identify flows, and older clients that do not know alias rows exist.

### Multi-email writes

Account-scoped contact create/update endpoints should accept an optional `email_addresses` array for dashboard use.

Proposed shape:

```json
{
  "email": "bob@gmail.com",
  "email_addresses": [
    { "email": "bob@gmail.com", "primary": true },
    { "email": "bo@myworkplace.com", "primary": false }
  ]
}
```

Rules:

- if `email_addresses` is non-empty, exactly one item must have `primary: true`
- `email_addresses: []` is the explicit full-state operation for clearing all stored emails and setting `contacts.email` to `nil`
- if the array is present, it becomes the full desired state for the contact's emails
- if the array is present, `email_addresses` is the authoritative input and the top-level `email` field is ignored on write
- if the array is absent, the request behaves like today's single-email write path
- the top-level `email` value remains an output/backward-compat field derived from the selected primary row
- dashboard payloads should use value rows, not child-row ids, in the first iteration:

```json
{ "email": "bob@gmail.com", "primary": true }
```

This keeps the client-side shape simple and lets the sync service treat the array as desired final state instead of an imperative patch format.

Incoming `email_addresses[].id` values are response-only and should be ignored on write in the MVP.

## Ownership of Email Sync

Add one new backend owner for email-set mutations: `Contacts::EmailAddressesSyncService`.

Responsibilities:

- normalize and validate incoming email rows
- apply full-state updates from `email_addresses`
- apply primary-only updates from legacy `email`
- persist `contact_emails`
- mirror the chosen primary value into `contacts.email`
- reject duplicate rows inside one payload after normalization, including case-only and whitespace-only variants
- perform the full mutation inside one database transaction

Rule:

- no application code outside this service should directly change `contacts.email` when the intent is to mutate contact identity

Transitional compatibility rule:

- the `Contact` model should temporarily bridge direct legacy `email` assignments into the same sync path so older builders/mailbox flows do not create contacts that only populate `contacts.email`

This gives the system a single place to enforce invariants instead of scattering cache-sync logic across controllers, actions, builders, and imports.

## Contact Merge Behavior

Manual merge should preserve emails from both contacts.

Rules:

- keep the base contact's primary email as primary
- move non-duplicate emails from the mergee contact onto the base contact
- if mergee had the same email as base, skip the duplicate child row
- if the base contact has no email rows and the mergee does, move all mergee rows and preserve the mergee primary row as the resulting primary email
- after merge, resync `contacts.email` from the base contact's primary row

This matches existing merge precedence, where the base contact wins on conflicting attributes.

## API and Serialization

### Keep

- top-level `email` in contact JSON as the primary email

### Add

- `email_addresses` in account contact JSON responses

Shape:

```json
"email_addresses": [
  { "id": 1, "email": "bob@gmail.com", "primary": true },
  { "id": 2, "email": "bo@myworkplace.com", "primary": false }
]
```

Scope:

- account contacts endpoints
- account search contacts endpoints
- widget/public endpoints can continue returning top-level `email` only for the first iteration unless there is already a reason to surface aliases there
- webhook and event payloads remain primary-email-only in the MVP

Serialization strategy:

- keep the shared contact partial primary-email-only by default
- gate `email_addresses` behind an explicit render flag such as `with_email_addresses`
- only account contact and account search endpoints should enable that flag in the MVP

## Events and Realtime

Alias-only changes must still be observable as contact updates.

MVP contract:

- alias-only edits should `touch` the parent contact so normal `contact.updated` pathways still fire
- webhook and realtime payloads can remain primary-email-only in the MVP
- the dashboard contact-details flow should rely on the save response or an explicit refetch for `email_addresses`, not on broadcast payloads alone

## Dashboard UX

MVP dashboard behavior should stay small:

- create-contact flow keeps the existing single email input
- contact details view shows the primary email plus editable alias rows
- agents can add alias emails, remove alias emails, and mark one email as primary
- contact cards and conversation sidebars continue showing only the primary email

This keeps the new UI work focused on the one place where agents actually edit contact identities.

## Migration and Rollout

### Migration

1. create `contact_emails`
2. run a pre-index audit query; if legacy-invalid or normalization-colliding contact emails are found, abort the migration with a clear operator-facing error instead of auto-merging contacts
3. backfill one primary `contact_emails` row for every contact with a non-null `contacts.email`
4. leave `contacts.email` and its existing unique index in place
5. deploy new read paths everywhere so lookup/search can resolve through `contact_emails` and fall back to `contacts.email`
6. keep alias authoring disabled during mixed-version rollout overlap
7. once all app nodes and background workers are on the new code, enable alias authoring in account contact APIs and the dashboard

This is a deliberate two-phase rollout. It avoids trying to preserve new alias semantics on older nodes that still only understand single-email contacts.

### Rollout safety

- all legacy reads of `contacts.email` still work
- all new lookups resolve through `contact_emails`
- if something goes wrong in the UI layer, backend still accepts the legacy single-email payload
- no request path should be allowed to create secondary aliases until every web node and worker is on the new code

## Enterprise Compatibility

The existing Enterprise contact concern associates a company when `contacts.email` is first set. Keeping `contacts.email` as the primary-email cache preserves this behavior without requiring an Enterprise-only override for aliases.

Expected behavior:

- alias-only changes do not trigger company association
- promoting an alias to primary updates `contacts.email` and preserves the current company-association contract

## Error Handling

- invalid email format: reject the row with the current invalid-email message
- duplicate email already used by another contact in the same account: reject with the current duplicate-email semantics
- duplicate rows inside one `email_addresses` payload after normalization, including case-only or whitespace-only variants: reject before persistence
- malformed `email_addresses` payload with zero primaries and non-empty rows: reject
- malformed `email_addresses` payload with multiple primaries: reject
- deleting the current primary when aliases remain: auto-promote the oldest remaining email row to primary
- if `email_addresses` is provided together with a conflicting top-level `email`, ignore the top-level input and derive the public `email` field from the authoritative array payload

The auto-promotion rule keeps the API simple and avoids a special "must choose replacement" flow.

## Explicit MVP Scope Cuts

- alias-email matching is required in exactly these read surfaces:
  - account contact search
  - `SearchService` contact search
  - `SearchService` conversation search
  - Enterprise Captain email-based contact search helpers
- inbound email reconciliation should match alias emails across inboxes within the same account
- account contact filters and filter-backed exports remain primary-email-only in this MVP

## Testing Strategy

### Backend

- model specs for `ContactEmail`
- request/controller specs for contact create/update payloads
- action specs for identify and merge behavior
- builder/service specs for inbox/contact creation flows
- mailbox specs for inbound email reconciliation
- search specs to ensure alias emails are searchable in account contact search, conversation search, and Enterprise email-based contact search helpers

### Frontend

- component tests for contact details alias management
- store/API tests for sending `email_addresses` on update

## Open Questions Resolved

- Primary email should still exist: yes
- Backward compatibility with single-email payloads: preserve
- Alias emails in initial scope: account dashboard editing and backend reconciliation, yes
- Multi-phone in the same PR: no

## Final Design Summary

Add a normalized `contact_emails` table, keep `contacts.email` as the primary-email cache, and route all email reconciliation through the child table. This gives Chatwoot the missing "same customer, multiple sender emails" behavior without breaking the rest of the contact model or overreaching into a generic identity rewrite.
