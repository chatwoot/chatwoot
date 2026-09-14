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

Inbox eligibility, online presence, assigned workload, and policy capacity
are different facts. Spare capacity does not imply an agent is online;
being online does not imply eligibility for every inbox.
