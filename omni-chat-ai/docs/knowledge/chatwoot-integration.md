# Chatwoot integration — agent-bot & handoff

## Agent-bot webhook
1. Create an Agent Bot (Settings → Integrations → Bots) with `outgoing_url` = our service
   `/webhooks/chatwoot`. Chatwoot generates an HMAC secret → set `CHATWOOT_HMAC_SECRET`.
2. Connect the bot to inboxes → new conversations start `pending` (bot triages first).
3. Chatwoot POSTs events: `message_created`, `message_updated`, `conversation_opened`,
   `conversation_resolved`, `webwidget_triggered`. We act on inbound `message_created` only.
4. Note: on the agent-bot path, `conversation_status_changed` is not delivered — design around it.

## Replying & handoff (REST)
- Reply: `POST /api/v1/accounts/{acct}/conversations/{id}/messages`
  `{ content, message_type: "outgoing", private: false }`.
- Private note (manager context): same call with `private: true`.
- Handoff: `POST .../conversations/{id}/toggle_status { status: "open" }` → triggers `bot_handoff!`.
- Return to bot: set status back to `pending`.

## Routing on handoff
Use **Automation Rules** (event = conversation updated/created; conditions = inbox/labels/priority;
actions = assign team/agent, set priority, add labels, send message). The human sees the full
thread because the bot's replies are normal messages.

## Manager modes
- **Copilot:** draft only (post as suggestion/private), human approves & sends.
- **Autopilot:** AI replies directly; escalates on triggers.
