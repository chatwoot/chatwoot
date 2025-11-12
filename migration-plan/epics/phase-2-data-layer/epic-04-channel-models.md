# Epic 04: Channel Models

## Overview
- **Duration**: 1 week
- **Complexity**: Medium
- **Dependencies**: Epic 03 (Inbox model)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: Yes (each channel independent)

## Scope: 9 Channel Models

1. **Channel::FacebookPage** - Facebook Messenger integration
2. **Channel::Instagram** - Instagram messaging
3. **Channel::WhatsApp** - WhatsApp Business API
4. **Channel::Slack** - Slack workspace integration
5. **Channel::Telegram** - Telegram bot
6. **Channel::Line** - Line messaging
7. **Channel::TwitterProfile** - Twitter/X DM
8. **Channel::TwilioSms** - Twilio SMS
9. **Channel::Email** - SMTP/IMAP email

All channels inherit from Channel base class/concern and have similar structure.

## Success Criteria
- ✅ All 9 channel models migrated
- ✅ All associations working (belongs_to :inbox)
- ✅ All validations ported
- ✅ Tests passing (≥90% coverage)
- ✅ Factories created

## Task Pattern (Repeat for Each Channel)

### Per Channel: ~4 hours
1. Read Rails model + specs
2. Write TypeScript tests (TDD: Red)
3. Create TypeORM entity
4. Implement associations
5. Implement validations
6. Create factory
7. Run tests (TDD: Green)
8. Verify feature parity

## Common Channel Structure

```typescript
@Entity('channel_facebook_pages')
export class ChannelFacebookPage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column()
  pageId: string;

  @Column()
  pageAccessToken: string;

  @ManyToOne(() => Inbox, inbox => inbox.channels)
  inbox: Inbox;

  @Column()
  inboxId: string;

  // Channel-specific fields...
}
```

## Parallel Opportunities
- **Team A**: Facebook, Instagram, WhatsApp (Meta-based, 3 models)
- **Team B**: Slack, Telegram, Line (Messaging apps, 3 models)
- **Team C**: Twitter, Twilio, Email (Other, 3 models)

## Rollback Plan
- Remove entity files
- Remove factories
- No production impact (Rails still working)

---

**Status**: 🟡 Ready (after Epic 03)
**Detailed Rails Files**: `app/models/channel/*.rb`
