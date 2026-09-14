---
name: inboxes
description: Communication channels, assistant configuration, and agent eligibility
keywords: [channel, captain, assistant, assignment, capacity]
relations:
  contains: conversations
  configured_with: assistants
  staffed_by: human-agents
---

# Inboxes

An inbox is a communication channel containing [conversations](conversations.md).
It can have a configured [Captain assistant](assistants.md) and eligible human agents.

Inboxes have channel-specific configuration, working hours, a timezone, and
assignment settings. Agent membership determines who can be assigned work
in the inbox.
