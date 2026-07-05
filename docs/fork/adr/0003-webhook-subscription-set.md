# ADR-0003: Webhook subscription set — `message_created` + `conversation_status_changed`

**Status:** Accepted (2026-07-04)
**Fixes:** a subscription bug in the meta-saas integration guide (endpoint #16),
which subscribed to a non-existent webhook event.

## Context

The platform needs to know two things from Chatwoot: (a) a new customer message
arrived (to run the AI), and (b) a conversation was resolved (to resume AI after a
human handoff). The meta-saas guide subscribed its account webhook to:

```
["message_created", "conversation_resolved", "conversation_status_changed"]
```

`conversation_resolved` is **not a webhook event** in this Chatwoot build. The
allowed set is fixed in `app/models/webhook.rb`:

```ruby
ALLOWED_WEBHOOK_EVENTS = %w[
  conversation_status_changed conversation_updated conversation_created
  contact_created contact_updated message_created message_updated
  webwidget_triggered inbox_created inbox_updated
  conversation_typing_on conversation_typing_off
]
```

`conversation_resolved` exists only as an internal **reporting** event
(`ReportingEventListener`), never delivered over a webhook. Because
`validate_webhook_subscriptions` rejects any subscription outside
`ALLOWED_WEBHOOK_EVENTS`, sending that array returns **HTTP 422 and the webhook is
never created** — silently breaking the entire AI loop for that tenant.

## Decision

**Account webhooks subscribe to exactly `["message_created",
"conversation_status_changed"]`.** Resolution is detected from the
`conversation_status_changed` payload where `status == "resolved"`, not from a
dedicated event.

- `message_created` → run the AI (filter to `message_type == "incoming"`).
- `conversation_status_changed` with `status == "resolved"` → resume AI for that
  conversation. Other status transitions (`open`, `pending`, `snoozed`) are read
  as needed for the handoff-eligibility rule.

The meta-saas adapter (`chatwoot-api.adapter.ts`) drops `conversation_resolved`
from its subscription list. Its ingest logic already handles the resolved case
from `conversation_status_changed` (its own §4.2), so no runtime logic changes —
only the subscription array.

## Consequences

- Webhook creation succeeds; the AI loop provisions correctly.
- The event-name contract stays frozen — no new webhook event is added to
  `ALLOWED_WEBHOOK_EVENTS` (that would be a non-additive change to a public
  contract, and unnecessary).
- Ingest must treat `conversation_status_changed` as multi-purpose and branch on
  the `status` field, not assume a resolved-only event.
</content>
