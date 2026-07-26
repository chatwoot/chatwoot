# Business rules vs premium required attributes / SLA

## Source of truth

| Concern | Mechanism |
|---------|-----------|
| Block resolve / status change unless fields filled | **`settings.business_rules`** via `Conversations::BusinessRulesGuard` |
| Simple “required on resolve” UI (Conversation Workflow) | Shortcut that writes the same rule type `require_attributes_on_status` + keeps legacy `conversation_required_attributes` in sync for one release |
| SLA timers / policies | **Feature `sla`** — independent; does not replace business rules |

## Legacy list

`settings.conversation_required_attributes` is still enforced on resolve by the guard (compat). Prefer configuring via Business Rules or the Workflow shortcut (which syncs both).

## Migrate existing accounts

```bash
bundle exec rails business_rules:migrate_required_attributes DRY_RUN=1
bundle exec rails business_rules:migrate_required_attributes
```

Idempotent: creates `legacy_require_on_resolve` only when keys exist and no equivalent enabled rule is present.

## SLA

Enable the `sla` feature flag in Super Admin when you want response-time policies. Smoke separately from resolve guards.
