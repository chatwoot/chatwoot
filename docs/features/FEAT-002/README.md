# FEAT-002: API Campaign Feature

## Feature Overview

The API Campaign feature enables Chatwoot administrators to create and execute one-off marketing campaigns through API channel integrations. This feature allows users to send targeted messages to specific customer segments (defined by labels) through API-based communication channels at scheduled times.

### Key Capabilities

- Create one-off campaigns for API and WhatsApp channels
- Target specific customer audiences using label-based segmentation
- Schedule campaign execution at specific times
- **Configurable message delays** (none, fixed, or random) to prevent rate limiting
- Automatic conversation creation for each targeted contact
- Multi-channel support with channel-specific service implementations
- Webhook integration for external system notifications

### User Personas

**Primary Users:**
- **Administrators**: Create and manage API campaigns, configure scheduling and targeting
- **Marketing Managers**: Launch targeted customer communications for promotions, announcements, or notifications

**Secondary Users:**
- **System Integrators**: Receive webhook notifications for campaign-triggered conversations
- **Support Agents**: Handle conversations generated from campaigns

### Business Value

1. **Customer Engagement**: Proactively reach customers with targeted messages
2. **Marketing Automation**: Send scheduled announcements, offers, or updates without manual intervention
3. **Integration Flexibility**: Support for multiple channel types (API, WhatsApp) with extensible architecture
4. **Audience Segmentation**: Precise targeting using existing label infrastructure
5. **Scalability**: Background job processing ensures campaigns don't impact system performance

### Use Cases

1. **Product Announcements**: Notify premium customers about new features or updates
2. **Promotional Campaigns**: Send time-sensitive offers to specific customer segments
3. **System Notifications**: Alert customers about maintenance windows or important updates
4. **Re-engagement**: Reach out to inactive customers with targeted messages
5. **Event Invitations**: Invite VIP customers to exclusive events or webinars

---

## User Stories

### US-001: Create API Campaign

**As an** administrator
**I want** to create a one-off API campaign with targeted messaging
**So that** I can reach specific customer segments through API integrations

**Acceptance Criteria:**

- Given I am an administrator
- When I navigate to the API campaigns page
- Then I should see an option to create a new campaign
- And I should be able to fill in campaign details (title, message, inbox, schedule, audience)
- And the form should validate all required fields
- And upon successful creation, I should see a confirmation message
- And the campaign should appear in the campaigns list

### US-002: Schedule Campaign Execution

**As an** administrator
**I want** to schedule a campaign for future execution
**So that** messages are sent at optimal times

**Acceptance Criteria:**

- Given I am creating a campaign
- When I select a scheduled time
- Then I should only be able to select future dates/times
- And the system should convert local time to UTC for storage
- And the campaign should execute at the specified time
- And the campaign status should change to "completed" after execution

### US-003: Target Audience by Labels

**As an** administrator
**I want** to select customer labels as campaign audience
**So that** only relevant customers receive the message

**Acceptance Criteria:**

- Given I am creating a campaign
- When I select audience labels
- Then I should be able to choose multiple labels
- And the system should target contacts with ANY of the selected labels
- And contacts without matching labels should be excluded
- And each targeted contact should receive exactly one message

### US-004: View Campaign List

**As an** administrator
**I want** to view all API campaigns in my account
**So that** I can track campaign history and status

**Acceptance Criteria:**

- Given I navigate to the API campaigns page
- When campaigns exist in my account
- Then I should see a list of all API campaigns
- And each campaign should display title, status, inbox, and scheduled time
- And I should be able to delete campaigns
- And I should see an empty state when no campaigns exist

---

## Technical Architecture

### Frontend Components

#### 1. APICampaignsPage.vue
**Location:** `app/javascript/dashboard/routes/dashboard/campaigns/pages/APICampaignsPage.vue`

**Responsibilities:**
- Main page component for API campaigns
- Displays campaign list or empty state
- Handles campaign deletion
- Filters campaigns to show only API channel types

**Key Features:**
- Computed property to filter one-off campaigns by API inbox type
- Loading state management with spinner
- Dialog management for campaign creation
- Integration with campaign store

#### 2. APICampaignForm.vue
**Location:** `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/APICampaign/APICampaignForm.vue`

**Responsibilities:**
- Form for creating API campaigns
- Client-side validation using Vuelidate
- State management and form submission

**Form Fields:**
- `title` (String, required, min 1 character)
- `message` (String, required, min 1 character, max 150,000 characters, character count)
- `inboxId` (Number, required, filtered to API inboxes only)
- `scheduledAt` (DateTime, required, must be future time)
- `selectedAudience` (Array of label IDs, required, multi-select)

**Validation Rules:**
```javascript
const rules = {
  title: { required, minLength: minLength(1) },
  message: { required, minLength: minLength(1), maxLength: maxLength(150000) },
  inboxId: { required },
  scheduledAt: { required },
  selectedAudience: { required },
};
```

**Note:** The 150,000 character limit for campaign messages matches the Message model's content limit, allowing for comprehensive campaign messages while preventing database issues.

#### 3. APICampaignDialog.vue
**Location:** `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/APICampaign/APICampaignDialog.vue`

**Responsibilities:**
- Dialog wrapper for campaign form
- Campaign creation dispatch to store
- Success/error handling with alerts
- Analytics event tracking

#### 4. APICampaignEmptyState.vue
**Location:** `app/javascript/dashboard/components-next/Campaigns/EmptyState/APICampaignEmptyState.vue`

**Responsibilities:**
- Empty state display when no campaigns exist
- Instructional content to guide users
- Sample campaign cards for visualization

### Backend Services

#### 1. Api::OneoffApiCampaignService
**Location:** `app/services/api/oneoff_api_campaign_service.rb`

**Purpose:** Process API campaigns by creating conversations and messages for targeted contacts

**Workflow:**
1. Validates campaign is API type and one-off
2. Marks campaign as completed (prevents duplicate execution)
3. Extracts audience labels from campaign
4. Finds all contacts tagged with any of the audience labels
5. For each contact:
   - Creates/finds ContactInbox with auto-generated UUID source_id
   - Creates Conversation using CampaignConversationBuilder
   - Conversation automatically includes campaign message via builder
   - Webhook system notifies external systems

**Key Methods:**
```ruby
def perform
  # Validation
  # Mark completed
  # Process audience
end

def process_audience(audience_labels)
  # Find contacts
  # Create conversations
end

def create_conversation_and_message(contact)
  # ContactInboxBuilder
  # CampaignConversationBuilder
end
```

**Error Handling:**
- Raises error for invalid campaign type
- Raises error for completed campaigns
- Logs errors for individual contact failures
- Continues processing remaining contacts on failure

#### 2. Whatsapp::OneoffWhatsappCampaignService
**Location:** `app/services/whatsapp/oneoff_whatsapp_campaign_service.rb`

**Purpose:** Process WhatsApp campaigns by sending messages directly through WhatsApp channel

**Workflow:**
1. Validates campaign is WhatsApp type and one-off
2. Marks campaign as completed
3. Extracts audience labels
4. Finds all contacts with matching labels
5. For each contact with phone number:
   - Creates message object structure
   - Sends message via WhatsApp channel provider

**Key Differences from API Service:**
- Requires phone number validation (skips contacts without phone)
- Sends messages directly via channel (no conversation creation in service)
- Uses OpenStruct to create message object for WhatsApp provider

### Models

#### Campaign Model
**Location:** `app/models/campaign.rb`

**Schema:**
```ruby
# campaigns table
- id (bigint, primary key)
- title (string, required)
- message (text, required, max 150,000 characters)
- campaign_type (integer, enum: ongoing=0, one_off=1)
- campaign_status (integer, enum: active=0, completed=1)
- audience (jsonb)
- scheduled_at (datetime, indexed)
- inbox_id (bigint, required, indexed)
- account_id (bigint, required, indexed)
- display_id (integer, auto-generated)
- sender_id (integer, optional)
- enabled (boolean, default: true)
```

**Validation:**
```ruby
validates :message, presence: true, length: { maximum: Limits::CAMPAIGN_MESSAGE_MAX_LENGTH }
# where CAMPAIGN_MESSAGE_MAX_LENGTH = 150,000
```

**Campaign Lifecycle:**
1. Campaign created with `campaign_type: one_off` (auto-set for API/WhatsApp/SMS inboxes)
2. Campaign scheduled with `scheduled_at` timestamp
3. Background job triggers campaign at scheduled time
4. `trigger!` method called, which delegates to `execute_campaign`
5. `execute_campaign` routes to appropriate service based on inbox type
6. Service marks campaign as `completed` at start of execution
7. Campaign status prevents re-execution

**Audience Structure:**
```json
[
  { "type": "Label", "id": 1 },
  { "type": "Label", "id": 2 }
]
```

**Supported Inbox Types:**
- Website (ongoing campaigns only)
- Twilio SMS (one-off)
- Sms (one-off)
- Whatsapp (one-off)
- API (one-off)

**Model Callbacks:**
- `before_validation :ensure_correct_campaign_attributes` - Auto-sets campaign_type to one_off for API channels
- `after_commit :set_display_id` - Generates sequential display_id per account

### Store Integration

#### Inboxes Store
**Location:** `app/javascript/dashboard/store/modules/inboxes.js`

**New Getter:**
```javascript
getAPIInboxes($state) {
  return $state.records.filter(item => item.channel_type === INBOX_TYPES.API);
}
```

**Purpose:** Filters inboxes to show only API type channels for campaign inbox selection

### Routing

**Location:** `app/javascript/dashboard/routes/dashboard/campaigns/campaigns.routes.js`

**New Route:**
```javascript
{
  path: 'api',
  name: 'campaigns_api_index',
  meta: {
    featureFlag: FEATURE_FLAGS.CAMPAIGNS,
    permissions: ['administrator'],
  },
  component: APICampaignsPage,
}
```

**Access Control:**
- Requires `CAMPAIGNS` feature flag to be enabled
- Requires `administrator` role

### Navigation

**Sidebar Integration:**
Updated `Sidebar.vue` to include navigation link to API campaigns under Campaigns section.

---

## Implementation Details

### Campaign Creation Flow

1. **User Interaction:**
   - Administrator navigates to `/accounts/:accountId/campaigns/api`
   - Clicks "Create campaign" button
   - APICampaignDialog opens with APICampaignForm

2. **Form Validation:**
   - Vuelidate validates all fields on input
   - Submit button disabled until all fields valid
   - Error messages displayed for invalid fields

3. **Form Submission:**
   - Form prepares campaign details object:
     ```javascript
     {
       title: "Campaign Title",
       message: "Campaign message content",
       inbox_id: 1,
       scheduled_at: "2025-10-05T14:30:00.000Z", // UTC
       audience: [
         { id: 1, type: "Label" },
         { id: 2, type: "Label" }
       ]
     }
     ```
   - Dispatches to `campaigns/create` store action
   - Backend creates campaign record
   - Success alert shown, dialog closes
   - Campaign appears in list

4. **Backend Processing:**
   - Campaign record created in database
   - `ensure_correct_campaign_attributes` callback sets `campaign_type` to `one_off`
   - Campaign scheduled for execution via background job

### Campaign Execution Flow

1. **Triggering:**
   - Background job (Sidekiq) calls `campaign.trigger!` at scheduled time
   - `trigger!` method checks campaign is one_off and not completed
   - Delegates to `execute_campaign` private method

2. **Service Selection:**
   - `execute_campaign` checks `inbox.inbox_type`
   - Routes to appropriate service:
     - `API` → `Api::OneoffApiCampaignService`
     - `Whatsapp` → `Whatsapp::OneoffWhatsappCampaignService`
     - `Twilio SMS` → `Twilio::OneoffSmsCampaignService`
     - `Sms` → `Sms::OneoffSmsCampaignService`

3. **API Campaign Processing:**
   - Service validates campaign and inbox type
   - Marks campaign as completed immediately (prevents re-execution)
   - Extracts label IDs from audience array
   - Queries contacts with matching labels (ANY match, not ALL)
   - For each contact:
     - Creates ContactInbox with auto-generated UUID source_id
     - Creates Conversation via CampaignConversationBuilder
     - Conversation builder automatically creates first message with campaign content
     - Logs success/failure for each contact

4. **Webhook Notifications:**
   - Conversation creation triggers webhook events
   - External systems receive notifications about new conversations
   - Systems can process campaign-triggered conversations via API

### Scheduling Mechanism

**Frontend Time Handling:**
```javascript
// Current local time (prevents past time selection)
const currentDateTime = computed(() => {
  const now = new Date();
  const localTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return localTime.toISOString().slice(0, 16);
});

// Convert to UTC for backend
const formatToUTCString = localDateTime =>
  localDateTime ? new Date(localDateTime).toISOString() : null;
```

**Backend Scheduling:**
- Campaign model stores `scheduled_at` in UTC
- Background job scheduler (likely Sidekiq-scheduler or similar) checks for campaigns due
- Campaigns executed at or after scheduled_at time
- Completed status prevents duplicate execution

### Audience Targeting

**Label-based Segmentation:**
```ruby
# Extract label IDs from audience
audience_label_ids = campaign.audience.select { |audience| audience['type'] == 'Label' }.pluck('id')

# Get label titles
audience_labels = campaign.account.labels.where(id: audience_label_ids).pluck(:title)

# Find contacts with ANY matching label
contacts = campaign.account.contacts.tagged_with(audience_labels, any: true)
```

**Key Points:**
- Uses ActsAsTaggableOn gem for label matching
- `any: true` means contacts need at least one matching label
- Each contact receives message once (even if they have multiple matching labels)
- Contacts must be associated with the campaign's account

### Channel-Specific Handling

#### API Channels
**Contact Inbox Creation:**
```ruby
contact_inbox = ContactInboxBuilder.new(
  contact: contact,
  inbox: inbox,
  source_id: nil, # Auto-generates UUID
  hmac_verified: false
).perform
```

**Conversation Creation:**
```ruby
conversation = Campaigns::CampaignConversationBuilder.new(
  contact_inbox_id: contact_inbox.id,
  campaign_display_id: campaign.display_id,
  conversation_additional_attributes: {},
  custom_attributes: {}
).perform
```

**Message Handling:**
- CampaignConversationBuilder automatically creates first message
- Message content comes from campaign.message
- Message includes campaign_id in additional_attributes

#### WhatsApp Channels
**Direct Message Sending:**
```ruby
message_object = OpenStruct.new(
  content: campaign.message,
  attachments: [],
  conversation: OpenStruct.new(
    contact_inbox: OpenStruct.new(source_id: nil),
    can_reply?: true
  ),
  additional_attributes: {},
  content_type: nil,
  content_attributes: {}
)

channel.send_message(to: contact.phone_number, message_object)
```

**Differences:**
- No ContactInbox or Conversation created by service
- Messages sent directly to WhatsApp provider
- Requires valid phone number on contact

---

## UI/UX Specifications

### Campaign Creation Form

**Form Layout:**
```
┌─────────────────────────────────────┐
│ Create API campaign                 │
├─────────────────────────────────────┤
│ Title *                             │
│ [Input field                      ] │
│                                     │
│ Message *                           │
│ [Textarea with character count    ] │
│ [                                 ] │
│                                     │
│ Select Inbox *                      │
│ [Dropdown - API inboxes only    ▼ ] │
│                                     │
│ Audience *                          │
│ [Multi-select labels            ▼ ] │
│                                     │
│ Scheduled time *                    │
│ [DateTime picker               📅 ] │
│                                     │
│ [ Cancel ]  [ Create ]              │
└─────────────────────────────────────┘
```

**Field Specifications:**

| Field | Type | Required | Validation | Placeholder |
|-------|------|----------|------------|-------------|
| Title | Text Input | Yes | Min 1 char | "Please enter the title of campaign" |
| Message | Textarea | Yes | Min 1 char, Max 150,000 chars | "Please enter the message of campaign" |
| Inbox | Dropdown | Yes | Must be API inbox | "Select Inbox" |
| Audience | Multi-select | Yes | At least 1 label | "Select the customer labels" |
| Scheduled time | DateTime | Yes | Future time only | "Please select the time" |

**Validation Messages:**
- Title: "Title is required"
- Message: "Message is required"
- Inbox: "Inbox is required"
- Audience: "Audience is required"
- Scheduled time: "Scheduled time is required"

**UI States:**
- **Normal**: All fields editable
- **Validating**: Error messages shown below invalid fields
- **Submitting**: Create button shows loading spinner, form disabled
- **Success**: Dialog closes, success alert shown
- **Error**: Error alert shown, form remains open for corrections

### Campaign List Display

**List Layout:**
```
┌─────────────────────────────────────────────────────────┐
│ API campaigns                    [ Create campaign ]     │
├─────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Campaign Title                          [🗑️ Delete] │ │
│ │ Campaign message content...                         │ │
│ │ Sent from: API Inbox Name                           │ │
│ │ on: Oct 5, 2025 2:30 PM                             │ │
│ │ Status: Scheduled / Completed                       │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ ...                                                 │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

**Campaign Card Information:**
- Title (bold)
- Message content (truncated if long)
- Inbox name ("Sent from: {inbox_name}")
- Scheduled time ("on: {formatted_datetime}")
- Status badge (Scheduled/Completed)
- Delete action (confirmation dialog)

### Empty State

**Empty State Display:**
```
┌─────────────────────────────────────────────────────────┐
│ API campaigns                    [ Create campaign ]     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│               [Empty State Icon]                         │
│                                                          │
│        No API campaigns are available                    │
│                                                          │
│   Launch an API campaign to reach your customers         │
│   directly. Send custom messages through your API        │
│   integration. Click 'Create campaign' to get started.   │
│                                                          │
│   [Sample Campaign Card - Visual Reference]              │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Empty State Features:**
- Friendly title and subtitle
- Instructional text
- Sample campaign cards for visual reference
- Call-to-action to create first campaign

### Styling Guidelines

**Tailwind CSS Classes Used:**
- Form wrapper: `flex flex-col gap-4`
- Labels: `mb-0.5 text-sm font-medium text-n-slate-12`
- Buttons: Custom Button component with variants
- Dialog: `w-[25rem] z-50 min-w-0 absolute top-10 ltr:right-0 rtl:left-0 bg-n-alpha-3 backdrop-blur-[100px] p-6 rounded-xl border border-slate-50 dark:border-slate-900 shadow-md`
- Empty state: `pt-14`
- Loading spinner: `flex items-center justify-center py-10 text-n-slate-11`

**Component Library:**
- Input (components-next)
- TextArea (components-next)
- Button (components-next)
- ComboBox (components-next)
- TagMultiSelectComboBox (components-next)
- Spinner (components-next)

---

## Testing Strategy

### Frontend Tests (Vitest)

#### APICampaignForm.spec.js
**Location:** `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/APICampaign/APICampaignForm.spec.js`

**Coverage:**
- Component renders correctly
- Form fields display with proper stubs
- Audience options computed correctly from labels
- Inbox options computed correctly from API inboxes
- Form validation works (Vuelidate integration)
- Submit disabled when form invalid
- Submit enabled when form valid
- Form emits submit event with correct payload
- Cancel emits cancel event
- Form resets after successful submission
- DateTime validation (future time only)
- Character count for message field

**Test Approach:**
```javascript
// Mocks
- useMapGetter (campaigns/getUIFlags, labels/getLabels, inboxes/getAPIInboxes)
- useI18n

// Stubs
- Input, TextArea, Button, ComboBox, TagMultiSelectComboBox

// Test Cases
- Rendering
- Computed properties
- Validation
- Event emission
- State management
```

#### APICampaignsPage.spec.js
**Location:** `app/javascript/dashboard/campaigns/pages/APICampaignsPage.spec.js`

**Coverage:**
- Page renders correctly
- Shows spinner when loading
- Shows campaign list when campaigns exist
- Shows empty state when no campaigns
- Filters campaigns to API type only
- Opens dialog on create click
- Handles campaign deletion
- Confirmation dialog integration

### Backend Tests (RSpec)

#### oneoff_api_campaign_service_spec.rb
**Location:** `spec/services/api/oneoff_api_campaign_service_spec.rb`

**Coverage (146 lines):**

**Valid Campaign Tests:**
- ✓ Marks campaign as completed
- ✓ Creates contact inbox and conversation for each contact
- ✓ Creates conversation with correct attributes
- ✓ Creates message in conversation with campaign content
- ✓ Creates contact inbox with generated UUID source_id

**Error Handling:**
- ✓ Raises error when campaign already completed
- ✓ Raises error when inbox is not API type
- ✓ Handles contact inbox creation failure gracefully
- ✓ Handles conversation creation failure gracefully
- ✓ Continues processing remaining contacts on individual failures

**Multi-contact Tests:**
- ✓ Creates conversations for all matching contacts
- ✓ Each contact receives exactly one message

**Logging:**
- ✓ Logs successful conversation creation
- ✓ Logs errors when conversation creation fails

**Test Setup:**
```ruby
let(:account) { create(:account) }
let(:api_channel) { create(:channel_api, account: account) }
let(:api_inbox) { create(:inbox, channel: api_channel, account: account) }
let(:contact) { create(:contact, account: account) }
let(:label) { create(:label, account: account) }
let(:campaign) do
  create(:campaign,
    account: account,
    inbox: api_inbox,
    audience: [{ 'type' => 'Label', 'id' => label.id }]
  )
end
```

#### oneoff_whatsapp_campaign_service_spec.rb
**Location:** `spec/services/whatsapp/oneoff_whatsapp_campaign_service_spec.rb`

**Coverage (114 lines):**

**Valid Campaign Tests:**
- ✓ Marks campaign as completed
- ✓ Sends message to contacts with phone numbers
- ✓ Skips contacts without phone numbers
- ✓ Sends message with correct content
- ✓ Creates proper message object structure for WhatsApp provider

**Error Handling:**
- ✓ Raises error when campaign already completed
- ✓ Raises error when inbox is not WhatsApp type

**Multi-contact Tests:**
- ✓ Sends messages to all contacts with phone numbers
- ✓ Correct count of messages sent

### Key Test Scenarios

1. **Happy Path:**
   - Create campaign with valid data
   - Campaign executes at scheduled time
   - All targeted contacts receive messages
   - Campaign marked as completed

2. **Validation:**
   - Required fields enforced
   - Future time validation
   - API inbox type validation
   - Campaign type validation

3. **Error Handling:**
   - Duplicate execution prevented (completed check)
   - Invalid inbox type rejected
   - Individual contact failures don't stop campaign
   - Errors logged appropriately

4. **Edge Cases:**
   - No contacts match audience labels (campaign completes with no messages)
   - Contact inbox already exists (finds existing)
   - Multiple contacts with same labels (each gets one message)
   - Contacts without phone numbers (WhatsApp only - skipped)

5. **Integration:**
   - Store actions dispatch correctly
   - Analytics events tracked
   - Webhook notifications sent
   - UI updates after CRUD operations

---

## Internationalization

### Supported Languages

- **English (en)** - Complete
- **Portuguese (pt_BR)** - Complete

### Translation Structure

**Frontend Translations:**
**Location:**
- `app/javascript/dashboard/i18n/locale/en/campaign.json`
- `app/javascript/dashboard/i18n/locale/pt_BR/campaign.json`

**Translation Keys:**
```json
{
  "CAMPAIGN": {
    "API": {
      "HEADER_TITLE": "API campaigns",
      "NEW_CAMPAIGN": "Create campaign",
      "EMPTY_STATE": {
        "TITLE": "No API campaigns are available",
        "SUBTITLE": "Launch an API campaign to reach..."
      },
      "CARD": {
        "STATUS": {
          "COMPLETED": "Completed",
          "SCHEDULED": "Scheduled"
        },
        "CAMPAIGN_DETAILS": {
          "SENT_FROM": "Sent from",
          "ON": "on"
        }
      },
      "CREATE": {
        "TITLE": "Create API campaign",
        "FORM": {
          "TITLE": {
            "LABEL": "Title",
            "PLACEHOLDER": "Please enter the title of campaign",
            "ERROR": "Title is required"
          },
          "MESSAGE": { ... },
          "INBOX": { ... },
          "AUDIENCE": { ... },
          "SCHEDULED_AT": { ... },
          "BUTTONS": {
            "CREATE": "Create",
            "CANCEL": "Cancel"
          },
          "API": {
            "SUCCESS_MESSAGE": "API campaign created successfully",
            "ERROR_MESSAGE": "There was an error. Please try again."
          }
        }
      }
    }
  }
}
```

### Settings Navigation

**Location:**
- `app/javascript/dashboard/i18n/locale/en/settings.json`
- `app/javascript/dashboard/i18n/locale/pt_BR/settings.json`

**New Keys:**
```json
{
  "API_CAMPAIGNS": "API Campaigns"
}
```

### Adding New Languages

To add support for additional languages:

1. **Frontend:** Do NOT add new language files directly
   - Chatwoot uses Crowdin for community translations
   - Only update English (`en.json`) in this repository
   - Crowdin will sync translations to other languages

2. **Backend:** Update only `config/locales/en.yml`
   - Other locales managed by community via Crowdin

---

## Data Model

### Campaign Table Schema

```sql
CREATE TABLE campaigns (
  id BIGSERIAL PRIMARY KEY,
  account_id BIGINT NOT NULL REFERENCES accounts(id),
  inbox_id BIGINT NOT NULL REFERENCES inboxes(id),
  title VARCHAR NOT NULL,
  message TEXT NOT NULL,
  campaign_type INTEGER NOT NULL DEFAULT 0, -- 0: ongoing, 1: one_off
  campaign_status INTEGER NOT NULL DEFAULT 0, -- 0: active, 1: completed
  audience JSONB,
  scheduled_at TIMESTAMP,
  display_id INTEGER NOT NULL,
  sender_id INTEGER REFERENCES users(id),
  enabled BOOLEAN DEFAULT TRUE,
  trigger_only_during_business_hours BOOLEAN DEFAULT FALSE,
  trigger_rules JSONB,
  template_params JSONB,
  description TEXT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX index_campaigns_on_account_id ON campaigns(account_id);
CREATE INDEX index_campaigns_on_inbox_id ON campaigns(inbox_id);
CREATE INDEX index_campaigns_on_campaign_status ON campaigns(campaign_status);
CREATE INDEX index_campaigns_on_campaign_type ON campaigns(campaign_type);
CREATE INDEX index_campaigns_on_scheduled_at ON campaigns(scheduled_at);
```

### Audience JSON Structure

```json
[
  {
    "type": "Label",
    "id": 1
  },
  {
    "type": "Label",
    "id": 2
  }
]
```

**Design Notes:**
- Extensible for future audience types (e.g., Segment, Custom Attribute)
- Array allows multiple audience criteria
- Type field enables polymorphic audience targeting

### Relationships

```
Campaign
  ├── belongs_to :account
  ├── belongs_to :inbox
  ├── belongs_to :sender (User, optional)
  └── has_many :conversations
```

---

## Security & Access Control

### Authorization

**Role Requirements:**
- Only **administrators** can access campaign features
- Enforced at route level via `permissions: ['administrator']` in route meta

### Multi-tenancy

- All campaigns scoped to account
- Contacts filtered by campaign account
- Inboxes must belong to same account as campaign
- Validation: `inbox_must_belong_to_account`

### Data Validation

**Model Validations:**
```ruby
validates :account_id, presence: true
validates :inbox_id, presence: true
validates :title, presence: true
validates :message, presence: true
validate :validate_campaign_inbox
validate :sender_must_belong_to_account
validate :inbox_must_belong_to_account
validate :prevent_completed_campaign_from_update
```

**Inbox Type Validation:**
- Only specific inbox types allowed: Website, Twilio SMS, Sms, Whatsapp, API
- Prevents campaigns on unsupported channels

**Completed Campaign Protection:**
- Completed campaigns cannot be updated
- Prevents accidental modification of historical data

---

## Performance Considerations

### Background Processing

- Campaign execution runs in background jobs (Sidekiq)
- Prevents blocking web requests during campaign processing
- Large campaigns process contacts sequentially without overwhelming system

### Database Indexing

- Indexed fields: `account_id`, `inbox_id`, `campaign_status`, `campaign_type`, `scheduled_at`
- Optimizes queries for:
  - Finding campaigns by account
  - Finding campaigns by status
  - Finding scheduled campaigns due for execution
  - Campaign list filtering

### Contact Query Optimization

```ruby
# Efficient label matching
contacts = campaign.account.contacts.tagged_with(audience_labels, any: true)
```

- Uses ActsAsTaggableOn optimized queries
- Single query to find all matching contacts
- `any: true` uses OR logic for better flexibility

### Error Handling Strategy

- Individual contact failures don't stop campaign
- Errors logged for debugging
- Campaign marked completed even if some contacts fail
- Prevents retry loops on permanent failures

---

## Monitoring & Observability

### Logging

**Success Logging:**
```ruby
Rails.logger.info "[API Campaign] Created conversation #{conversation&.id} for contact #{contact.id} in campaign #{campaign.id}"
```

**Error Logging:**
```ruby
Rails.logger.error "[API Campaign] Failed to create conversation for contact #{contact.id}: #{e.message}"
```

**Log Searchability:**
- Consistent prefix: `[API Campaign]`
- Includes key IDs: conversation, contact, campaign
- Error context included in message

### Analytics Events

**Campaign Creation:**
```javascript
useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
  type: CAMPAIGN_TYPES.ONE_OFF,
});
```

**Tracked Metrics:**
- Campaign creation events
- Campaign type distribution
- Potential for future: execution success rate, contact reach, conversion metrics

### Webhook Integration

- Conversation creation triggers webhook events
- External systems notified of campaign-triggered conversations
- Enables custom reporting and analytics in external systems

---

## Future Enhancements

### Potential Extensions

1. **Advanced Scheduling**
   - Recurring campaigns
   - Timezone-aware scheduling
   - Business hours enforcement
   - Smart send time optimization

2. **Enhanced Targeting**
   - Custom attribute filters
   - Segment-based targeting
   - Exclude lists
   - Contact limit per campaign

3. **Template Support**
   - Message templates with variables
   - Multi-language templates
   - Rich media support (images, files)
   - Template preview before send

4. **Analytics & Reporting**
   - Campaign performance dashboard
   - Delivery rate tracking
   - Response rate metrics
   - A/B testing support

5. **Campaign Management**
   - Draft campaigns
   - Campaign duplication
   - Campaign editing (before execution)
   - Bulk campaign operations

6. **Channel Expansion**
   - Email campaigns
   - Social media campaigns
   - In-app notifications
   - SMS with link tracking

7. **Delivery Optimization**
   - Rate limiting
   - Batch processing controls
   - Retry logic for failures
   - Priority queuing

8. **User Experience**
   - Campaign preview
   - Test send functionality
   - Campaign history view
   - Better status tracking (queued, processing, completed, failed)

9. **Integration Features**
   - CRM integration for audience sync
   - Marketing automation platform hooks
   - Custom webhook payloads
   - API endpoints for external campaign creation

10. **Compliance Features**
    - Opt-out list management
    - GDPR compliance tools
    - Message approval workflow
    - Audit logging

---

## Related Documentation

- **Campaign Model:** `app/models/campaign.rb`
- **Campaigns Store:** `app/javascript/dashboard/store/modules/campaigns.js`
- **Frontend Components:** `app/javascript/dashboard/components-next/Campaigns/`
- **Backend Services:** `app/services/`
- **Test Files:** `spec/services/` and `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/APICampaign/*.spec.js`

---

## Implementation Checklist

- [x] Frontend form component with validation
- [x] Frontend page component with list/empty states
- [x] Frontend dialog integration
- [x] Frontend routing
- [x] Frontend store getters for API inboxes
- [x] Backend API campaign service
- [x] Backend WhatsApp campaign service
- [x] Campaign model updates for API channel support
- [x] Internationalization (English, Portuguese)
- [x] Frontend tests (Vitest)
- [x] Backend tests (RSpec)
- [x] Sidebar navigation integration
- [x] Empty state component
- [x] Delete confirmation dialog
- [x] Analytics event tracking
- [x] Error handling and logging
- [x] Documentation

---

## Conclusion

The API Campaign feature provides a comprehensive solution for targeted, scheduled messaging through API channels in Chatwoot. With robust validation, multi-channel support, extensive testing, and thoughtful error handling, this feature enables administrators to engage customers proactively while maintaining system performance and reliability.

**Extension: Message Delay (EXT-001) - Completed October 4, 2025**

The campaign feature has been enhanced with configurable message delays to prevent rate limiting and improve deliverability:
- Three delay types: none (immediate), fixed (constant), or random (range-based)
- Uses existing `trigger_rules` jsonb column (no migration required)
- Fully tested with 107 passing tests (80 backend + 27 frontend)
- Production ready with English and Portuguese translations
- Delay display in UI deferred to future iteration

**Enhancement: Increased Message Character Limit - October 4, 2025**

The campaign message field limit has been increased from 200 to 150,000 characters:
- Frontend: Added `:max-length="150000"` to TextArea component
- Backend: Added `Limits::CAMPAIGN_MESSAGE_MAX_LENGTH` constant (150,000)
- Backend validation: `validates :message, length: { maximum: Limits::CAMPAIGN_MESSAGE_MAX_LENGTH }`
- Matches Message model's content limit for consistency
- No database migration required (TEXT column supports this)
- Fully backward compatible with existing campaigns
- 3 new RSpec tests added for message length validation
- Character counter remains visible to users

The extensible architecture (service-based, channel-agnostic) positions the feature well for future enhancements such as template support, advanced targeting, and additional channel types.
