# FEAT-002: API Campaign - Architecture Diagram

## System Architecture Overview

This document provides visual representations of the API Campaign feature architecture, data flows, and component interactions.

---

## Component Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Frontend Layer (Vue 3)                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────┐      ┌────────────────────┐                │
│  │  APICampaignsPage  │      │  Sidebar.vue       │                │
│  │  (Route Component) │◄─────┤  (Navigation)      │                │
│  └────────────────────┘      └────────────────────┘                │
│           │                                                          │
│           ├──► Shows Loading Spinner                                │
│           ├──► Shows Campaign List                                  │
│           └──► Shows Empty State                                    │
│                                                                      │
│  ┌────────────────────┐      ┌────────────────────┐                │
│  │ APICampaignDialog  │◄─────┤  Campaign Store    │                │
│  │ (Form Wrapper)     │      │  (Vuex)            │                │
│  └────────────────────┘      └────────────────────┘                │
│           │                            │                             │
│           ▼                            ▼                             │
│  ┌────────────────────┐      ┌────────────────────┐                │
│  │ APICampaignForm    │◄─────┤  Inboxes Store     │                │
│  │ (Form + Validation)│      │  (getAPIInboxes)   │                │
│  └────────────────────┘      └────────────────────┘                │
│           │                            │                             │
│           └────────────────┬───────────┘                            │
│                            │                                         │
│                            ▼                                         │
│                   ┌────────────────────┐                            │
│                   │  Labels Store      │                            │
│                   │  (getLabels)       │                            │
│                   └────────────────────┘                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ HTTP API
                                   │ POST /api/v1/campaigns
                                   │
┌─────────────────────────────────────────────────────────────────────┐
│                         Backend Layer (Rails)                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────┐      ┌────────────────────┐                │
│  │ CampaignsController│─────►│  Campaign Model    │                │
│  │ (API Endpoint)     │      │  (ActiveRecord)    │                │
│  └────────────────────┘      └────────────────────┘                │
│                                       │                              │
│                                       │ trigger! (at scheduled_at)  │
│                                       │                              │
│                                       ▼                              │
│                              ┌─────────────────┐                    │
│                              │ execute_campaign│                    │
│                              │  (switch inbox) │                    │
│                              └─────────────────┘                    │
│                                       │                              │
│              ┌────────────────────────┼────────────────────┐        │
│              │                        │                    │        │
│              ▼                        ▼                    ▼        │
│  ┌───────────────────┐   ┌───────────────────┐   ┌──────────────┐ │
│  │ Api::Oneoff       │   │ Whatsapp::Oneoff  │   │ SMS/Twilio   │ │
│  │ ApiCampaign       │   │ WhatsappCampaign  │   │ Services     │ │
│  │ Service           │   │ Service           │   │              │ │
│  └───────────────────┘   └───────────────────┘   └──────────────┘ │
│           │                       │                                 │
│           │                       │                                 │
│           ▼                       ▼                                 │
│  ┌───────────────────┐   ┌───────────────────┐                    │
│  │ ContactInbox      │   │ WhatsApp Provider │                    │
│  │ Builder           │   │ send_message()    │                    │
│  └───────────────────┘   └───────────────────┘                    │
│           │                                                          │
│           ▼                                                          │
│  ┌───────────────────┐                                             │
│  │ CampaignConv.     │                                             │
│  │ Builder           │                                             │
│  └───────────────────┘                                             │
│           │                                                          │
│           ▼                                                          │
│  ┌───────────────────┐                                             │
│  │ Conversation +    │                                             │
│  │ Message Created   │                                             │
│  └───────────────────┘                                             │
│           │                                                          │
│           ▼                                                          │
│  ┌───────────────────┐                                             │
│  │ Webhook Events    │───────► External Systems                    │
│  └───────────────────┘                                             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow - Campaign Creation

```
┌──────────────┐
│ Administrator│
│ (User)       │
└──────┬───────┘
       │ 1. Clicks "Create Campaign"
       │
       ▼
┌─────────────────────┐
│ APICampaignsPage    │
│ (opens dialog)      │
└──────┬──────────────┘
       │ 2. Dialog Rendered
       │
       ▼
┌─────────────────────┐
│ APICampaignDialog   │
│ ├─ APICampaignForm  │
│ └─ Vuelidate        │
└──────┬──────────────┘
       │ 3. User fills form:
       │    - Title: "Summer Promotion"
       │    - Message: "Check out our sale!"
       │    - Inbox: API Inbox #1
       │    - Audience: [VIP, Premium]
       │    - Schedule: 2025-10-05 14:00
       │
       │ 4. Client-side validation (Vuelidate)
       │
       ▼
┌─────────────────────┐
│ Form Validation     │
│ ✓ Title required    │
│ ✓ Message required  │
│ ✓ Inbox required    │
│ ✓ Audience required │
│ ✓ Future time only  │
└──────┬──────────────┘
       │ 5. All valid → Submit
       │
       ▼
┌─────────────────────┐
│ Prepare Payload     │
│ {                   │
│   title,            │
│   message,          │
│   inbox_id,         │
│   scheduled_at: UTC,│
│   audience: [       │
│     {type, id}      │
│   ]                 │
│ }                   │
└──────┬──────────────┘
       │ 6. Store dispatch
       │    campaigns/create
       │
       ▼
┌─────────────────────┐
│ Campaign Store      │
│ (Vuex Action)       │
└──────┬──────────────┘
       │ 7. POST /api/v1/campaigns
       │
       ▼
┌─────────────────────┐
│ CampaignsController │
│ #create             │
└──────┬──────────────┘
       │ 8. Strong params
       │    Authorization
       │
       ▼
┌─────────────────────┐
│ Campaign.create!    │
│ ├─ Validations      │
│ ├─ Callbacks:       │
│ │  ensure_correct_  │
│ │  campaign_attrs   │
│ └─ Sets type:one_off│
└──────┬──────────────┘
       │ 9. Record saved
       │    display_id generated
       │
       ▼
┌─────────────────────┐
│ Background Job      │
│ Scheduled at        │
│ scheduled_at time   │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Success Response    │
│ 200 OK + campaign   │
└──────┬──────────────┘
       │ 10. UI Update
       │
       ▼
┌─────────────────────┐
│ Frontend Updates    │
│ ├─ Success alert    │
│ ├─ Close dialog     │
│ └─ Refresh list     │
└─────────────────────┘
```

---

## Data Flow - Campaign Execution

```
┌─────────────────────┐
│ Scheduled Time      │
│ Reached             │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Background Job      │
│ (Sidekiq)           │
│ campaign.trigger!   │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Campaign#trigger!   │
│ ├─ Check one_off?   │
│ └─ Check !completed?│
└──────┬──────────────┘
       │ Valid ✓
       │
       ▼
┌─────────────────────┐
│ execute_campaign    │
│ Switch inbox_type:  │
│ ├─ API              │
│ ├─ Whatsapp         │
│ ├─ Twilio SMS       │
│ └─ Sms              │
└──────┬──────────────┘
       │ For API type
       │
       ▼
┌─────────────────────────────────────────────┐
│ Api::OneoffApiCampaignService               │
├─────────────────────────────────────────────┤
│ 1. Validate campaign & inbox                │
│    ✓ inbox_type == 'API'                    │
│    ✓ campaign.one_off?                      │
│                                              │
│ 2. Mark campaign.completed!                 │
│    (Prevents duplicate execution)           │
│                                              │
│ 3. Extract audience labels                  │
│    audience_label_ids = [1, 2]              │
│    audience_labels = ["VIP", "Premium"]     │
│                                              │
│ 4. Find matching contacts                   │
│    contacts = account.contacts              │
│      .tagged_with(labels, any: true)        │
│    → [contact1, contact2, contact3]         │
│                                              │
│ 5. For each contact:                        │
└──────┬──────────────────────────────────────┘
       │
       ├─────────────────────────────────┐
       │                                 │
       ▼                                 ▼
┌─────────────────┐           ┌─────────────────┐
│ Contact #1      │           │ Contact #2      │
└──────┬──────────┘           └──────┬──────────┘
       │                              │
       ▼                              ▼
┌─────────────────────────────────────────────┐
│ ContactInboxBuilder                          │
│ ├─ contact: contact                          │
│ ├─ inbox: api_inbox                          │
│ ├─ source_id: nil (auto UUID)                │
│ └─ hmac_verified: false                      │
│                                              │
│ Returns: ContactInbox with UUID source_id    │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│ Campaigns::CampaignConversationBuilder       │
│ ├─ contact_inbox_id                          │
│ ├─ campaign_display_id                       │
│ ├─ conversation_additional_attributes        │
│ └─ custom_attributes                         │
│                                              │
│ Creates:                                     │
│ ├─ Conversation                              │
│ │  ├─ contact_inbox                          │
│ │  ├─ campaign_id                            │
│ │  └─ account                                │
│ └─ Message (first message)                   │
│    ├─ content: campaign.message              │
│    ├─ message_type: outgoing                 │
│    └─ additional_attributes:                 │
│       campaign_id: campaign.id               │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────┐
│ Webhook System      │
│ ├─ conversation_    │
│ │  created          │
│ └─ message_created  │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ External Systems    │
│ ├─ CRM update       │
│ ├─ Analytics        │
│ └─ Notifications    │
└─────────────────────┘
       │
       ▼
┌─────────────────────┐
│ Logging             │
│ [API Campaign]      │
│ Created conversation│
│ #{conv.id} for      │
│ contact #{cont.id}  │
└─────────────────────┘
```

---

## Service Architecture - Channel Pattern

```
                    ┌────────────────────┐
                    │  Campaign Model    │
                    │  #execute_campaign │
                    └─────────┬──────────┘
                              │
                              │ Routes based on inbox_type
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│ API Service   │     │ WhatsApp      │     │ SMS Service   │
│               │     │ Service       │     │               │
├───────────────┤     ├───────────────┤     ├───────────────┤
│ - Validates   │     │ - Validates   │     │ - Validates   │
│   API inbox   │     │   WA inbox    │     │   SMS inbox   │
│               │     │               │     │               │
│ - Marks       │     │ - Marks       │     │ - Marks       │
│   completed   │     │   completed   │     │   completed   │
│               │     │               │     │               │
│ - Gets labels │     │ - Gets labels │     │ - Gets labels │
│               │     │               │     │               │
│ - Finds       │     │ - Finds       │     │ - Finds       │
│   contacts    │     │   contacts    │     │   contacts    │
│               │     │   (w/ phone)  │     │   (w/ phone)  │
│               │     │               │     │               │
│ - Creates     │     │ - Sends       │     │ - Sends       │
│   ContactInbox│     │   message via │     │   message via │
│               │     │   channel     │     │   Twilio      │
│ - Creates     │     │               │     │               │
│   Conversation│     │               │     │               │
│   (via builder│     │               │     │               │
│   creates msg)│     │               │     │               │
└───────────────┘     └───────────────┘     └───────────────┘
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│ Conversations │     │ Direct message│     │ Direct message│
│ + Messages    │     │ to WhatsApp   │     │ to phone      │
│ created       │     │ provider      │     │ via Twilio    │
└───────────────┘     └───────────────┘     └───────────────┘
```

**Key Differences:**

| Aspect | API Service | WhatsApp Service | SMS Service |
|--------|-------------|------------------|-------------|
| Creates Conversation | ✅ Yes | ❌ No | ❌ No |
| Creates ContactInbox | ✅ Yes | ❌ No | ❌ No |
| Sends via Channel | ❌ No (webhook) | ✅ Yes | ✅ Yes |
| Requires Phone | ❌ No | ✅ Yes | ✅ Yes |
| Message Storage | DB (via builder) | Channel provider | Channel provider |

---

## Database Schema

```
┌─────────────────────────────────────────────┐
│ campaigns                                   │
├─────────────────────────────────────────────┤
│ id (PK)                                     │
│ account_id (FK → accounts)        [indexed] │
│ inbox_id (FK → inboxes)           [indexed] │
│ title (string, required)                    │
│ message (text, required)                    │
│ campaign_type (int)               [indexed] │
│   0: ongoing                                │
│   1: one_off                                │
│ campaign_status (int)             [indexed] │
│   0: active                                 │
│   1: completed                              │
│ audience (jsonb)                            │
│   [{"type": "Label", "id": 1}, ...]         │
│ scheduled_at (timestamp)          [indexed] │
│ display_id (int, auto-generated)            │
│ sender_id (FK → users, optional)            │
│ enabled (boolean, default: true)            │
│ trigger_rules (jsonb)                       │
│ template_params (jsonb)                     │
│ description (text)                          │
│ trigger_only_during_business_hours (bool)   │
│ created_at (timestamp)                      │
│ updated_at (timestamp)                      │
└─────────────────────────────────────────────┘
          │                    │
          │                    │
          ▼                    ▼
┌─────────────────┐   ┌─────────────────┐
│ accounts        │   │ inboxes         │
├─────────────────┤   ├─────────────────┤
│ id (PK)         │   │ id (PK)         │
│ name            │   │ account_id (FK) │
│ ...             │   │ name            │
└─────────────────┘   │ inbox_type      │
                      │ channel_id (FK) │
                      │ ...             │
                      └─────────────────┘
                               │
                               ▼
                      ┌─────────────────┐
                      │ channels        │
                      ├─────────────────┤
                      │ id (PK)         │
                      │ type            │
                      │ ...             │
                      └─────────────────┘
```

**Campaign Execution Creates:**

```
campaigns (scheduled)
    │
    ├──► contact_inboxes (for each contact)
    │    ├─ id (PK)
    │    ├─ contact_id (FK)
    │    ├─ inbox_id (FK)
    │    ├─ source_id (UUID for API)
    │    └─ ...
    │
    └──► conversations (for each contact)
         ├─ id (PK)
         ├─ account_id (FK)
         ├─ inbox_id (FK)
         ├─ contact_id (FK)
         ├─ contact_inbox_id (FK)
         ├─ campaign_id (FK)
         └─ ...
              │
              └──► messages (first message)
                   ├─ id (PK)
                   ├─ conversation_id (FK)
                   ├─ content (campaign.message)
                   ├─ message_type (outgoing)
                   ├─ additional_attributes:
                   │  {"campaign_id": campaign.id}
                   └─ ...
```

---

## State Machine - Campaign Lifecycle

```
┌─────────────┐
│   Created   │
│             │
│ campaign_   │
│ type:       │
│ one_off     │
│             │
│ campaign_   │
│ status:     │
│ active      │
└──────┬──────┘
       │
       │ Saved to DB
       │
       ▼
┌─────────────┐
│  Scheduled  │
│             │
│ Background  │
│ job queued  │
│ for         │
│ scheduled_at│
└──────┬──────┘
       │
       │ Time reached
       │
       ▼
┌─────────────┐
│  Triggered  │
│             │
│ trigger!    │
│ called      │
└──────┬──────┘
       │
       ├──► Validation
       │    ├─ one_off? ✓
       │    └─ !completed? ✓
       │
       ▼
┌─────────────┐
│ Executing   │
│             │
│ Service     │
│ processing  │
│             │
│ ⚠️ Status   │
│ marked      │
│ completed   │
│ FIRST       │
└──────┬──────┘
       │
       ├──► For each contact:
       │    ├─ Create ContactInbox
       │    ├─ Create Conversation
       │    └─ Create Message
       │
       ▼
┌─────────────┐
│  Completed  │
│             │
│ campaign_   │
│ status:     │
│ completed   │
│             │
│ All contacts│
│ processed   │
└─────────────┘

**Important:** Campaign marked completed at START of execution
to prevent duplicate runs if job fails/retries.
```

---

## Error Handling Flow

```
┌─────────────────────┐
│ Campaign Execution  │
└──────┬──────────────┘
       │
       ├──► Check: already completed?
       │    YES → raise "Completed Campaign"
       │    NO  → continue
       │
       ├──► Check: valid inbox_type?
       │    NO  → raise "Invalid campaign"
       │    YES → continue
       │
       ├──► Mark as completed
       │    (prevents retry)
       │
       ├──► Get audience labels
       │    └──► Find contacts
       │         └──► For each contact:
       │
       ├──────────────────────┐
       │                      │
       ▼                      ▼
┌─────────────┐      ┌─────────────┐
│ Contact #1  │      │ Contact #2  │
└──────┬──────┘      └──────┬──────┘
       │                    │
       ├──► Try:            ├──► Try:
       │    └─ ContactInbox │    └─ ContactInbox
       │       creation     │       creation
       │                    │
       │    Success ✓       │    FAILS ✗
       │                    │
       ▼                    ▼
┌─────────────┐      ┌─────────────────────┐
│ Continue to │      │ Rescue              │
│ Conversation│      │ StandardError       │
│ creation    │      │                     │
│             │      │ Log error:          │
│             │      │ "[API Campaign]     │
│             │      │ Failed to create    │
│             │      │ conversation for    │
│             │      │ contact #{id}"      │
└──────┬──────┘      │                     │
       │             │ Continue to next    │
       │             │ contact (don't stop)│
       ▼             └─────────────────────┘
┌─────────────┐                │
│ Success     │                │
│             │◄───────────────┘
│ Log:        │
│ "[API       │
│ Campaign]   │
│ Created     │
│ conversation│
│ #{id}"      │
└─────────────┘

Result: Campaign marked completed even if some contacts failed.
Individual failures don't stop entire campaign.
```

---

## Frontend State Flow

```
┌─────────────────────────────────────────────┐
│ APICampaignsPage State                      │
├─────────────────────────────────────────────┤
│                                             │
│ isFetchingCampaigns (computed)              │
│   ↓                                         │
│   uiFlags.isFetching                        │
│                                             │
│ APICampaigns (computed)                     │
│   ↓                                         │
│   getCampaigns(CAMPAIGN_TYPES.ONE_OFF)      │
│   .filter(c => c.inbox.channel_type         │
│             .includes('Api'))               │
│                                             │
│ hasNoAPICampaigns (computed)                │
│   ↓                                         │
│   APICampaigns.length === 0 &&              │
│   !isFetchingCampaigns                      │
│                                             │
└─────────────────────────────────────────────┘
          │
          │ Determines UI state:
          │
          ├──► isFetchingCampaigns = true
          │    └──► Show Spinner
          │
          ├──► hasNoAPICampaigns = true
          │    └──► Show Empty State
          │
          └──► else
               └──► Show Campaign List
```

---

## Form Validation Flow

```
┌─────────────────────────────────────────────┐
│ APICampaignForm (Vuelidate)                 │
├─────────────────────────────────────────────┤
│                                             │
│ state = {                                   │
│   title: '',                                │
│   message: '',                              │
│   inboxId: null,                            │
│   scheduledAt: null,                        │
│   selectedAudience: []                      │
│ }                                           │
│                                             │
│ rules = {                                   │
│   title: { required, minLength(1) }         │
│   message: { required, minLength(1) }       │
│   inboxId: { required }                     │
│   scheduledAt: { required }                 │
│   selectedAudience: { required }            │
│ }                                           │
│                                             │
└──────┬──────────────────────────────────────┘
       │
       │ User input triggers validation
       │
       ▼
┌─────────────────────┐
│ v$.{field}.$error   │
│                     │
│ true → show error   │
│ false → no error    │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ formErrors          │
│ (computed)          │
│                     │
│ Returns error msg   │
│ or empty string     │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Template displays:  │
│                     │
│ :message="formErrors│
│          .title"    │
│ :message-type=      │
│   "error"/"info"    │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ isSubmitDisabled    │
│ (computed)          │
│                     │
│ v$.$invalid         │
│                     │
│ true → disable btn  │
│ false → enable btn  │
└─────────────────────┘
       │
       ▼
┌─────────────────────┐
│ handleSubmit()      │
│                     │
│ await v$.$validate()│
│                     │
│ if !valid → return  │
│ if valid → emit     │
│            submit   │
└─────────────────────┘
```

---

## Multi-Channel Service Pattern

This pattern allows easy extension for new channel types:

```
To add a new channel (e.g., Telegram):

1. Create service:
   /app/services/telegram/oneoff_telegram_campaign_service.rb

   class Telegram::OneoffTelegramCampaignService
     pattr_initialize [:campaign!]

     def perform
       # Validate inbox type
       # Mark completed
       # Process audience
       # Send via Telegram channel
     end
   end

2. Update Campaign model:
   def execute_campaign
     case inbox.inbox_type
     when 'API'
       Api::OneoffApiCampaignService.new(campaign: self).perform
     when 'Telegram'
       Telegram::OneoffTelegramCampaignService.new(campaign: self).perform
     # ... other channels
     end
   end

3. Add tests:
   /spec/services/telegram/oneoff_telegram_campaign_service_spec.rb

4. Update frontend:
   - Add TelegramCampaignsPage.vue
   - Add route
   - Add getTelegramInboxes getter
   - Add i18n keys
```

---

## Security Layers

```
┌─────────────────────────────────────────────┐
│ Security & Authorization Layers             │
├─────────────────────────────────────────────┤
│                                             │
│ 1. Route Guard                              │
│    ├─ FEATURE_FLAGS.CAMPAIGNS (enabled)     │
│    └─ permissions: ['administrator']        │
│                                             │
│ 2. Account Scoping                          │
│    └─ All queries scoped to current account │
│                                             │
│ 3. Model Validations                        │
│    ├─ inbox_must_belong_to_account          │
│    ├─ sender_must_belong_to_account         │
│    └─ validate_campaign_inbox               │
│                                             │
│ 4. Completed Campaign Protection            │
│    └─ prevent_completed_campaign_from_update│
│                                             │
│ 5. Service Validations                      │
│    ├─ Check inbox_type matches service      │
│    ├─ Check campaign.one_off?               │
│    └─ Check !campaign.completed?            │
│                                             │
└─────────────────────────────────────────────┘
```

---

## Performance Optimizations

```
Database Indexing:
┌─────────────────────────────────────────────┐
│ campaigns table indexes:                    │
├─────────────────────────────────────────────┤
│ ✓ account_id        (for account scoping)   │
│ ✓ inbox_id          (for inbox filtering)   │
│ ✓ campaign_status   (for status queries)    │
│ ✓ campaign_type     (for type filtering)    │
│ ✓ scheduled_at      (for job scheduler)     │
└─────────────────────────────────────────────┘

Background Processing:
┌─────────────────────────────────────────────┐
│ Campaign execution in Sidekiq worker        │
├─────────────────────────────────────────────┤
│ ✓ Non-blocking web requests                 │
│ ✓ Sequential contact processing             │
│ ✓ Error isolation (one failure ≠ all fail)  │
│ ✓ Logging for monitoring                    │
└─────────────────────────────────────────────┘

Query Optimization:
┌─────────────────────────────────────────────┐
│ Efficient label matching                    │
├─────────────────────────────────────────────┤
│ ✓ Single query for all matching contacts    │
│ ✓ ActsAsTaggableOn optimized queries        │
│ ✓ tagged_with(labels, any: true)            │
│   (OR logic, not N+1)                       │
└─────────────────────────────────────────────┘
```

---

## Monitoring & Observability

```
Logging Strategy:
┌─────────────────────────────────────────────┐
│ Structured logging with [API Campaign]      │
├─────────────────────────────────────────────┤
│ Success logs:                               │
│ "[API Campaign] Created conversation 123    │
│  for contact 456 in campaign 789"           │
│                                             │
│ Error logs:                                 │
│ "[API Campaign] Failed to create            │
│  conversation for contact 456: {error}"     │
└─────────────────────────────────────────────┘

Analytics Events:
┌─────────────────────────────────────────────┐
│ CAMPAIGNS_EVENTS.CREATE_CAMPAIGN            │
├─────────────────────────────────────────────┤
│ Payload:                                    │
│ {                                           │
│   type: CAMPAIGN_TYPES.ONE_OFF              │
│ }                                           │
└─────────────────────────────────────────────┘

Webhook Events:
┌─────────────────────────────────────────────┐
│ Triggered on conversation/message creation  │
├─────────────────────────────────────────────┤
│ ✓ conversation_created                      │
│ ✓ message_created                           │
│                                             │
│ External systems can:                       │
│ ✓ Track campaign reach                      │
│ ✓ Monitor delivery                          │
│ ✓ Measure engagement                        │
└─────────────────────────────────────────────┘
```

---

## Extension Points

```
The architecture supports these extension points:

1. New Channel Types
   └─ Add service in /app/services/{channel}/
   └─ Update Campaign#execute_campaign
   └─ Add frontend page and routes

2. New Audience Types
   └─ Extend audience JSON structure
   └─ Update service process_audience method
   └─ Add form fields for new criteria

3. Template Support
   └─ Add template_id to campaign model
   └─ Create TemplateRenderer service
   └─ Update message creation logic

4. Scheduling Enhancements
   └─ Add recurring fields to model
   └─ Create RecurringCampaignScheduler
   └─ Update trigger logic

5. Analytics
   └─ Create CampaignAnalytics service
   └─ Add dashboard components
   └─ Track delivery/response metrics
```

---

**Last Updated:** October 4, 2025
**Version:** 1.0
**Status:** Production
