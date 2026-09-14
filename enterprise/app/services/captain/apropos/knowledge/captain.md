---
name: captain
description: AI participation in conversations and transfers to humans
keywords: [ai, bot, assistant, handoff, escalation]
relations:
  implemented_by: assistants
  communicates_through: messages
  participates_in: conversations
  operates_in: inboxes
  transfers_through: handoffs
  transfers_to: human-agents
---

# Captain

Captain is the AI assistant system, not necessarily an assistant's name.
An account can have multiple [assistants](assistants.md).

[Message authorship](messages.md) establishes participation. Mentions of
“Captain” or an assistant configured for an inbox do not.

[Handoffs](handoffs.md) and human takeovers are distinct. To understand why
either happened, read the surrounding [conversation](conversations.md).
