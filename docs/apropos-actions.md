# Apropos record actions and assignment context

Use `apropos` to discover operations and `describe` to read their complete contracts.
Contracts live in `ActionContracts`; they include arguments, examples, results,
requirements, side effects, and retry behavior. Discovery is concise; description
returns the full contract. Actions continue to use the common receipt wrapper.

## Added actions

| Operation | Target | Behavior |
| --- | --- | --- |
| `create-contact` | Current account ref | Create a contact from allowed profile/custom fields |
| `update-contact` | Contact ref | Update supplied profile fields; merge custom attributes |
| `create-conversation` | Inbox ref | Use an existing account contact and normal contact-inbox/conversation builders |
| `update-label` | Label ref | Edit existing label metadata; renames propagate asynchronously |
| `remove-label` | Conversation ref | Remove a label from this conversation, not from the account |
| `update-custom-attributes` | Conversation ref | Merge supplied keys, preserving other custom attributes |
| `unassign-agent` | Conversation ref | Clear human assignee, keeping team/bot fields |
| `unassign-team` | Conversation ref | Clear team without explicitly clearing human assignee |
| `snooze-conversation` | Conversation ref | Snooze until a future ISO 8601 timestamp with timezone |
| `create-contact-note` | Contact ref | Create an internal profile note attributed to the acting user |
| `update-contact-note` | Contact-note ref | Replace its content and update user attribution, matching the app |

No label creation or deletion operation is added. All record references resolve
within the current account. The `accounts` resource exposes only the current
account's ID/name, providing a scoped target for contact creation.

Creation is not generally idempotent. Conversation creation respects the inbox's
single-conversation rule and returns `created: false` when the builder returns an
existing conversation; it does not reopen it. No initial message is explicitly
sent, but normal callbacks and configured automation still apply. Follow-up
messages require the existing message action. Channel contact requirements apply.

## Assignment reads

```scheme
(assignment-context (hash "type" "inboxes" "id" 10) 0)
```

This read-only function returns policy settings and a paginated list of manually
assignable agents. `next_cursor` is the last agent ID or `#f` when exhausted.
It exposes separate values for:

- Manual eligibility from `inbox.assignable_agents`.
- Membership availability and live online inbox membership.
- Configured capacity policy, per-inbox limit, open count, and remaining slots.
- `CapacityService.agent_has_capacity?` under the assigned policy.
- `inbox.member_ids_with_assignment_capacity` under current feature/legacy rules.
- `AutoAssignment::RateLimiter.within_limit?`.

Null capacity limits/remaining slots mean unlimited under that capacity policy,
not zero. Configured policy checks do not imply that the relevant feature is
enabled. The response includes those feature flags and stored assignment policy.
Policy exclusions are returned as configuration, not silently applied to this
agent list. Automatic routing also checks teams, queue age/label exclusions,
enablement, and distribution order. No single flag promises automatic assignment.

The function neither reserves capacity nor chooses an agent. Values can change
between reading and writing. `assign-agent` remains a manual assignment operation
with its existing inbox eligibility check, not the automatic assignment engine.

## Contact history and knowledge

```scheme
(related (hash "type" "contacts" "id" 42) "conversations" 0)
(related (hash "type" "contacts" "id" 42) "notes" 0)
(faq-search "How can a customer cancel their subscription?" 7)
```

Contact conversations already include every status. Contact notes are a separate
`contact_notes` resource, not private conversation messages. Both relationships
page by ascending database ID; follow `next_cursor`. Notes can also be fetched
by ref or queried through WootQL. Creating notes is not idempotent; updates replace
the full content and set the acting user as the last editor, like the app.

`faq-search` uses Captain's approved-response vector search with at most five
matches. The optional assistant database ID restricts the search; omit it for
account-wide approved FAQs. The `assistants` resource supports discovering IDs.
The lookup returns question, answer, assistant_id, FAQ ref, and a nullable
customer-visible source URL. It is evidence retrieval, not answer generation.
Each lookup sends query text to the configured embedding provider and consumes
one shared agent-call allowance. It does not invoke a translation/chat model.
