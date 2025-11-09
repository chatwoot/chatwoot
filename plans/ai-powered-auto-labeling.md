# AI-Powered Auto-Labeling for Conversations - Implementation Plan

## Quick Reference

**What**: Automatically label conversations using AI after configurable message threshold
**How**: OpenAI gpt-4o-mini with structured JSON outputs
**API Key**: Global ENV variable (`OPENAI_API_KEY`)
**Files to Create**: 3 backend (service, job, listener) + 1 frontend (Vue component)
**Files to Update**: 5 frontend + 1 config + 1 env
**Effort**: 3-5 days

---

## Overview

This plan details the implementation of an AI-powered automatic labeling feature for conversations. The system will analyze conversation messages using OpenAI's LLM and automatically apply relevant labels based on configurable thresholds.

**Key Innovation**: Uses OpenAI's structured outputs (JSON schema) to prevent label hallucinations by enforcing an enum constraint based on existing labels in the database.

### Feature Specifications

- **Scope**: Global account setting (applies to all labels)
- **Trigger**: Configurable message threshold (default: 3 messages)
- **Edition**: Open-source (available to all users)
- **Error Handling**: Retry with exponential backoff (3 attempts)
- **OpenAI Integration**: Uses global API key from ENV (OPENAI_API_KEY)
- **Response Format**: Structured JSON outputs using openai-ruby gem

### Prerequisites

Before implementation, ensure:

1. **OpenAI Ruby Gem**: Verify `gem 'ruby-openai'` is in Gemfile
2. **API Key**: Obtain OpenAI API key from https://platform.openai.com/api-keys
3. **ENV Configuration**: Add `OPENAI_API_KEY=sk-proj-...` to `.env` file
4. **Permissions**: Ensure API key has access to gpt-4o-mini model
5. **Testing**: Have test API key for development/staging environments

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│  Labels Settings Page                               │
│  ├─ Toggle: "Enable AI Auto-Labeling"              │
│  └─ Input: "Message Threshold" (1-10)              │
└─────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│  Event: message_created                             │
│  └─ AutoLabelListener.message_created               │
└─────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│  Validation Checks:                                 │
│  ✓ auto_label_enabled = true                       │
│  ✓ message count >= threshold                      │
│  ✓ conversation has no labels                      │
│  ✓ OPENAI_API_KEY present in ENV                   │
└─────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│  Labels::AutoLabelJob.perform_later                 │
│  └─ Async background job with retry logic          │
└─────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│  Labels::AutoLabelService.new(conversation).perform │
└─────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│  Labels::OpenaiClassifierService                    │
│  └─ Uses openai-ruby with structured outputs       │
│  └─ Returns: { labels: ["support", "billing"] }    │
└─────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│  conversation.add_labels(suggested_labels)          │
│  └─ Creates activity message & dispatches events   │
└─────────────────────────────────────────────────────┘
```

---

## Implementation Steps

### Phase 1: Backend Foundation

#### Step 1.1: Create Auto Label Service

**File**: `app/services/labels/auto_label_service.rb`

**Purpose**: Core business logic for automatic label assignment

**Implementation**:

```ruby
# frozen_string_literal: true

class Labels::AutoLabelService
  pattr_initialize [:conversation!]

  def perform
    return unless auto_label_enabled?
    return unless openai_api_key_present?
    return if conversation.label_list.any?

    suggested_labels = fetch_label_suggestions
    return if suggested_labels.blank?

    apply_labels(suggested_labels)
    Rails.logger.info("Auto-labeled conversation #{conversation.id} with: #{suggested_labels.join(', ')}")
  rescue StandardError => e
    Rails.logger.error("Auto-labeling failed for conversation #{conversation.id}: #{e.message}")
    raise # Re-raise for job retry
  end

  private

  def auto_label_enabled?
    account.settings.dig('auto_label_enabled') == true
  end

  def openai_api_key_present?
    ENV['OPENAI_API_KEY'].present?
  end

  def fetch_label_suggestions
    classifier = Labels::OpenaiClassifierService.new(
      conversation: conversation,
      account: account
    )

    result = classifier.suggest_labels
    result[:labels] || []
  end

  def apply_labels(label_names)
    conversation.add_labels(label_names)
  end

  def account
    @account ||= conversation.account
  end
end
```

**Key Points**:
- Uses `pattr_initialize` pattern (existing Chatwoot convention)
- Checks if auto-labeling is enabled in account settings
- Validates ENV['OPENAI_API_KEY'] is present
- Skips if conversation already has labels
- Uses new OpenaiClassifierService for structured outputs
- Applies labels using existing `add_labels` method
- Logs success/failure for debugging
- Re-raises errors for job retry mechanism

---

#### Step 1.2: Create Auto Label Background Job

**File**: `app/jobs/labels/auto_label_job.rb`

**Purpose**: Async execution with retry logic

**Implementation**:

```ruby
# frozen_string_literal: true

class Labels::AutoLabelJob < ApplicationJob
  queue_as :default

  # Retry 3 times with exponential backoff: 3s, 9s, 27s
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(conversation_id)
    conversation = Conversation.find_by(id: conversation_id)
    return unless conversation

    Labels::AutoLabelService.new(conversation: conversation).perform
  end
end
```

**Key Points**:
- Uses `ApplicationJob` base class
- Queue: `default` (can be changed to `low` if needed)
- Retry strategy: exponential backoff, 3 attempts
- Gracefully handles missing conversations
- Simple delegation to service object

---

#### Step 1.3: Create Auto Label Event Listener

**File**: `app/listeners/auto_label_listener.rb`

**Purpose**: Listen to message_created events and trigger auto-labeling

**Implementation**:

```ruby
# frozen_string_literal: true

class AutoLabelListener < BaseListener
  def message_created(event)
    message = event.data[:message]
    conversation = message.conversation

    return unless should_auto_label?(conversation, message)

    Labels::AutoLabelJob.perform_later(conversation.id)
  end

  private

  def should_auto_label?(conversation, message)
    return false unless message.incoming?
    return false unless auto_label_enabled?(conversation.account)
    return false if conversation.label_list.any?
    return false unless threshold_met?(conversation)

    true
  end

  def auto_label_enabled?(account)
    account.settings.dig('auto_label_enabled') == true
  end

  def threshold_met?(conversation)
    threshold = conversation.account.settings.dig('auto_label_message_threshold') || 3
    conversation.messages.incoming.count >= threshold
  end
end
```

**Key Points**:
- Inherits from `BaseListener` (existing Chatwoot pattern)
- Subscribes to `message_created` event
- Only processes incoming messages (not outgoing)
- Checks if auto-labeling is enabled
- Validates conversation has no existing labels
- Checks if message count threshold is met
- Enqueues background job asynchronously

---

#### Step 1.4: Create OpenAI Classifier Service with Structured Outputs

**File**: `app/services/labels/openai_classifier_service.rb`

**Purpose**: Direct OpenAI integration using global API key with structured JSON outputs

**Implementation**:

```ruby
# frozen_string_literal: true

class Labels::OpenaiClassifierService
  pattr_initialize [:conversation!, :account!]

  def suggest_labels
    return { labels: [] } unless should_process?

    response = call_openai_api
    parse_response(response)
  rescue StandardError => e
    Rails.logger.error("OpenAI label classification failed: #{e.message}")
    { labels: [] }
  end

  private

  def should_process?
    return false unless ENV['OPENAI_API_KEY'].present?
    return false if conversation.messages.incoming.count < 3
    return false if conversation.messages.count > 100
    return false if available_labels.empty?

    true
  end

  def call_openai_api
    client.chat(
      parameters: {
        model: 'gpt-4o-mini',
        messages: build_messages,
        temperature: 0.3,
        response_format: {
          type: 'json_schema',
          json_schema: {
            name: 'label_classification',
            strict: true,
            schema: response_schema
          }
        }
      }
    )
  end

  def build_messages
    [
      { role: 'system', content: system_prompt },
      *conversation_messages
    ]
  end

  def system_prompt
    <<~PROMPT
      You are a customer support conversation classifier. Your task is to analyze the conversation
      and select the most relevant labels from the provided list.

      Available labels: #{available_labels.join(', ')}

      Rules:
      - Select up to 2 most relevant labels
      - Use EXACT label names from the available list (preserve casing)
      - Return empty array if no labels match well
      - Base your decision on the conversation content and context
    PROMPT
  end

  def conversation_messages
    # Get last 20 messages to stay within token limits
    messages = conversation.messages.chat.last(20)

    messages.map do |message|
      {
        role: message.incoming? ? 'user' : 'assistant',
        content: message.content || ''
      }
    end
  end

  def response_schema
    {
      type: 'object',
      properties: {
        labels: {
          type: 'array',
          description: 'Array of selected label names',
          items: {
            type: 'string',
            enum: available_labels
          },
          maxItems: 2
        },
        reasoning: {
          type: 'string',
          description: 'Brief explanation of why these labels were chosen (optional)'
        }
      },
      required: ['labels'],
      additionalProperties: false
    }
  end

  def parse_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    return { labels: [] } if content.blank?

    parsed = JSON.parse(content)
    {
      labels: parsed['labels'] || [],
      reasoning: parsed['reasoning']
    }
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse OpenAI response: #{e.message}")
    { labels: [] }
  end

  def available_labels
    @available_labels ||= account.labels.pluck(:title)
  end

  def client
    @client ||= OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end
end
```

**Key Points**:
- Uses `pattr_initialize` pattern for consistency
- Direct integration with openai-ruby gem
- Uses global ENV['OPENAI_API_KEY'] (no per-account hooks)
- **Structured Outputs**: JSON schema with strict validation
- Response schema enforces label enum (only valid labels)
- Returns structured hash: `{ labels: [...], reasoning: '...' }`
- Validates conversation has 3+ messages, <100 total
- Limits to last 20 messages for token efficiency
- Uses gpt-4o-mini for cost-effective classification
- Graceful error handling with logging
- Prevents hallucinated labels (enum constraint)

---

#### Step 1.5: Register Listener

**File**: `config/initializers/listeners.rb`

**Action**: Add AutoLabelListener to Rails dispatcher

**Implementation**:

```ruby
# Add to existing listeners array
Rails.configuration.dispatcher.subscribe(AutoLabelListener.instance)
```

**Location**: Add after existing listener registrations (around line 10-20)

---

### Phase 2: Frontend Implementation

#### Step 2.1: Create Auto Label Settings Component

**File**: `app/javascript/dashboard/routes/dashboard/settings/labels/AutoLabelSettings.vue`

**Purpose**: UI component for enabling/configuring auto-labeling

**Implementation**:

```vue
<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

const store = useStore();
const { t } = useI18n();

const autoLabelEnabled = ref(false);
const messageThreshold = ref(3);
const isUpdating = ref(false);

const account = computed(() => store.getters['accounts/getAccount']);

onMounted(() => {
  loadSettings();
});

const loadSettings = () => {
  const settings = account.value?.settings || {};
  autoLabelEnabled.value = settings.auto_label_enabled || false;
  messageThreshold.value = settings.auto_label_message_threshold || 3;
};

const updateSettings = async () => {
  isUpdating.value = true;
  try {
    await store.dispatch('accounts/updateSettings', {
      auto_label_enabled: autoLabelEnabled.value,
      auto_label_message_threshold: messageThreshold.value,
    });
    useAlert(t('LABEL_MGMT.AUTO_LABEL.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(t('LABEL_MGMT.AUTO_LABEL.UPDATE_FAILED'));
  } finally {
    isUpdating.value = false;
  }
};

const handleToggle = () => {
  updateSettings();
};

const handleThresholdChange = () => {
  if (autoLabelEnabled.value) {
    updateSettings();
  }
};
</script>

<template>
  <div class="mb-6 rounded-lg border border-slate-200 bg-white p-6">
    <div class="mb-4">
      <h3 class="text-lg font-semibold text-slate-900">
        {{ t('LABEL_MGMT.AUTO_LABEL.TITLE') }}
      </h3>
      <p class="mt-1 text-sm text-slate-600">
        {{ t('LABEL_MGMT.AUTO_LABEL.DESCRIPTION') }}
      </p>
    </div>

    <!-- Toggle Switch -->
    <div class="flex items-center">
      <label class="relative inline-flex cursor-pointer items-center">
        <input
          v-model="autoLabelEnabled"
          type="checkbox"
          class="peer sr-only"
          :disabled="isUpdating"
          @change="handleToggle"
        />
        <div
          class="peer h-6 w-11 rounded-full bg-slate-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-slate-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-woot-500 peer-checked:after:translate-x-full peer-checked:after:border-white peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-woot-300 peer-disabled:opacity-50"
        ></div>
        <span class="ml-3 text-sm font-medium text-slate-900">
          {{ t('LABEL_MGMT.AUTO_LABEL.ENABLE') }}
        </span>
      </label>
    </div>

    <!-- Threshold Configuration -->
    <div
      v-if="autoLabelEnabled"
      class="mt-4 border-t border-slate-200 pt-4"
    >
      <label
        for="message-threshold"
        class="block text-sm font-medium text-slate-700"
      >
        {{ t('LABEL_MGMT.AUTO_LABEL.THRESHOLD_LABEL') }}
      </label>
      <div class="mt-2 flex items-center gap-4">
        <input
          id="message-threshold"
          v-model.number="messageThreshold"
          type="number"
          min="1"
          max="10"
          class="block w-24 rounded-md border-slate-300 shadow-sm focus:border-woot-500 focus:ring-woot-500 sm:text-sm"
          :disabled="isUpdating"
          @change="handleThresholdChange"
        />
        <span class="text-sm text-slate-600">
          {{ t('LABEL_MGMT.AUTO_LABEL.THRESHOLD_HINT') }}
        </span>
      </div>
    </div>

    <!-- Info Message -->
    <div
      v-if="autoLabelEnabled"
      class="mt-4 rounded-md bg-blue-50 p-3"
    >
      <div class="flex">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-5 w-5 text-blue-400"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
        <p class="ml-3 text-sm text-blue-700">
          {{ t('LABEL_MGMT.AUTO_LABEL.INFO_MESSAGE') }}
        </p>
      </div>
    </div>
  </div>
</template>
```

**Key Points**:
- Uses Composition API with `<script setup>` (Chatwoot standard)
- Tailwind-only styling (no custom CSS)
- No OpenAI integration checks (uses global ENV key)
- Real-time settings update on toggle/change
- Threshold input with 1-10 range validation
- Visual feedback with info messages
- Disabled state during updates
- Simple toggle interface without complex validation

---

#### Step 2.2: Update Labels Index Page

**File**: `app/javascript/dashboard/routes/dashboard/settings/labels/Index.vue`

**Action**: Import and render AutoLabelSettings component

**Implementation**:

```vue
<script setup>
// ... existing imports
import AutoLabelSettings from './AutoLabelSettings.vue';
</script>

<template>
  <div class="flex-1 overflow-auto p-4">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="add-circle"
      @click="openAddPopup"
    >
      {{ $t('LABEL_MGMT.HEADER_BTN_TXT') }}
    </woot-button>

    <!-- ADD THIS COMPONENT HERE -->
    <AutoLabelSettings class="mb-6" />

    <!-- Existing labels table -->
    <div class="row">
      <!-- ... existing table code ... -->
    </div>

    <!-- ... rest of existing template ... -->
  </div>
</template>
```

**Location**: Add `<AutoLabelSettings />` component after the "Add Label" button and before the labels table

---

#### Step 2.3: Update Account API Client

**File**: `app/javascript/dashboard/api/account.js`

**Action**: Add method to update account settings

**Implementation**:

```javascript
// Add to existing methods
updateSettings(accountId, settings) {
  return axios.patch(`${this.url}/${accountId}`, {
    settings,
  });
},
```

**Location**: Add after existing CRUD methods (around line 20-30)

---

#### Step 2.4: Update Accounts Vuex Store

**File**: `app/javascript/dashboard/store/modules/accounts.js`

**Action**: Add action to update account settings

**Implementation**:

```javascript
const actions = {
  // ... existing actions

  updateSettings: async ({ commit }, settings) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: true });
    try {
      const accountId = window.chatwootConfig.accountId;
      const response = await AccountAPI.updateSettings(accountId, settings);
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
      commit(types.default.UPDATE_ACCOUNT_SETTINGS, response.data);
      return response.data;
    } catch (error) {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
      throw error;
    }
  },
};
```

**Also add mutation type**:

```javascript
// In store/mutation-types.js
export default {
  // ... existing types
  UPDATE_ACCOUNT_SETTINGS: 'UPDATE_ACCOUNT_SETTINGS',
};
```

**And mutation**:

```javascript
// In store/modules/accounts.js mutations
const mutations = {
  // ... existing mutations

  [types.default.UPDATE_ACCOUNT_SETTINGS]($state, accountData) {
    const account = $state.records.find(r => r.id === accountData.id);
    if (account) {
      Vue.set(account, 'settings', accountData.settings);
    }
  },
};
```

---

#### Step 2.5: Add i18n Translations

**File**: `app/javascript/dashboard/i18n/locale/en/labelsMgmt.json`

**Action**: Add auto-label translations

**Implementation**:

```json
{
  "HEADER": "Labels",
  "HEADER_BTN_TXT": "Add label",
  "LOADING": "Fetching labels",
  "AUTO_LABEL": {
    "TITLE": "AI-Powered Auto-Labeling",
    "DESCRIPTION": "Automatically assign labels to conversations using AI analysis based on conversation content and context.",
    "ENABLE": "Enable automatic labeling",
    "THRESHOLD_LABEL": "Minimum messages before auto-labeling",
    "THRESHOLD_HINT": "Wait for this many messages before applying labels",
    "UPDATE_SUCCESS": "Auto-label settings updated successfully",
    "UPDATE_FAILED": "Failed to update auto-label settings",
    "INFO_MESSAGE": "Labels will be automatically applied when conversations reach the message threshold. Only unlabeled conversations will be processed. Requires OPENAI_API_KEY to be configured."
  },
  "SEARCH_404": "There are no items matching this query",
  "LIST": {
    "404": "There are no labels available in this account.",
    "TITLE": "Manage labels",
    "DESC": "Labels let you categorize and prioritize conversations and leads. You can assign a label to a conversation or contact from the conversation sidebar.",
    "TABLE_HEADER": ["Name", "Description", "Color"]
  },
  // ... rest of existing translations
}
```

---

### Phase 3: Backend Controller Updates (Optional)

#### Step 3.1: Update Accounts Controller

**File**: `app/controllers/api/v1/accounts_controller.rb`

**Action**: Ensure settings updates are supported

**Implementation**:

Check if the controller already supports settings updates. If not, add:

```ruby
def update
  @account = current_user.accounts.find(params[:id])
  @account.update!(account_params)
  render json: @account, include: [:settings]
end

private

def account_params
  params.require(:account).permit(:name, :locale, :domain, :support_email, :auto_resolve_duration, settings: {})
end
```

**Note**: Most likely this already exists, just verify `settings: {}` is in permitted params.

---

### Phase 4: Testing & Validation

#### Manual Testing Checklist

1. **Settings UI**:
   - [ ] Navigate to Settings → Labels
   - [ ] Verify AutoLabelSettings component renders
   - [ ] Toggle auto-label on/off
   - [ ] Change message threshold (1-10)
   - [ ] Verify settings persist after page reload
   - [ ] Verify info message shows when enabled

2. **Auto-Labeling Behavior**:
   - [ ] Create new conversation
   - [ ] Send messages until threshold is met
   - [ ] Verify labels are automatically applied
   - [ ] Check conversation activity shows "System added labels"
   - [ ] Verify no labels applied if conversation already labeled

3. **Error Handling**:
   - [ ] Remove OPENAI_API_KEY from ENV
   - [ ] Verify auto-labeling doesn't crash
   - [ ] Check logs for graceful error messages
   - [ ] Restore API key and verify recovery
   - [ ] Test with invalid API key
   - [ ] Verify retry logic works (check Sidekiq)

4. **Edge Cases**:
   - [ ] Test with threshold = 1 (immediate labeling)
   - [ ] Test with threshold = 10
   - [ ] Test with no available labels in account
   - [ ] Test with 50+ labels (performance)
   - [ ] Test conversation with 100+ messages
   - [ ] Verify only existing labels are applied (no hallucinations)
   - [ ] Test with special characters in label names
   - [ ] Verify max 2 labels applied per conversation

5. **Performance**:
   - [ ] Monitor Sidekiq queue for job processing
   - [ ] Verify jobs complete within 10 seconds
   - [ ] Check for duplicate job enqueuing
   - [ ] Monitor OpenAI API latency

#### Integration Testing (Optional)

Create spec file: `spec/services/labels/auto_label_service_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe Labels::AutoLabelService do
  let(:account) { create(:account, settings: { 'auto_label_enabled' => true }) }
  let(:conversation) { create(:conversation, account: account) }
  let(:hook) { create(:integrations_hook, account: account, app_id: 'openai', status: 'enabled') }
  let(:service) { described_class.new(conversation: conversation) }

  describe '#perform' do
    context 'when auto-labeling is enabled' do
      it 'applies suggested labels to conversation' do
        # Test implementation
      end
    end

    context 'when auto-labeling is disabled' do
      it 'does not apply labels' do
        # Test implementation
      end
    end
  end
end
```

---

## Rollout Plan

### Phase 1: Setup & Backend (Day 1-2)
1. Verify `gem 'ruby-openai'` in Gemfile (run `bundle install` if needed)
2. Add OPENAI_API_KEY to `.env` file
3. Implement backend service (OpenaiClassifierService)
4. Implement auto label service, job, and listener
5. Register listener in initializers
6. Test OpenAI integration with curl/console

### Phase 2: Frontend (Day 2-3)
1. Create AutoLabelSettings component
2. Update Labels Index page
3. Add Vuex actions and API methods
4. Add i18n translations

### Phase 3: Testing (Day 3-4)
1. Manual testing with real OpenAI API
2. Test all edge cases
3. Performance testing with high message volume
4. Error scenario testing

### Phase 4: Documentation (Day 4)
1. Update user documentation
2. Add developer notes
3. Create migration guide (if needed)

### Phase 5: Deployment (Day 5)
1. Deploy to staging
2. Monitor logs and performance
3. Fix any issues
4. Deploy to production
5. Announce feature to users

---

## Configuration

### Environment Variables

Add to `.env` file:

```bash
# OpenAI API Key for AI-powered features
OPENAI_API_KEY=sk-proj-your-api-key-here
```

**Important**: This is a global API key used by all accounts/organizations. Ensure it's properly secured.

### Account Settings Schema

```json
{
  "auto_label_enabled": false,
  "auto_label_message_threshold": 3
}
```

Stored in `accounts.settings` JSONB column.

---

## Monitoring & Logging

### Log Messages

```ruby
# Success
Rails.logger.info("Auto-labeled conversation #{conversation.id} with: #{labels.join(', ')}")

# Failure
Rails.logger.error("Auto-labeling failed for conversation #{conversation.id}: #{error.message}")

# Skipped
Rails.logger.debug("Skipped auto-labeling for conversation #{conversation.id}: threshold not met")
```

### Metrics to Track

- Auto-labeling job execution time
- Success/failure rate
- Average labels per conversation
- OpenAI API latency
- Job retry rate

---

## Security Considerations

1. **API Key Protection**:
   - Global OpenAI API key stored in ENV (OPENAI_API_KEY)
   - Never expose in frontend code or API responses
   - Use environment-specific keys (dev, staging, production)
   - Rotate keys periodically

2. **Rate Limiting**:
   - Consider adding rate limits for OpenAI API calls
   - Monitor usage to prevent API quota exhaustion
   - Implement per-account rate limiting if needed

3. **Data Privacy**:
   - Conversation content sent to OpenAI API
   - Ensure compliance with GDPR/privacy regulations
   - Consider data residency requirements
   - Add disclaimer in UI about AI processing

4. **Permission Checks**:
   - Only account admins can enable/configure auto-labeling
   - Validate permissions in controller before settings updates

5. **Cost Management**:
   - Global API key means all accounts share quota/costs
   - Monitor OpenAI API usage and costs
   - Consider implementing usage limits per account

---

## Performance Optimization

### Current Optimizations

1. **Async Processing**: All labeling done in background jobs
2. **Message Limiting**: Only last 20 messages sent to OpenAI
3. **Conversation Filtering**: Skip conversations with 100+ messages
4. **Caching**: Reuse OpenAI client instance

### Future Optimizations (if needed)

1. **Batch Processing**: Process multiple conversations in single job
2. **Smart Caching**: Cache label suggestions for similar conversations
3. **Rate Limiting**: Throttle OpenAI API calls during high traffic
4. **Model Selection**: Use faster/cheaper models for simple cases

---

## Known Limitations

1. **OpenAI Dependency**: Feature requires OPENAI_API_KEY in environment
2. **Global API Key**: All accounts share same OpenAI API key and quota
3. **Message Threshold**: Cannot label conversations with fewer than 3 messages
4. **Already Labeled**: Won't re-label conversations that already have labels
5. **Token Limits**: Large conversations (100+ messages) are skipped
6. **Language Support**: Accuracy depends on OpenAI's language capabilities
7. **Cost Sharing**: All accounts share API usage costs (no per-account tracking)

---

## Future Enhancements

1. **Per-Label Toggle**: Enable/disable auto-labeling per individual label
2. **Confidence Scores**: Show AI confidence level for label suggestions
3. **Label Review**: Allow agents to review/approve AI labels before applying
4. **Custom Prompts**: Allow admins to customize AI prompting
5. **Alternative LLMs**: Support for Anthropic Claude, local models, etc.
6. **Analytics Dashboard**: Track auto-labeling performance and accuracy
7. **Manual Override**: Allow manual label changes to train the system

---

## File Checklist

### Backend Files (Ruby)

- [ ] `app/services/labels/auto_label_service.rb` - NEW
- [ ] `app/services/labels/openai_classifier_service.rb` - NEW (structured outputs)
- [ ] `app/jobs/labels/auto_label_job.rb` - NEW
- [ ] `app/listeners/auto_label_listener.rb` - NEW
- [ ] `config/initializers/listeners.rb` - UPDATE (register listener)
- [ ] `app/controllers/api/v1/accounts_controller.rb` - VERIFY (settings support)
- [ ] `.env` - UPDATE (add OPENAI_API_KEY)

### Frontend Files (Vue/JS)

- [ ] `app/javascript/dashboard/routes/dashboard/settings/labels/AutoLabelSettings.vue` - NEW
- [ ] `app/javascript/dashboard/routes/dashboard/settings/labels/Index.vue` - UPDATE
- [ ] `app/javascript/dashboard/api/account.js` - UPDATE
- [ ] `app/javascript/dashboard/store/modules/accounts.js` - UPDATE
- [ ] `app/javascript/dashboard/store/mutation-types.js` - UPDATE
- [ ] `app/javascript/dashboard/i18n/locale/en/labelsMgmt.json` - UPDATE

### Testing Files (Optional)

- [ ] `spec/services/labels/auto_label_service_spec.rb` - NEW
- [ ] `spec/jobs/labels/auto_label_job_spec.rb` - NEW
- [ ] `spec/listeners/auto_label_listener_spec.rb` - NEW

---

## Success Criteria

✅ **Feature Complete When**:

1. Toggle appears in Labels settings page
2. Enabling toggle activates auto-labeling
3. Conversations are automatically labeled after threshold
4. Labels appear in conversation activity feed
5. Settings persist across page reloads
6. Error handling works (retry + logging)
7. Manual testing passes all scenarios
8. No console errors in browser
9. No unhandled exceptions in Rails logs
10. OPENAI_API_KEY properly configured in ENV
11. Structured JSON responses working correctly
12. Labels match exactly what's in the database (no hallucinations)

---

## Support & Troubleshooting

### Common Issues

**Issue**: Auto-labeling not triggering
- **Check**: Is auto_label_enabled = true in account settings?
- **Check**: Is ENV['OPENAI_API_KEY'] set correctly?
- **Check**: Has conversation reached message threshold?
- **Check**: Does conversation already have labels?
- **Check**: Are there at least 3 incoming messages?

**Issue**: Labels not applied
- **Check**: Are there any labels in the account?
- **Check**: Check Sidekiq for failed jobs
- **Check**: Review Rails logs for OpenAI API errors
- **Check**: Verify OPENAI_API_KEY is valid (test with curl)
- **Check**: Verify OpenAI API quota not exceeded

**Issue**: Settings not saving
- **Check**: Browser console for API errors
- **Check**: Rails logs for validation errors
- **Check**: Verify current user is account admin

**Issue**: Invalid labels being applied
- **Check**: This shouldn't happen with structured outputs
- **Check**: Verify JSON schema is working correctly
- **Check**: Review OpenAI API response in logs

**Issue**: OpenAI API errors
- **Check**: API key validity and permissions
- **Check**: Rate limits and quotas
- **Check**: Network connectivity to OpenAI API
- **Check**: OpenAI service status

---

## References

### Related Files (for context)

- `app/models/label.rb` - Label model with acts_as_taggable
- `app/models/conversation.rb` - Conversation model with Labelable concern
- `app/models/concerns/labelable.rb` - Label methods (add_labels, update_labels)
- `app/controllers/api/v1/accounts/labels_controller.rb` - Label CRUD API
- `app/javascript/dashboard/components/widgets/conversation/conversation/LabelSuggestion.vue` - Manual label suggestion UI (existing feature, different from auto-labeling)

### External Dependencies

- **OpenAI Gem**: `gem 'ruby-openai'` - [Documentation](https://github.com/openai/openai-ruby)
- **Structured Outputs**: [OpenAI Docs](https://github.com/openai/openai-ruby?tab=readme-ov-file#structured-outputs-and-function-calling)
- **Acts-as-Taggable-On**: `gem 'acts-as-taggable-on'`
- **Vue 3**: Frontend framework
- **Vuex**: State management
- **Tailwind CSS**: Styling

### OpenAI API Reference

- **Model Used**: gpt-4o-mini (cost-effective for classification)
- **Response Format**: json_schema with strict validation
- **Structured Outputs**: Prevents hallucinated labels via enum constraint
- **Token Optimization**: Last 20 messages only (~3000 tokens max)

---

## Conclusion

This implementation plan provides a complete roadmap for adding AI-powered auto-labeling to Chatwoot. The feature:

- ✅ Uses global ENV-based OpenAI API key (simple configuration)
- ✅ Implements structured JSON outputs (prevents hallucinated labels)
- ✅ Follows Chatwoot conventions (service objects, background jobs, listeners)
- ✅ Provides configurable threshold for flexibility
- ✅ Handles errors gracefully with retry logic
- ✅ Uses Tailwind-only styling per project guidelines
- ✅ Includes comprehensive logging and monitoring
- ✅ Designed for easy testing and debugging
- ✅ No per-account OpenAI integration setup required
- ✅ Cost-effective with gpt-4o-mini model

**Key Technical Highlights**:
- **Structured Outputs**: JSON schema with enum constraint ensures only valid labels
- **Direct OpenAI Integration**: Uses openai-ruby gem directly with ENV key
- **Type Safety**: Response schema enforces strict validation
- **Token Efficiency**: Only sends last 20 messages to stay within limits

**Estimated Effort**: 3-5 days for experienced developer
**Complexity**: Medium (builds on existing patterns)
**Risk**: Low (isolated feature, graceful degradation)

---

**Last Updated**: 2025-11-09
**Version**: 2.0 (Updated for global API key + structured outputs)
**Status**: Ready for Implementation
