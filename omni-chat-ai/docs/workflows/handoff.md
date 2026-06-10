# Workflow — AI ↔ human handoff

```
customer message → Chatwoot (pending) → agent-bot webhook → AI service
                                                              │
                          ┌───────────────────────────────────┤
                          ▼                                   ▼
                 resolve/answer                       escalate (trigger)
                  (send reply)                  post handoff line + private summary
                          │                     toggle_status → open  (bot_handoff!)
                          ▼                                   │
                    stays pending                      automation routes to team/agent
                  (bot keeps control)                  human takes over (full history)
                                                              │
                                              optional: open → pending (return to bot)
```

## Escalation triggers (any one)
- model confidence below threshold
- refund / complaint intent
- negative sentiment / anger
- explicit request for a human
- order value above threshold (high-value sale)
- KB gap (no grounded answer)

## Guarantees
- The bot never replies while a conversation is `open` (human-owned).
- On escalation, no further AI loops — route straight to a human.
