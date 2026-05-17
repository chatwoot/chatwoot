# Questions for the Custom-Code Agent

## Data model review

1. Are there any custom tables referencing `account_id`, `inbox_id`, `conversation_id`, or `contact_id` that this migration script must also update?
2. Are there custom reporting or analytics tables outside core Chatwoot that depend on inbox/account ownership?
3. Are there custom Redis keys tied to inbox membership, assignment, or account ownership?

## Core model overrides

1. Are there overrides/extensions under `enterprise/` or private patches for `Inbox`, `Channel::Whatsapp`, `Conversation`, `Message`, `Contact`, or `ContactInbox`?
2. Do any custom callbacks fire on inbox/channel/account changes that could cause side effects during execute?
3. Does any custom code assume `conversation_participants`, `mentions`, or `notifications` must be preserved?

## WhatsApp-specific behavior

1. Is inbound WhatsApp routing still based only on phone number / channel lookup, or is there custom account-based routing?
2. Are there any custom webhook processors, middleware, or jobs tied to WhatsApp inbox ownership?
3. Are there custom WhatsApp provider integrations or coexistence features that make moving the existing channel risky?

## Integrations and automation

1. Are there custom inbox-level integrations, hooks, bots, or automations not covered by core Chatwoot models?
2. Are there custom campaign, SLA, or assignment extensions that make current blockers incomplete?
3. Are there custom labels/notes/contact enrichment workflows that would require preserving more metadata than v1 currently does?

## Execution safety

1. Is there any custom code reason to avoid running this inside a production web pod?
2. Is there any private code that expects workers to be running while this migration executes?
3. Based on the installed customizations, is the current v1 script safe enough for a dry-run, or does it require extension first?
