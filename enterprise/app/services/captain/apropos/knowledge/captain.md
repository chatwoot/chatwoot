---
name: captain
description: Chatwoot's AI assistant system
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

Captain is Chatwoot's AI assistant system. An account can configure multiple
assistants with their own names, instructions, and knowledge.

Assistants operate in inboxes, exchange messages within conversations, and
can hand conversations over to human agents.
