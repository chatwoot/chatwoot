---
name: handoffs
description: Explicit Captain transfers versus observed human takeovers
keywords: [captain, escalation, transfer, human, takeover]
relations:
  transfers_from: captain
  transfers_to: human-agents
  occurs_in: conversations
  contextualized_by: messages
---

# Handoffs

An explicit handoff records [Captain](captain.md) transferring responsibility.
A human replying afterward is a separate event. Assignment alone proves neither.

Recorded handoff times and reasons are stronger evidence than transfer wording
in a [message](messages.md). Missing tracking is not proof no handoff happened.

The surrounding [conversation](conversations.md) explains why. “Billing” is
a topic; “needed a human to approve an adjustment” is a handoff reason.
