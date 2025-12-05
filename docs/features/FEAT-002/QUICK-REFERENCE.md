# FEAT-002: API Campaign - Quick Reference Card

## One-Page Summary

**Status:** ✅ Production Ready | **Commit:** 923ae29a8 | **Date:** Sep 20, 2025

---

## What Is It?

One-off campaigns for API and WhatsApp channels with label-based targeting and scheduled execution.

---

## Key Files

### Frontend (Vue 3)
```
app/javascript/dashboard/
├── components-next/Campaigns/Pages/CampaignPage/APICampaign/
│   ├── APICampaignForm.vue (189 lines) - Form with validation
│   └── APICampaignDialog.vue (49 lines) - Dialog wrapper
├── routes/dashboard/campaigns/pages/
│   └── APICampaignsPage.vue (85 lines) - Main page
└── routes/dashboard/campaigns/
    └── campaigns.routes.js - Route: /campaigns/api
```

### Backend (Rails)
```
app/services/
├── api/oneoff_api_campaign_service.rb (52 lines)
└── whatsapp/oneoff_whatsapp_campaign_service.rb (46 lines)

app/models/campaign.rb - execute_campaign method
```

### Tests
```
Frontend: APICampaignForm.spec.js, APICampaignsPage.spec.js (347 lines)
Backend: oneoff_api_campaign_service_spec.rb (146 lines)
         oneoff_whatsapp_campaign_service_spec.rb (114 lines)
```

---

## User Flow

```
1. Admin → /campaigns/api
2. Click "Create campaign"
3. Fill form:
   - Title (required)
   - Message (required)
   - Inbox (API inboxes only, required)
   - Audience (labels, multi-select, required)
   - Schedule (future datetime, required)
4. Submit → Validation → Create
5. Campaign saved, background job scheduled
6. At scheduled time:
   - Service executes
   - Marks campaign completed
   - Finds contacts with matching labels
   - Creates conversations (API) or sends messages (WhatsApp)
   - Webhooks notify external systems
```

---

## Technical Flow

```
APICampaignForm
  ↓ (validates with Vuelidate)
Campaign Store (campaigns/create)
  ↓ (POST /api/v1/campaigns)
Campaign Model (ActiveRecord)
  ↓ (background job at scheduled_at)
Campaign#trigger! → execute_campaign
  ↓ (routes by inbox_type)
Api::OneoffApiCampaignService
  ↓
  1. Validate (API inbox + one_off campaign)
  2. Mark completed (prevent re-run)
  3. Get labels from audience
  4. Find contacts: tagged_with(labels, any: true)
  5. For each contact:
     - Apply delay (sleep) if index > 0 and delay configured
     - ContactInboxBuilder (creates with UUID)
     - CampaignConversationBuilder (creates conv + message)
  6. Webhook events triggered
  7. Log success/errors
```

---

## API Request Examples

### Example 1: Campaign with No Delay (Default)

```javascript
POST /api/v1/campaigns

{
  "title": "Summer Sale",
  "message": "Check out our 50% off sale!",
  "inbox_id": 1,
  "scheduled_at": "2025-10-05T14:00:00.000Z",
  "audience": [
    { "type": "Label", "id": 1 },
    { "type": "Label", "id": 2 }
  ],
  "trigger_rules": {
    "delay": { "type": "none" }
  }
}
```

### Example 2: Campaign with Fixed 5-Second Delay

```javascript
POST /api/v1/campaigns

{
  "title": "Product Announcement",
  "message": "New feature available now!",
  "inbox_id": 1,
  "scheduled_at": "2025-10-05T14:00:00.000Z",
  "audience": [
    { "type": "Label", "id": 1 }
  ],
  "trigger_rules": {
    "delay": {
      "type": "fixed",
      "seconds": 5
    }
  }
}
```

### Example 3: Campaign with Random 3-10 Second Delay

```javascript
POST /api/v1/campaigns

{
  "title": "Re-engagement Campaign",
  "message": "We miss you! Come back for exclusive offers.",
  "inbox_id": 1,
  "scheduled_at": "2025-10-05T14:00:00.000Z",
  "audience": [
    { "type": "Label", "id": 3 },
    { "type": "Label", "id": 4 }
  ],
  "trigger_rules": {
    "delay": {
      "type": "random",
      "min": 3,
      "max": 10
    }
  }
}
```

---

## Database Schema (Key Fields)

```sql
campaigns (
  id bigint PRIMARY KEY,
  account_id bigint NOT NULL,         -- indexed
  inbox_id bigint NOT NULL,           -- indexed
  title varchar NOT NULL,
  message text NOT NULL,
  campaign_type int NOT NULL,         -- 0:ongoing, 1:one_off
  campaign_status int NOT NULL,       -- 0:active, 1:completed
  audience jsonb,                     -- [{"type":"Label","id":1}]
  scheduled_at timestamp,             -- indexed
  display_id int NOT NULL
)
```

---

## Validation Rules

### Frontend (Vuelidate)
- title: required, minLength(1)
- message: required, minLength(1), maxLength(150000)
- inboxId: required
- scheduledAt: required, future date only
- selectedAudience: required

### Backend (ActiveRecord)
- account_id, inbox_id, title, message: presence
- message: length { maximum: Limits::CAMPAIGN_MESSAGE_MAX_LENGTH } (150,000 chars)
- inbox: must be API/Whatsapp/SMS/Twilio SMS/Website type
- inbox: must belong to same account
- completed campaigns: cannot be updated

---

## Store Integrations

```javascript
// New getter
inboxes/getAPIInboxes
  → filters records by channel_type === INBOX_TYPES.API

// Existing actions used
campaigns/create
campaigns/getCampaigns
labels/getLabels
campaigns/getUIFlags
```

---

## Service Pattern

Both API and WhatsApp services follow same pattern:

```ruby
class Api::OneoffApiCampaignService
  pattr_initialize [:campaign!]

  def perform
    validate!
    mark_completed!
    process_audience(get_labels)
  end

  private

  def process_audience(labels)
    contacts = find_contacts(labels)
    contacts.each { |c| process_contact(c) }
  end
end
```

**Differences:**
- **API**: Creates ContactInbox → Conversation → Message
- **WhatsApp**: Sends message directly via channel.send_message()

---

## Testing Commands

```bash
# Frontend (Vitest)
pnpm test APICampaign

# Backend (RSpec)
bundle exec rspec spec/services/api/oneoff_api_campaign_service_spec.rb
bundle exec rspec spec/services/whatsapp/oneoff_whatsapp_campaign_service_spec.rb
```

---

## Common Tasks

### Add New Channel Support

```ruby
# 1. Create service
class Telegram::OneoffTelegramCampaignService
  # ...same pattern
end

# 2. Update Campaign model
def execute_campaign
  case inbox.inbox_type
  when 'Telegram'
    Telegram::OneoffTelegramCampaignService.new(campaign: self).perform
  # ...
  end
end

# 3. Add tests
# 4. Update frontend to filter Telegram inboxes
```

### Debug Campaign Execution

```bash
# Search logs
tail -f log/development.log | grep "\[API Campaign\]"

# Check campaign status
rails console
campaign = Campaign.find(123)
campaign.completed?
campaign.scheduled_at
campaign.inbox.inbox_type
```

---

## Error Handling

**Service validates and raises errors for:**
- Already completed campaigns
- Wrong inbox type (not API/WhatsApp)
- Non-one-off campaigns

**Graceful handling:**
- Individual contact failures don't stop campaign
- Errors logged with context
- Campaign marked completed even if some contacts fail

---

## Security

- ✅ Route guard: administrator role required
- ✅ Feature flag: CAMPAIGNS must be enabled
- ✅ Account scoping: all queries filtered by account
- ✅ Inbox validation: must belong to same account
- ✅ Completed protection: can't update finished campaigns

---

## Performance

- ✅ Background job processing (non-blocking)
- ✅ Database indexes on key fields
- ✅ Efficient label queries (tagged_with, any: true)
- ✅ Sequential contact processing (no overwhelming)
- ✅ Error isolation (continue on failures)

---

## i18n Keys

```json
CAMPAIGN.API.HEADER_TITLE
CAMPAIGN.API.NEW_CAMPAIGN
CAMPAIGN.API.EMPTY_STATE.TITLE
CAMPAIGN.API.EMPTY_STATE.SUBTITLE
CAMPAIGN.API.CREATE.TITLE
CAMPAIGN.API.CREATE.FORM.TITLE.LABEL
CAMPAIGN.API.CREATE.FORM.TITLE.PLACEHOLDER
CAMPAIGN.API.CREATE.FORM.TITLE.ERROR
... (similar for MESSAGE, INBOX, AUDIENCE, SCHEDULED_AT)
CAMPAIGN.API.CREATE.FORM.API.SUCCESS_MESSAGE
CAMPAIGN.API.CREATE.FORM.API.ERROR_MESSAGE
```

---

## Monitoring

**Logs to watch:**
```
[API Campaign] Created conversation 123 for contact 456 in campaign 789
[API Campaign] Failed to create conversation for contact 456: {error}
```

**Analytics events:**
```javascript
CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, { type: CAMPAIGN_TYPES.ONE_OFF }
```

**Webhooks:**
- conversation_created
- message_created

---

## Known Limitations (MVP Scope)

- ❌ No recurring campaigns
- ❌ No draft mode
- ❌ No campaign editing after creation
- ❌ No message templates with variables
- ❌ No rich media support
- ❌ No test send
- ❌ No delivery tracking in UI
- ❌ Label-based targeting only (no segments, custom attributes)

See README.md "Future Enhancements" for roadmap.

---

## Quick Troubleshooting

**Campaign not executing?**
- Check scheduled_at is in the future
- Check background job is running (Sidekiq)
- Check campaign.completed? is false
- Check inbox.inbox_type matches service

**No contacts receiving messages?**
- Check contacts have matching labels
- Check audience JSON structure
- Check logs for individual errors
- For WhatsApp: check contacts have phone numbers

**Form validation errors?**
- All fields required
- Scheduled time must be future
- At least one label required
- API inbox must be selected

---

## Resources

- **Full Spec:** `docs/features/FEAT-002/README.md` (1,150 lines)
- **Progress:** `docs/features/FEAT-002/PROGRESS.md` (520 lines)
- **Index:** `docs/features/FEAT-002/INDEX.md` (210 lines)
- **Quick Reference:** `docs/features/FEAT-002/QUICK-REFERENCE.md` (This file)
- **Extension - Message Delay:** `docs/features/FEAT-002/EXT-001-MESSAGE-DELAY.md` (✅ Completed)

---

## Contact

- Developer: @milesibastos
- Email: antonio@milesibastos.com
- Commit: 923ae29a8
- Date: September 20, 2025

---

## Recent Updates

**October 4, 2025:**
- ✅ Message character limit increased from 200 to 150,000 characters
- ✅ Added `Limits::CAMPAIGN_MESSAGE_MAX_LENGTH` constant
- ✅ Frontend validation updated with `:max-length="150000"`
- ✅ Backend validation: `length: { maximum: 150_000 }`
- ✅ 3 new RSpec tests for message length validation
- ✅ Matches Message model's content limit

---

**Last Updated:** October 4, 2025
