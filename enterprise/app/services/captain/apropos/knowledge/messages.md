---
name: messages
description: Authorship, direction, visibility, and conversation chronology
keywords: [sender, human, captain, reply, private, note]
relations:
  belongs_to: conversations
  authored_by: [assistants, human-agents]
  provides_context_for: handoffs
---

# Messages

Messages belong to [conversations](conversations.md). Authorship, direction,
and visibility are separate: both humans and [Captain](captain.md) send
outgoing messages; private notes are not customer-facing replies.

Sender identity distinguishes contacts, human users, and assistants. An
outgoing message alone does not prove a human replied. Automation and
campaign messages also need to be distinguished from human activity.

Read events in order when investigating a [handoff](handoffs.md).
The first human reply in a conversation may precede Captain's involvement.
