# WhatsApp identity contract

Chatwoot exposes a typed `whatsapp_identity` alongside the existing `source_id` wherever a response is already scoped to an exact WhatsApp `ContactInbox`. `source_id` is not deprecated or rewritten, so existing integrations can continue using it unchanged.

The identity contains `type` (`phone_number`, `bsuid`, or `parent_bsuid`), `value`, `provider`, and `inbox_id`. Meta Cloud values remain unprefixed. Twilio values retain their provider-shaped `whatsapp:` prefix so they can round-trip without guessing or normalization.

Conversation responses and outgoing webhooks also expose `whatsapp_username` when the provider supplied one. These fields are additive and are omitted or returned as `null` for non-WhatsApp and unsupported providers.

## Scope and permissions

The typed identity never expands the existing response scope: it describes the same `source_id` already attached to the authorized contact inbox, conversation, or message. Cross-inbox aliases are intentionally not emitted. A merged contact may own identifiers from unrelated WhatsApp inboxes or business portfolios, and contact ownership alone is not permission to expose those aliases together.

Contact exports and generic contact webhooks therefore remain unchanged until their cross-inbox permission, masking, retention, and deletion behavior is agreed. The stable Chatwoot contact `id` remains the recommended downstream join key; phone number is not guaranteed for BSUID-only contacts.

## Sending

Provider-aware send paths continue to use the selected conversation or contact inbox. Meta Cloud sends BSUID destinations using the `recipient` contract, while Twilio uses its `whatsapp:<BSUID>` destination. Authentication templates cannot be sent to BSUID recipients.
