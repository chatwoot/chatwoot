# Epic 05: Integration Models

## Overview
- **Duration**: 1 week
- **Complexity**: Medium
- **Dependencies**: Epic 03 (Account, Inbox models)
- **Team Size**: 2 engineers
- **Can Parallelize**: Yes (each integration independent)

## Scope: 10 Integration Models

1. **Integrations::Hook** - Webhook configurations
2. **Integrations::Slack** - Slack app integration
3. **Integrations::Dialogflow** - Google Dialogflow AI
4. **Integrations::Google** - Google services
5. **Integrations::Shopify** - Shopify e-commerce
6. **AgentBot** - Automated agent bots
7. **AgentBotInbox** - Bot-inbox associations (join table)
8. **WorkingHour** - Business hours configuration
9. **Webhook** - Outgoing webhooks
10. **ApplicationHook** - Application-level hooks

## Success Criteria
- ✅ All 10 models migrated with feature parity
- ✅ All associations working
- ✅ All validations ported
- ✅ Tests ≥90% coverage
- ✅ Factories created

## Key Patterns

### Integration Base Pattern
```typescript
@Entity('integrations_hooks')
export class IntegrationsHook {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  appId: string;

  @Column('jsonb')
  settings: Record<string, any>;

  @ManyToOne(() => Account)
  account: Account;

  @Column()
  status: string; // active, inactive

  // Integration-specific fields...
}
```

## Parallel Opportunities
- **Team A**: Hooks, Webhooks, ApplicationHook (5 models)
- **Team B**: Slack, Dialogflow, Google, Shopify, AgentBot, WorkingHour (5 models)

## Estimated Time
- 10 models × 3 hours = 30 hours
- Total with testing: ~40 hours (1 week for 2 engineers)

---

**Status**: 🟡 Ready (after Epic 03)
**Rails Files**: `app/models/integrations/*.rb`, `app/models/agent_bot.rb`, etc.
