---
name: assistants
description: Captain assistant identity, configuration, and knowledge
keywords: [captain, ai, instructions, faq]
relations:
  implements: captain
  communicates_through: messages
  operates_in: inboxes
---

# Assistants

A [Captain](captain.md) assistant has its own name, instructions, and knowledge.
Its name need not contain “Captain”.

An assistant operates through configured [inboxes](inboxes.md).
Configuration describes where it can operate; its [messages](messages.md)
show where it actually replied.
