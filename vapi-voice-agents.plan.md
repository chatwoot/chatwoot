<!-- 1dddcdfe-83ec-497f-9cdc-bf14cdc82531 ba3b0821-f6a0-4248-8d40-c132e00ea221 -->
# Vapi.ai Voice Agents Integration Plan

## Overview

Integrate Vapi.ai to enable AI voice agents that handle incoming phone calls, with transcripts logged as Chatwoot conversations. Voice agents are inbox-specific and tied to existing phone/Twilio inboxes.

## Architecture Decisions

### Integration Approach

- Voice agents configured per inbox (inbox-level, not account-level)
- Vapi API credentials stored in global ENV variables (`VAPI_API_KEY`, `VAPI_PHONE_NUMBER`, etc.)
- Use existing Chatwoot inbox + contact + conversation flow
- Vapi webhooks → create/update conversations with call transcripts
- Background jobs (Sidekiq) for async Vapi API calls

### Data Flow

1. **Inbound Call**: Vapi webhook → creates/finds contact → creates/continues conversation → logs transcript as messages
2. **Agent Assignment**: Vapi agents configured per inbox in new UI
3. **Conversation Linking**: Match calls to contacts by phone number, continue existing open conversations or create new ones

---

## Backend Implementation

### 1. Database Schema

**New Model: `VapiAgent`** (associates Vapi voice agents with inboxes)

Migration: `db/migrate/YYYYMMDDHHMMSS_create_vapi_agents.rb`

```ruby
create_table :vapi_agents do |t|
  t.references :inbox, null: false, foreign_key: true, index: true
  t.references :account, null: false, foreign_key: true, index: true
  t.string :vapi_agent_id, null: false  # Vapi's agent ID
  t.string :name, null: false
  t.string :phone_number  # Optional: dedicated number for this agent
  t.jsonb :settings, default: {}  # Store Vapi agent config
  t.boolean :active, default: true
  t.timestamps
end
add_index :vapi_agents, :vapi_agent_id
```

**Migration to add Vapi call metadata to conversations**

Migration: `db/migrate/YYYYMMDDHHMMSS_add_vapi_metadata_to_conversations.rb`

```ruby
# Store call_id, duration, recording_url in additional_attributes
# No schema change needed - use existing additional_attributes jsonb column
```

### 2. Models

**`app/models/vapi_agent.rb`**

```ruby
class VapiAgent < ApplicationRecord
  belongs_to :inbox
  belongs_to :account
  
  validates :inbox_id, presence: true
  validates :account_id, presence: true
  validates :vapi_agent_id, presence: true, uniqueness: true
  validates :name, presence: true
  
  # Validate that inbox belongs to account
  validate :inbox_belongs_to_account
  
  private
  
  def inbox_belongs_to_account
    return unless inbox && account
    errors.add(:inbox, 'must belong to the account') unless inbox.account_id == account_id
  end
end
```

**Update `app/models/inbox.rb`**

```ruby
# Add association
has_one :vapi_agent, dependent: :destroy_async

# Add helper method
def vapi?
  vapi_agent.present? && vapi_agent.active?
end
```

### 3. Services

**`app/services/vapi/incoming_call_service.rb`**

- Handles incoming Vapi webhooks (call start, transcript updates, call end)
- Finds/creates contact by phone number
- Finds/creates conversation (reuses open conversation if exists)
- Creates messages with transcript content
- Stores call metadata (duration, recording URL) in `conversation.additional_attributes`

**`app/services/vapi/agent_sync_service.rb`**

- Fetches available Vapi agents from API
- Syncs agent configurations to Chatwoot

**`app/services/vapi/api_client.rb`**

- Wrapper for Vapi REST API calls
- Uses `VAPI_API_KEY` from ENV
- Methods: `list_agents`, `get_agent`, `create_agent`, `update_agent`

### 4. Jobs

**`app/jobs/vapi/call_events_job.rb`**

```ruby
class Vapi::CallEventsJob < ApplicationJob
  queue_as :default
  
  def perform(payload)
    Vapi::IncomingCallService.new(params: payload).perform
  end
end
```

### 5. Controllers

**`app/controllers/api/v1/accounts/vapi_agents_controller.rb`**

- Standard CRUD for VapiAgent
- Actions: `index`, `show`, `create`, `update`, `destroy`
- `GET /sync_agents` - fetches available agents from Vapi API

**`app/controllers/webhooks/vapi_controller.rb`**

- Receives Vapi webhooks
- Validates webhook signature (if Vapi provides one)
- Enqueues `Vapi::CallEventsJob`

Route: `POST /webhooks/vapi`

### 6. Routes

**`config/routes.rb`**

```ruby
# Inside api/v1/accounts scope
resources :vapi_agents, only: [:index, :show, :create, :update, :destroy] do
  collection do
    get :sync_agents
  end
end

# Webhook endpoint (outside account scope)
post 'webhooks/vapi', to: 'webhooks/vapi#process_payload'
```

---

## Frontend Implementation

### 1. New Top-Level Menu Item

**Update: `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`**

Add Voice Agents menu item to `menuItems` computed property (around line 355, after Portals):

```javascript
{
  name: 'VoiceAgents',
  label: t('SIDEBAR.VOICE_AGENTS'),
  icon: 'i-lucide-phone-call',  // or 'i-lucide-mic'
  to: accountScopedRoute('vapi_agents_index'),
}
```

### 2. Routes

**New file: `app/javascript/dashboard/routes/dashboard/voiceAgents/voiceAgents.routes.js`**

```javascript
import { frontendURL } from '../../../helper/URLHelper';
import SettingsContent from '../settings/Wrapper.vue';
import VoiceAgentsIndex from './Index.vue';
import VoiceAgentForm from './Form.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/voice-agents'),
      component: SettingsContent,
      props: {
        headerTitle: 'VOICE_AGENTS.HEADER',
        icon: 'phone-call',
        showBackButton: false,
      },
      children: [
        {
          path: '',
          name: 'vapi_agents_index',
          component: VoiceAgentsIndex,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'new',
          name: 'vapi_agents_new',
          component: VoiceAgentForm,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: ':id/edit',
          name: 'vapi_agents_edit',
          component: VoiceAgentForm,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
```

**Update: `app/javascript/dashboard/routes/dashboard/dashboard.routes.js`**

Import and add voiceAgents routes to children array.

### 3. Vuex Store Module

**New file: `app/javascript/dashboard/store/modules/vapiAgents.js`**

- State: `records`, `uiFlags`
- Actions: `get`, `show`, `create`, `update`, `delete`, `syncAgents`
- Getters: `getVapiAgents`, `getVapiAgentById`, `getUIFlags`
- API calls to `/api/v1/accounts/:accountId/vapi_agents`

**Update: `app/javascript/dashboard/store/index.js`**

Register `vapiAgents` module.

### 4. API Client

**New file: `app/javascript/dashboard/api/vapiAgents.js`**

```javascript
class VapiAgentsAPI extends ApiClient {
  constructor() {
    super('vapi_agents', { accountScoped: true });
  }
  
  syncAgents() {
    return axios.get(`${this.url}/sync_agents`);
  }
}
```

### 5. Vue Components

**`app/javascript/dashboard/routes/dashboard/voiceAgents/Index.vue`**

- List all voice agents with table/cards
- Show: agent name, associated inbox, phone number, status (active/inactive)
- Actions: Edit, Delete, Toggle Active
- "Sync from Vapi" button (calls API to fetch Vapi agents)
- "New Voice Agent" button
- Use Tailwind for styling

**`app/javascript/dashboard/routes/dashboard/voiceAgents/Form.vue`**

- Form to create/edit voice agent
- Fields:
  - Name (text input)
  - Inbox (dropdown - select from account inboxes)
  - Vapi Agent ID (text input or dropdown if synced)
  - Phone Number (optional text input)
  - Active (toggle)
  - Settings (JSON editor or structured form for Vapi config)
- Save/Cancel buttons

**`app/javascript/dashboard/routes/dashboard/voiceAgents/components/AgentCard.vue`** (optional)

- Reusable card component for displaying agent info

### 6. i18n Translations

**Update: `app/javascript/dashboard/i18n/locale/en/settings.json`**

Add to SIDEBAR section:

```json
"VOICE_AGENTS": "Voice Agents"
```

**New file: `app/javascript/dashboard/i18n/locale/en/voiceAgents.json`**

```json
{
  "VOICE_AGENTS": {
    "HEADER": "Voice Agents",
    "LIST": {
      "TITLE": "Voice Agents",
      "DESCRIPTION": "Manage Vapi.ai voice agents for your inboxes",
      "EMPTY_STATE": "No voice agents configured",
      "SYNC_BUTTON": "Sync from Vapi"
    },
    "FORM": {
      "TITLE_NEW": "New Voice Agent",
      "TITLE_EDIT": "Edit Voice Agent",
      "NAME": "Agent Name",
      "INBOX": "Inbox",
      "VAPI_AGENT_ID": "Vapi Agent ID",
      "PHONE_NUMBER": "Phone Number",
      "ACTIVE": "Active",
      "SETTINGS": "Configuration"
    }
  }
}
```

---

## Call Flow & Message Handling

### Vapi Webhook Payload Structure

Expected webhook events from Vapi:

- `call.started` - Call initiated
- `call.transcript.updated` - Real-time transcript
- `call.ended` - Call completed (includes duration, recording URL)

### Message Creation Logic

**In `Vapi::IncomingCallService`:**

1. Parse webhook payload
2. Extract: `call_id`, `phone_number`, `transcript`, `duration`, `recording_url`
3. Find inbox by `vapi_agent_id` (from webhook or phone number)
4. Find/create contact using `ContactInboxWithContactBuilder`
5. Find/create conversation:

   - If `inbox.lock_to_single_conversation` → use last conversation
   - Else → use last non-resolved conversation, or create new

6. Create message(s):

   - For `call.started`: activity message "Call started"
   - For `call.transcript.updated`: incoming message with transcript chunks
   - For `call.ended`: activity message "Call ended - Duration: X min" + store recording URL

---

## Configuration & Environment Variables

**Required ENV variables:**

```bash
# Add to .env file (user needs to configure)
VAPI_API_KEY=your_vapi_api_key
VAPI_WEBHOOK_SECRET=your_webhook_secret  # For signature verification
```

**Update `.env.example` with these variables**

---

## Testing Considerations

### Backend

- **Models**: Validate associations, uniqueness constraints
- **Services**: Test `Vapi::IncomingCallService` with various webhook payloads
- **Controllers**: Test CRUD operations, permissions
- **Jobs**: Test async processing of webhooks

### Frontend

- **Components**: Test form validation, list rendering
- **Store**: Test actions, mutations, getters
- **Routes**: Test navigation, permissions

---

## Security & Permissions

- Voice Agents management restricted to **administrators only**
- Webhook endpoint validates Vapi signature (if available)
- API endpoints use existing Chatwoot authentication/authorization
- Store API keys in ENV (never in database or frontend)

---

## Enterprise Compatibility

### Check Enterprise Overrides

Before implementing, search for:

```bash
rg -n "Inbox|VoiceAgent|Vapi" app enterprise
```

- Ensure no conflicts with enterprise voice features
- If `enterprise/app/models/channel/voice.rb` exists, coordinate integration
- Add extension points if needed (`prepend_mod_with`)

---

## Deployment & Migration

1. Run migrations: `bundle exec rails db:migrate`
2. Add ENV variables to production environment
3. Restart Rails server and Sidekiq workers
4. Configure Vapi webhook URL in Vapi dashboard: `https://your-domain.com/webhooks/vapi`
5. Test with a sample call

---

## Future Enhancements (Out of Scope)

- Outbound call initiation from Chatwoot
- Real-time call monitoring dashboard
- Call analytics/reporting
- Agent performance metrics
- Multi-language support for transcripts
- Voice agent templates

### To-dos

- [x] Create VapiAgent model, migration, and update Inbox model with association
- [x] Implement Vapi services (IncomingCallService, ApiClient, AgentSyncService)
- [x] Create VapiAgents controller and Vapi webhook controller with routes
- [x] Create voice agents routes and integrate into dashboard navigation
- [x] Implement Vuex store module and API client for voice agents
- [x] Build Vue components (Index, Form) with Tailwind styling
- [x] Add English translations for voice agents UI
- [x] Add Voice Agents menu item to main sidebar
- [x] Test end-to-end flow: webhook → conversation creation → UI display