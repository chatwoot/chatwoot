# Epic 06: Supporting Models

## Overview
- **Duration**: 1 week  
- **Complexity**: Low-Medium
- **Dependencies**: Epic 03-05 (core, channel, integration models)
- **Team Size**: 3 engineers
- **Can Parallelize**: Yes (high parallelization potential)

## Scope: 31 Supporting Models

### Messaging & Content (4 models)
1. **Attachment** - File attachments for messages
2. **Note** - Internal notes on conversations
3. **CannedResponse** - Pre-defined message templates
4. **MessageTemplate** - Message template configurations

### Automation (2 models)
5. **AutomationRule** - Workflow automation rules
6. **Macro** - Quick action sequences

### Analytics & Reporting (4 models)
7. **ReportingEvent** - Analytics event tracking
8. **ConversationSummary** - Conversation summary data
9. **CsatSurvey** - Customer satisfaction survey
10. **CsatSurveyResponse** - Survey responses

### Help Center (4 models)
11. **Portal** - Knowledge base portal
12. **Category** - Article categories
13. **Article** - Help articles
14. **Folder** - Article folders

### Custom Fields (3 models)
15. **CustomAttribute** - Custom field definitions
16. **CustomAttributeDefinition** - Attribute schema
17. **CustomFilter** - Saved filter configurations

### Labels & Tags (2 models)
18. **Label** - Tags for conversations/contacts
19. **ConversationLabel** - Join table for conversation labels

### Notifications (3 models)
20. **Notification** - User notifications
21. **NotificationSetting** - User notification preferences
22. **NotificationSubscription** - Push notification subscriptions

### Platform & API (4 models)
23. **Platform::App** - Platform applications
24. **Platform::AppKey** - API keys for apps
25. **AccessToken** - OAuth access tokens
26. **ApiKeyInbox** - API key inbox associations

### Other (5 models)
27. **Avatar** - User/contact avatars
28. **DataImport** - Data import jobs
29. **ContactInbox** - Join table for contact-inbox
30. **InstallationConfig** - Installation configuration
31. **RelatedCategory** - Category relationships (if exists)

## Success Criteria
- ✅ All 31 models migrated with feature parity
- ✅ All associations working
- ✅ All validations ported
- ✅ Tests passing (≥90% coverage)
- ✅ Factories created for each model

## Parallel Opportunities

### Team A: Messaging, Automation, Analytics (10 models)
- Attachment, Note, CannedResponse, MessageTemplate
- AutomationRule, Macro
- ReportingEvent, ConversationSummary, CsatSurvey, CsatSurveyResponse

### Team B: Help Center, Custom Fields, Labels (9 models)
- Portal, Category, Article, Folder
- CustomAttribute, CustomAttributeDefinition, CustomFilter
- Label, ConversationLabel

### Team C: Notifications, Platform, Other (12 models)
- Notification, NotificationSetting, NotificationSubscription
- Platform::App, Platform::AppKey, AccessToken, ApiKeyInbox
- Avatar, DataImport, ContactInbox, InstallationConfig, RelatedCategory

## Task Pattern (Per Model)

Average 2-3 hours per model × 31 models = ~80 hours total

**With 3 engineers**: ~27 hours each ≈ 1 week

### Steps per model:
1. Read Rails model (`app/models/[name].rb`)
2. Read Rails specs (`spec/models/[name]_spec.rb`)
3. Write TypeScript tests (TDD: Red)
4. Create TypeORM entity
5. Implement associations
6. Implement validations
7. Implement methods
8. Create factory
9. Run tests (TDD: Green)
10. Verify feature parity
11. Update progress tracker

## Common Patterns

### Simple Model Example
```typescript
@Entity('canned_responses')
export class CannedResponse {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  @IsNotEmpty()
  shortCode: string;

  @Column('text')
  @IsNotEmpty()
  content: string;

  @ManyToOne(() => Account)
  account: Account;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
```

### Join Table Pattern
```typescript
@Entity('conversation_labels')
export class ConversationLabel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Conversation, conv => conv.labels)
  conversation: Conversation;

  @ManyToOne(() => Label, label => label.conversations)
  label: Label;
}
```

## Estimated Time Breakdown

| Category | Models | Hours per Engineer |
|----------|--------|-------------------|
| Team A | 10 | 27 hours |
| Team B | 9 | 24 hours |
| Team C | 12 | 32 hours |

**Average**: ~27 hours per engineer = **1 week**

## Dependencies

**Must Complete First:**
- Epic 03 (Account, User, Conversation, Message, Contact)
- Epic 04 (Channel models for ContactInbox)
- Epic 05 (Integration models for some associations)

**Enables:**
- Epic 07-10 (API controllers need these models)
- Epic 12-13 (Background jobs use these models)

## Rollback Plan

- Remove entity files
- Remove factories
- Remove tests
- No production impact (Rails still running)

---

**Status**: 🟡 Ready (after Epic 03-05)
**Priority**: Medium (less critical than core/channel/integration)
**Rails Files**: Various in `app/models/`
