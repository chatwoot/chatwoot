# Uno group conversations architecture

## Context

Today ViperChat already accepts WhatsApp group messages coming from Uno API, but the
current implementation adapts groups into the existing one-to-one conversation
model.

The current behavior is:

- Uno sends a WhatsApp Cloud-like webhook payload.
- A group message is detected when `contacts[0].group_id` is present.
- The group itself is stored as the conversation contact/contact inbox.
- The real participant is stored as the message sender when available.
- Incoming text content is prefixed with the participant name, for example
  `*Maria*: hello`, so the old UI can show who sent the group message.

This works, but it makes a group look like a fake contact and prevents the new
Chatwoot group conversation UI from showing structured members, group title,
participant count, and sender labels.

The goal is to keep the existing behavior as a fallback while introducing a new
group conversation schema that can be enabled per Uno inbox.

## Uno API 3.0.61 capabilities

The local Uno API project at `../unoapi-cloud` is version `3.0.61` and includes
cached group endpoints.

Routes:

```http
GET /v15.0/{phone}/groups
GET /v15.0/{phone}/groups/{groupId}/participants
```

The endpoints are registered in `src/router.ts`:

```ts
router.get('/:version/:phone/groups', middleware, groupsController.list.bind(groupsController))
router.get('/:version/:phone/groups/:groupId/participants', middleware, groupsController.participants.bind(groupsController))
```

`GET /v15.0/{phone}/groups` returns cached groups for the session:

```json
{
  "phone": "5549988290955",
  "groups": [
    {
      "jid": "120363040468224422@g.us",
      "subject": "Equipe",
      "participantsCount": 12
    }
  ]
}
```

`GET /v15.0/{phone}/groups/{groupId}/participants` returns participants from the
group cache:

```json
{
  "phone": "5549988290955",
  "group": {
    "jid": "120363040468224422@g.us",
    "subject": "Equipe"
  },
  "participants": [
    { "jid": "5566996269251", "name": "Fulano" },
    { "jid": "123456789012345@lid", "name": "Ciclano" }
  ]
}
```

Important endpoint behavior:

- `groupId` accepts both `1203...` and `1203...@g.us`.
- PN participants are returned as digits only, without `@s.whatsapp.net`.
- LID participants are returned with `@lid`.
- `name` is resolved from Uno contact cache with PN/LID fallback mapping.
- If a group is not cached in Redis, Uno returns `404`.

These endpoints are not official Meta Graph endpoints. They are Uno/Baileys
cache endpoints exposed through the Uno API service.

## Alignment with official Meta documentation

The architecture should not treat groups as a Uno-only extension. The internal
Chatwoot model and Uno endpoints should stay as close as possible to the
official WhatsApp Business Platform group contract.

Expected official/compatible contract:

- Sending a group message uses the message send endpoint, but with
  `recipient_type: "group"` instead of `recipient_type: "individual"`.
- The `to` field should receive the `GROUP_ID`.
- Incoming group message webhooks include `messages[].group_id`.
- The `messages[].from` field represents the participant who sent the message.
- Group message status webhooks include `recipient_id` with the group id and
  `recipient_type: "group"`.
- Group status events can be aggregated to reduce webhook fan-out.

This means the Chatwoot model should use neutral names that are compatible with
the official concept:

- `group_source_id` should store the external `GROUP_ID`.
- `group_title` should store the group subject/name when available.
- `messages.sender` should represent the real participant.
- `conversation.group?` should drive rendering and outbound routing without
  depending on the group being disguised as a contact.

For Uno, the recommendation is to expose/accept a Meta-compatible layer even if
the internal implementation still uses Baileys:

- accept outbound payloads with `recipient_type: "group"` and `to: "<GROUP_ID>"`;
- emit inbound webhooks with `messages[].group_id`;
- emit statuses with `recipient_type: "group"` and `recipient_id: "<GROUP_ID>"`;
- keep extra cache endpoints, such as `/groups` and
  `/groups/{groupId}/participants`, as complementary member-hydration resources,
  not as the primary messaging contract.

This prepares Chatwoot for two scenarios:

- Uno/Baileys using a Meta-compatible contract;
- a future switch to an official/BSP API that implements groups without another
  database and UI redesign.

## Official group management actions

The group management documentation covers more than sending and receiving
messages. The architecture should leave room for these capabilities even if they
are not all implemented in the first rollout.

Relevant official actions:

- Create group:
  - `POST /groups`
  - main fields: `subject`, `description`, `join_approval_mode`;
  - the platform generates an `invite_link` when the group is created;
  - the business phone number used to create the group is added as creator and
    admin.
- Create group invite template:
  - template with `library_template_name: "group_invite_link"`;
  - used to invite users to the group through an approved message.
- Join requests:
  - `GET /groups/{group_id}/join_requests`;
  - `POST /groups/{group_id}/join_requests` to approve;
  - `DELETE /groups/{group_id}/join_requests` to reject;
  - `join_approval_mode` can be `approval_required` or `auto_approve`.
- Invite link:
  - `GET /groups/{group_id}/invite_link`;
  - `POST /groups/{group_id}/invite_link` to reset the link.
- Remove participants:
  - `DELETE /groups/{group_id}/participants`;
  - payload with `participants`;
  - documented limit of up to 8 participants per call;
  - a removed participant cannot rejoin through the old invite link.
- Get group info:
  - `GET /groups/{group_id}?fields=...`;
  - documented fields include `subject`, `description`, `participants`,
    `join_approval_mode`, `suspended`, `creation_timestamp`, and
    `total_participant_count`.
- List active groups:
  - `GET /groups`;
  - pagination through `limit`, `before`, and `after`.
- Update group settings:
  - `POST /groups/{group_id}`;
  - updates `subject`, `description`, and group photo;
  - photo follows media upload rules, with JPEG, max 5MB, square image, and
    minimum 192x192 size.
- Delete group:
  - `DELETE /groups/{group_id}`;
  - removes all participants, including the business.

Official/compatible webhooks that should be reflected in the model:

- `group_lifecycle_update`: creation, deletion, and lifecycle failures.
- `group_participants_update`: join, approval/removal, and participant changes.
- `group_settings_update`: subject, description, or photo changes.

Important notes:

- The official contract emphasizes invite and join approval flows, not free
  manual participant addition.
- Admin/creator information is clear for the business number that creates the
  group, but the documented participant list returns `wa_id`; per-participant
  admin role should not be assumed as an official field without validating the
  real provider response.
- If Uno/Baileys exposes extra admin/role fields, they can be stored as optional
  metadata, but Chatwoot core should remain aligned with the official contract.

## Target Chatwoot model

The target model should follow the new Chatwoot group conversation idea:

- `conversations.group`: marks the conversation as a group.
- `conversations.group_source_id`: stores the external group JID, for example
  `120363040468224422@g.us`.
- `conversations.group_title`: stores the group subject.
- `group_contacts`: stores additional contacts that participate in the group.
- `messages.sender`: points to the real contact that sent the message.

Future optional fields if official management actions are implemented:

- `group_description`
- `group_invite_link`
- `group_join_approval_mode`
- `group_suspended`
- `group_created_at_external`
- `group_participants_count`
- optional per-member metadata, such as `role`/`is_admin`, only if the provider
  returns it reliably.

For compatibility, the first implementation should keep the old group fake
contact as `conversation.contact` instead of immediately allowing nil
`contact_id`/`contact_inbox_id`. This reduces risk because existing Chatwoot
code still assumes those relations are present in many places.

## Rollout flag

Add a provider config flag for Uno inboxes:

```json
{
  "use_group_conversation_schema": true
}
```

Behavior:

- `false` or missing: keep the current legacy group behavior.
- `true`: use the structured group conversation behavior for new incoming group
  messages.

The checkbox can live in the Uno inbox configuration UI and be persisted in
`channel_whatsapp.provider_config`.

Suggested label:

```text
Usar novo modelo de conversas em grupo
```

Suggested help text:

```text
Armazena grupos como conversas estruturadas, com membros e remetente real. Use
somente com Uno API 3.0.61 ou superior.
```

## Inbound architecture

### Legacy mode

Keep the existing flow:

- `contacts[0].group_id` becomes the group contact inbox source id.
- `contacts[0].group_subject` becomes the fake contact name.
- `contacts[0].group_picture` becomes the fake contact avatar.
- Message text is prefixed with `*sender name*:` for incoming group messages.

### Structured mode

When `use_group_conversation_schema` is enabled and `contacts[0].group_id` is
present:

1. Sync the real participant contact from `contacts[0].wa_id`.
2. Keep the real participant as `@contact` and `@sender`.
3. Find or create the group conversation by `inbox_id + group_source_id`.
4. Set group metadata:
   - `group: true`
   - `group_source_id: contacts[0].group_id`
   - `group_title: contacts[0].group_subject || contacts[0].group_id`
5. Keep the legacy group contact/contact inbox as the primary conversation
   contact for compatibility.
6. Create or update `group_contacts` for the sender contact.
7. Create the message with `sender: @sender`.
8. Do not prefix message content with `*sender name*:` in structured mode.

The new UI can then render sender names from `message.sender` and group metadata
from the conversation JSON.

## Uno group member hydration

The webhook gives the current sender, but it does not necessarily include all
group members. Uno 3.0.61 can fill that gap through the participants endpoint.

Suggested service:

```ruby
Whatsapp::Unoapi::GroupParticipantsSyncService
```

Inputs:

- `inbox`
- `group_source_id`
- `group_title`, optional

Responsibilities:

1. Build Uno base URL from `channel.provider_config['url']`.
2. Use the inbox phone number as `{phone}`.
3. Call:

```http
GET /v15.0/{phone}/groups/{group_source_id}/participants
```

4. For each participant:
   - if `jid` is digits, map it to a normal WhatsApp contact phone/source id;
   - if `jid` ends with `@lid`, store it as an email/source-id style identity,
     matching the current LID handling;
   - use `name` when present;
   - create/update `Contact` and `ContactInbox`;
   - create `GroupContact`.
5. If Uno returns `404`, keep the group conversation and only sync the sender
   from the current webhook.

Recommended triggers:

- On first message for a new group conversation.
- Periodic background refresh for active group conversations.
- Manual admin action later, if needed.

Avoid calling Uno participants endpoint on every message. For large groups this
can add unnecessary load.

Suggested freshness policy:

- Store `group_contacts_synced_at` later, or use a lightweight cache key.
- Refresh when no sync has happened or when the last sync is older than a
  configurable interval, for example 24 hours.

## Outbound architecture

Current sending logic can rely on `conversation.contact_inbox.source_id` for the
recipient. In structured mode this must not be the only source of truth.

For group conversations:

- destination should be `conversation.group_source_id`;
- payload `to` should be the group JID when using Uno Cloud-compatible send;
- status/update payloads should use `group_source_id` for `group_id`.

This avoids coupling outbound delivery to the legacy fake group contact.

## Historical migration

Old group conversations can be migrated because the old implementation used the
group JID as `contact_inbox.source_id`.

Detection candidates:

```ruby
Conversation
  .joins(:contact_inbox)
  .where("contact_inboxes.source_id LIKE ?", "%@g.us")
```

Backfill steps:

1. Mark conversation as `group: true`.
2. Set `group_source_id` from `conversation.contact_inbox.source_id`.
3. Set `group_title` from `conversation.contact.name`.
4. Create `group_contacts` from distinct `messages.sender` contacts.
5. Optionally call Uno participants endpoint to enrich the full member list.
6. Keep the existing `contact_id` and `contact_inbox_id` for compatibility.
7. Do not rewrite old message content in the first migration.

Old messages may still contain `*Name*:` prefixes. That is acceptable during the
first rollout. A later cleanup can normalize historical content if the UI needs
it.

## Database changes

Minimum required schema:

```ruby
add_column :conversations, :group, :boolean, default: false, null: false
add_column :conversations, :group_source_id, :string
add_column :conversations, :group_title, :string
add_index :conversations, :group
add_index :conversations, [:inbox_id, :group_source_id],
          unique: true,
          where: "group_source_id IS NOT NULL"
```

New table:

```ruby
create_table :group_contacts do |t|
  t.references :account, null: false, foreign_key: true
  t.references :conversation, null: false, foreign_key: true
  t.references :contact, null: false, foreign_key: true
  t.timestamps
end

add_index :group_contacts, [:conversation_id, :contact_id], unique: true
```

Implementation note:

- Do not edit old migrations.
- Add new migrations using the current fork timestamp.
- Keep `contact_id` and `contact_inbox_id` required in the initial rollout unless
  we have audited all nil-sensitive call sites.

## Frontend/API shape

Conversation responses should include:

```json
{
  "group": true,
  "group_title": "Equipe",
  "group_source_id": "120363040468224422@g.us",
  "group_contacts": [
    {
      "id": 1,
      "contact_id": 10,
      "contact": {
        "id": 10,
        "name": "Fulano",
        "thumbnail": "..."
      }
    }
  ]
}
```

For performance, avoid embedding all members for large groups in every
conversation list response. Prefer:

- `group_contacts_count` in list/detail payloads;
- first few members for sidebar preview;
- paginated `/group_contacts` endpoint for the full member list.

## Implementation phases

## Responsibility matrix

This matrix separates what Uno must provide, what Chatwoot must implement, and
which points should stay Meta-like so a future WhatsApp Cloud/BSP channel can use
the same UI and data model.

### Uno API

Uno should expose an API/webhook layer compatible with Meta semantics even if it
uses Baileys internally.

Required for the new UI to work well:

- Emit Meta-like inbound group webhooks:
  - `object: "whatsapp_business_account"`;
  - `entry[].changes[].field: "messages"`;
  - `value.metadata.display_phone_number`;
  - `value.metadata.phone_number_id`;
  - `value.contacts[0].wa_id` with the real participant;
  - `value.contacts[0].profile.name`;
  - `value.contacts[0].profile.picture`, when available;
  - `value.messages[0].from` with the real participant;
  - `value.messages[0].group_id` with the external group id;
  - `value.messages[0].id`;
  - `value.messages[0].timestamp`;
  - `value.messages[0].type`;
  - type-specific content, such as `text.body`.
- Emit group metadata in the webhook when available:
  - `group_subject` or equivalent field mappable to `group_title`;
  - `group_picture`, when available;
  - keep `group_id` as a stable group identifier.
- Accept Meta-like outbound group sends:
  - `POST /v15.0/{phone}/messages`;
  - `recipient_type: "group"`;
  - `to: "<GROUP_ID>"`;
  - `type` and body following supported message formats.
- Emit Meta-like outbound statuses for groups:
  - `statuses[].recipient_id: "<GROUP_ID>"`;
  - `statuses[].recipient_type: "group"`;
  - `statuses[].id`;
  - `statuses[].status`;
  - `statuses[].timestamp`;
  - `statuses[].errors`, when failed.
- Keep group cache/hydration endpoints:
  - `GET /v15.0/{phone}/groups`;
  - `GET /v15.0/{phone}/groups/{groupId}/participants`;
  - `groupId` accepted with or without `@g.us`;
  - participant response with `jid` and `name`;
  - `404` when the group is not cached.

Recommended for official management compatibility:

- `GET /groups` to list active groups in a Meta-like shape, with pagination.
- `GET /groups/{group_id}?fields=...` returning:
  - `id`;
  - `subject`;
  - `description`;
  - `participants`;
  - `total_participant_count`;
  - `join_approval_mode`;
  - `suspended`;
  - `creation_timestamp`.
- `GET /groups/{group_id}/invite_link`.
- `POST /groups/{group_id}/invite_link` to reset link.
- `DELETE /groups/{group_id}/participants` to remove members.
- `POST /groups/{group_id}` to update subject, description, and photo.
- Meta-like webhooks:
  - `group_lifecycle_update`;
  - `group_participants_update`;
  - `group_settings_update`.

Optional/future:

- `POST /groups` to create groups. This action is intentionally disabled in
  the Chatwoot/ViperChat UI until the Baileys/WhatsApp platform support is
  stable; current UnoAPI tests can return `rate-overlimit` even after
  participant normalization and LID-to-phone-JID fallback.
- `GET/POST/DELETE /groups/{group_id}/join_requests`.
- `group_invite_link` template.
- Baileys extra fields such as `is_admin`, `role`, `lid`, `pn`, as long as they
  are optional metadata and do not replace the primary contract.

### Chatwoot backend

Chatwoot should transform the Meta-like contract into an internal group model
without depending on Uno-only details.

Required for the new UI:

- Create new migrations:
  - `conversations.group`;
  - `conversations.group_source_id`;
  - `conversations.group_title`;
  - `group_contacts` table;
  - unique index on `inbox_id + group_source_id`;
  - unique index on `conversation_id + contact_id`.
- Create models/associations:
  - `Conversation#group?`;
  - `Conversation#group_contacts`;
  - `Conversation#additional_contacts`;
  - `GroupContact`;
  - same-account validation;
  - duplicate member prevention.
- Add inbox-level flag:
  - `channel.provider_config['use_group_conversation_schema']`.
- Adapt WhatsApp/Uno inbound:
  - detect `messages[0].group_id`;
  - create/find conversation by `inbox_id + group_source_id`;
  - fill `group`, `group_source_id`, `group_title`;
  - keep legacy fake group contact as primary contact initially;
  - store the real participant as `message.sender`;
  - create/update `group_contacts` for the sender;
  - stop prefixing `*Name*:` into new structured group messages.
- Create member hydration service/job:
  - call Uno `GET /v15.0/{phone}/groups/{groupId}/participants`;
  - create/update `Contact`, `ContactInbox`, and `GroupContact`;
  - treat `404` as cache miss;
  - avoid calling on every message;
  - control freshness via cache or future field.
- Adapt outbound:
  - if `conversation.group?`, send to `conversation.group_source_id`;
  - use `recipient_type: "group"`;
  - keep legacy send path when the flag is disabled.
- Adapt inbound statuses:
  - accept `recipient_type: "group"`;
  - find conversation by `group_source_id`;
  - update message by `source_id`;
  - handle aggregated statuses without duplication.
- Expose API/JSON to frontend:
  - `group`;
  - `group_title`;
  - `group_source_id`;
  - `group_contacts_count`;
  - preview of a few members;
  - paginated members endpoint.

Recommended for future compatibility:

- Create a provider-independent normalization layer:
  - for example, `Whatsapp::GroupPayloadNormalizer`;
  - input from Uno, official WhatsApp Cloud, or BSP;
  - standardized internal output for conversation/message/group.
- Avoid Uno-specific database field names.
- Do not edit old migrations.
- Keep `contact_id` and `contact_inbox_id` required in the first rollout.
- Create extension points for providers that support official group management.

Optional/future:

- Internal API for:
  - listing participants;
  - updating subject/description/photo;
  - removing participant;
  - getting/resetting invite link;
  - approving/rejecting join requests;
  - manually syncing group.
- Store extra fields:
  - `group_description`;
  - `group_invite_link`;
  - `group_join_approval_mode`;
  - `group_suspended`;
  - `group_created_at_external`;
  - per-member metadata.

### Chatwoot frontend

Required for the new UI:

- Use `conversation.group === true` to switch from one-to-one conversation UI to
  group UI.
- Show `group_title` in card and header.
- Show group icon/avatar.
- Show `group_contacts_count`.
- Show message sender name using `message.sender`, without depending on text
  prefix.
- Create/use group panel:
  - first members preview;
  - paginated list;
  - local or remote search;
  - legacy primary contact indicator only if needed.
- Add `en` and `pt_BR` translations in the same commit.

Recommended:

- Do not load all members in conversation list.
- Use paginated endpoint for modal/full list.
- Show cache states:
  - loading members;
  - members unavailable;
  - recent/pending sync, if exposed by backend.

Optional/future:

- Management UI:
  - update title/description/photo;
  - copy/reset invite link;
  - remove participant;
  - approve/reject requests;
  - manually sync participants.

### Migration and rollout

Required:

- Migration/backfill for old conversations whose `contact_inbox.source_id` ends
  with `@g.us`.
- Fill:
  - `group: true`;
  - `group_source_id`;
  - `group_title`;
  - `group_contacts` from `messages.sender`.
- Do not rewrite old content in the first rollout.
- Enable the new mode by flag, inbox by inbox.
- Keep legacy fallback.

Recommended:

- Optional job to enrich history with participants from Uno.
- Specific logs for:
  - structured group created;
  - participant synced;
  - Uno cache miss;
  - group status received;
  - fallback to legacy mode.

### Future compatibility minimum contract

For Chatwoot to use Uno today and WhatsApp Cloud/BSP official channels in the
future, this is the minimum contract any provider should deliver:

Inbound:

```json
{
  "messages": [
    {
      "id": "wamid...",
      "from": "556699999999",
      "group_id": "120363040468224422@g.us",
      "timestamp": "1710000000",
      "type": "text",
      "text": { "body": "Message" }
    }
  ],
  "contacts": [
    {
      "wa_id": "556699999999",
      "profile": {
        "name": "Maria",
        "picture": "https://..."
      }
    }
  ],
  "metadata": {
    "display_phone_number": "556600000000",
    "phone_number_id": "123"
  }
}
```

Outbound:

```json
{
  "messaging_product": "whatsapp",
  "recipient_type": "group",
  "to": "120363040468224422@g.us",
  "type": "text",
  "text": {
    "body": "Message"
  }
}
```

Status:

```json
{
  "statuses": [
    {
      "id": "wamid...",
      "recipient_id": "120363040468224422@g.us",
      "recipient_type": "group",
      "status": "delivered",
      "timestamp": "1710000000"
    }
  ]
}
```

### Phase 1 - Data model and compatibility

- Add `group` fields to conversations.
- Add `group_contacts`.
- Add model validations.
- Add conversation JSON fields with count/preview, not full member dump.
- Add provider config flag for Uno.

### Phase 2 - Uno inbound structured mode

- Add branching in WhatsApp/Uno incoming service.
- In structured mode, create/find conversation by group id.
- Store sender as real contact.
- Stop prefixing sender name into new structured group messages.
- Sync current sender into `group_contacts`.

### Phase 3 - Uno participants sync

- Add Uno client method for `GET /groups/{groupId}/participants`.
- Add background job/service to hydrate members.
- Run on first group message and periodic refresh.
- Handle `404` as cache miss, not as hard failure.

### Phase 4 - Outbound group send

- Send to `conversation.group_source_id` when `conversation.group?`.
- Keep legacy send path when flag is disabled.
- Verify text, attachment, reaction/status update paths.

### Phase 5 - Historical migration

- Backfill old `@g.us` conversations into structured group metadata.
- Create `group_contacts` from historical message senders.
- Optionally enrich from Uno participants endpoint.
- Keep legacy fake group contact for compatibility.

### Phase 6 - UI integration

- Show group title/icon/count in conversation list and header.
- Show structured sender name in message bubbles.
- Add group info panel with paginated participants.
- Add `pt_BR` translations together with `en`.

## Risks and mitigations

- **Nil contact/contact inbox regressions**: keep legacy primary contact in the
  initial rollout.
- **Large group payloads**: avoid embedding all participants in every
  conversation response.
- **Uno cache miss**: treat `404` from participants endpoint as a soft miss.
- **LID/PN identity drift**: preserve Uno's returned `jid`; normalize PN digits
  but keep LID when no PN mapping exists.
- **Duplicate members**: enforce unique index on
  `group_contacts(conversation_id, contact_id)`.
- **Old messages with name prefix**: keep them unchanged during initial
  migration.
- **Translation warnings**: add `pt_BR` keys in the same commit as UI keys.

## Open decisions

- Should `group_contacts` include the primary legacy fake group contact? Proposed
  answer: no, only real participants.
- Should historical messages be cleaned to remove `*Name*:` prefixes? Proposed
  answer: not in the first rollout.
- Should member sync be automatic only, or should the admin UI expose a manual
  refresh? Proposed answer: automatic first, manual later if operations need it.
- Should we introduce `group_contacts_synced_at` now? Proposed answer: only if
  the initial sync job needs a DB-level freshness marker; otherwise use a cache
  key first.
