---
name: human-agents
description: Human participation, assignment, and availability
keywords: [user, agent, human, assignee, capacity]
relations:
  participates_in: conversations
  communicates_through: messages
  eligible_for: inboxes
  receives: handoffs
---

# Human agents

Human agents are users who handle conversations. Assignment records
responsibility; message authorship records who actually replied.

Eligibility for an inbox, online presence, and available capacity are
separate. A handoff to humans does not establish that someone has responded.
