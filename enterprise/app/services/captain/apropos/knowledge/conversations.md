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

A conversation has a current status, priority, labels, and optional team and
individual assignments. It can include customer messages, assistant and human
replies, private notes, and system activity.
