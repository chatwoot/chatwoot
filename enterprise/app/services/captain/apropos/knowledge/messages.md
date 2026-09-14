---
name: messages
description: Authorship, direction, visibility, and conversation chronology
keywords: [sender, human, captain, reply, private, note]
relations:
  belongs_to: conversations
  delivered_through: inboxes
  authored_by: [contacts, assistants, human-agents]
---

# Messages

A message belongs to a conversation and inbox. It can contain text or
structured content, such as an input form, and has a delivery status.

Authorship, message type, and visibility are separate properties. Authors
include contacts, human users, assistants, and bots. Message types include
incoming, outgoing, activity, and template. Private messages are internal notes.

The sender type and ID together identify the author; IDs are local to each
sender type. System activity can have no sender.
