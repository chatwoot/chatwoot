### Conversation Workflows: Required Attributes on Resolve

Admins can configure which custom conversation attributes must be filled before an agent can resolve a conversation.


#### How it works (current build)

- Admin picks one or more conversation-level custom attributes under Settings → Conversation Workflows.
- Selected attributes are stored on the account (settings.conversation_required_attributes).
- On resolve:
  - If all required attributes already have values on the conversation, it resolves immediately.
  - If any are missing, a modal opens listing only the missing attributes (supports text, number, link, date, list, and checkbox types). The resolve CTA is enabled only when all shown fields are filled.
  - On submit, conversation custom attributes are updated and the conversation is resolved.
- Bulk resolve:
  - Conversations that already have all required values resolve.
  - Conversations missing required values are skipped; a toast explains they need required attributes before resolution.
- UI bits:
  - Required attributes dropdown hides already-added items.
  - Resolve modal inputs use shared components (Input, ComboBox, ChoiceToggle) and auto-save the entered values before resolving.
  - List-type inputs handle options from the attribute definition; checkbox renders a yes/no toggle.
  - Required attribute cards show type/key and per-item badges (Pre-chat/Resolution) in Custom Attributes settings.


#### Admin Flow

- Navigate to Settings → Conversation Workflows.
- Under Required attributes on resolve, click Add Attributes.
- Pick from the dropdown of conversation attributes (already-added attributes are hidden).
- Save changes (updates account settings).
- Agents are prompted as described above when resolving or bulk resolving.
