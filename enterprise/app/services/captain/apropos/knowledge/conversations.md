---
name: conversations
description: Customer interactions, participants, and current assignment
keywords: [contact, messages, assignee, history]
relations:
  belongs_to: inboxes
  contains: messages
  handled_by: [assistants, human-agents]
  may_include: handoffs
---

# Conversations

A conversation connects a contact to an [inbox](inboxes.md) and contains
[messages](messages.md). A contact can have multiple conversations.

Current status and assignment describe the present, not the full history.
The current assignee need not have written earlier replies.

[Captain participation](captain.md), a [handoff](handoffs.md), and a human
reply can occur at different times within the same conversation.
