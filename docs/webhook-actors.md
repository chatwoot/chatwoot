# Conversation and message webhook actors

Conversation and message webhooks include a top-level `performed_by` value:

```json
{"performed_by": {"type": "user", "id": 42}}
```

The value is either `null` or an object containing only `type` and `id`.
Supported types are `user`, `agent_bot`, `automation_rule`, `contact`, and
`inbox`. User membership and account-owned actors are checked against the event
account. A global AgentBot is included when connected to an inbox in that
account. Unknown, out-of-account, unsaved, or absent actors produce `null`.
Names, email addresses, tokens, and other actor attributes are not included.

This applies to `conversation_created`, `conversation_updated`,
`conversation_status_changed`, `message_created`, and `message_updated` for
account and API inbox webhooks. AgentBot webhooks also include it for
`conversation_opened` and `conversation_resolved`, in addition to their existing
conversation-update and message events. Subscription and delivery rules do not
change. Older events queued before the change have a null actor.

The dispatcher captures the identity before synchronous listeners run and before
the asynchronous event is queued. An explicit internal `performed_by` actor
(such as an automation rule) takes precedence over the authenticated request
user. A supported actor is never inferred from the message sender, assignee, or
request parameters, and delivery does not read the worker's `Current.user`.
Existing internal `performed_by` event data remains unchanged.

A `user` actor identifies the authenticated user, including the owner of a user
API token. It does **not** distinguish dashboard actions from integrations using
that token, identify a macro, prove that a human accepted a handoff, or provide a
request correlation ID. Contact/inbox provenance is included only when the
originating event explicitly supplies it. System actions without actor context
remain null. Macro provenance and broader actor types are follow-up work.
