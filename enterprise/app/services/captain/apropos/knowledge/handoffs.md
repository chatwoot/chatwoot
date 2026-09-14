---
name: handoffs
description: Transfer of a conversation from Captain to human support
keywords: [captain, escalation, transfer, human, takeover]
relations:
  transfers_from: captain
  transfers_to: human-agents
  occurs_in: conversations
  contextualized_by: messages
---

# Handoffs

A handoff transfers a conversation from Captain to human support. Captain can
record a reason and a handoff time. Assignment and subsequent human messages
are separate events in the conversation's lifecycle.
