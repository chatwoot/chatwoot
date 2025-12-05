# Creating a New WhatsApp Inbox Provider

This guide explains how to create a new WhatsApp inbox provider/type in Chatwoot, similar to WhatsApp Cloud or Twilio integrations.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Backend Implementation](#backend-implementation)
3. [Frontend Implementation](#frontend-implementation)
4. [Database Schema](#database-schema)
5. [Webhooks & API Integration](#webhooks--api-integration)
6. [Testing](#testing)
7. [Complete Checklist](#complete-checklist)

## Architecture Overview

Chatwoot's WhatsApp integration follows a provider pattern where:

- **Channel Model** (`Channel::Whatsapp`) manages the WhatsApp channel configuration
- **Provider Services** handle specific provider implementations (WhatsApp Cloud, 360Dialog, etc.)
- **Webhook Controllers** receive and process incoming messages
- **Frontend Components** handle UI for configuration

### Key Components

```
app/
├── models/
│   └── channel/
│       └── whatsapp.rb                    # Main channel model
├── services/
│   └── whatsapp/
│       ├── providers/
│       │   ├── base_service.rb           # Base provider interface
│       │   ├── whatsapp_cloud_service.rb # WhatsApp Cloud implementation
│       │   └── whatsapp_360_dialog_service.rb
│       └── incoming_message_*_service.rb
├── controllers/
│   ├── webhooks/
│   │   └── whatsapp_controller.rb        # Webhook handler
│   └── api/v1/accounts/
│       └── whatsapp/
│           └── authorizations_controller.rb
└── jobs/
    └── webhooks/
        └── whatsapp_events_job.rb

app/javascript/dashboard/
├── routes/dashboard/settings/inbox/
│   └── channels/
│       ├── Whatsapp.vue                  # Provider selector
│       ├── CloudWhatsapp.vue             # WhatsApp Cloud config
│       └── Twilio.vue                    # Twilio config
└── api/channel/
    └── whatsappChannel.js
```

## Backend Implementation

### Step 1: Update the Channel Model

The `Channel::Whatsapp` model (`app/models/channel/whatsapp.rb`) uses a provider pattern. Add your new provider to the `PROVIDERS` constant:

```ruby
class Channel::Whatsapp < ApplicationRecord
  include Channelable
  include Reauthorizable

  self.table_name = 'channel_whatsapp'
  EDITABLE_ATTRS = [:phone_number, :provider, { provider_config: {} }].freeze

  # Add your new provider here
  PROVIDERS = %w[default whatsapp_cloud your_new_provider].freeze

  validates :provider, inclusion: { in: PROVIDERS }
  validates :phone_number, presence: true, uniqueness: true
  validate :validate_provider_config

  def provider_service
    case provider
    when 'whatsapp_cloud'
      Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: self)
    when 'your_new_provider'
      Whatsapp::Providers::YourNewProviderService.new(whatsapp_channel: self)
    else
      Whatsapp::Providers::Whatsapp360DialogService.new(whatsapp_channel: self)
    end
  end

  # Delegate methods to provider service
  delegate :send_message, to: :provider_service
  delegate :send_template, to: :provider_service
  delegate :sync_templates, to: :provider_service
  delegate :media_url, to: :provider_service
  delegate :api_headers, to: :provider_service
end
```

### Step 2: Create the Provider Service

Create a new provider service at `app/services/whatsapp/providers/your_new_provider_service.rb`:

```ruby
class Whatsapp::Providers::YourNewProviderService < Whatsapp::Providers::BaseService

  # Required: Send a text/attachment message
  def send_message(phone_number, message)
    @message = message

    if message.attachments.present?
      send_attachment_message(phone_number, message)
    elsif message.content_type == 'input_select'
      send_interactive_text_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  # Required: Send a WhatsApp template message
  def send_template(phone_number, template_info, message)
    response = HTTParty.post(
      "#{api_base_path}/messages",
      headers: api_headers,
      body: {
        to: phone_number,
        template: template_body_parameters(template_info),
        type: 'template'
      }.to_json
    )

    process_response(response, message)
  end

  # Required: Sync templates from provider
  def sync_templates
    # Mark as updated to prevent continuous retries on failure
    whatsapp_channel.mark_message_templates_updated

    response = HTTParty.get("#{api_base_path}/templates", headers: api_headers)

    if response.success?
      whatsapp_channel.update(
        message_templates: response['templates'],
        message_templates_last_updated: Time.now.utc
      )
    end
  end

  # Required: Validate provider configuration
  def validate_provider_config?
    response = HTTParty.get("#{api_base_path}/validate", headers: api_headers)
    response.success?
  end

  # Required: Return API headers for requests
  def api_headers
    {
      'Authorization' => "Bearer #{whatsapp_channel.provider_config['api_key']}",
      'Content-Type' => 'application/json'
    }
  end

  # Required: Return media URL from media ID
  def media_url(media_id)
    "#{api_base_path}/media/#{media_id}"
  end

  private

  def api_base_path
    ENV.fetch('YOUR_PROVIDER_BASE_URL', 'https://api.yourprovider.com/v1')
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{api_base_path}/messages",
      headers: api_headers,
      body: {
        to: phone_number,
        text: { body: message.outgoing_content },
        type: 'text'
      }.to_json
    )

    process_response(response, message)
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'

    response = HTTParty.post(
      "#{api_base_path}/messages",
      headers: api_headers,
      body: {
        to: phone_number,
        type: type,
        type => {
          link: attachment.download_url,
          caption: message.outgoing_content
        }
      }.to_json
    )

    process_response(response, message)
  end

  # Required: Extract error message from API response
  def error_message(response)
    response.parsed_response&.dig('error', 'message')
  end

  def template_body_parameters(template_info)
    {
      name: template_info[:name],
      language: {
        policy: 'deterministic',
        code: template_info[:lang_code]
      },
      components: template_info[:parameters] || []
    }
  end

  def send_interactive_text_message(phone_number, message)
    payload = create_payload_based_on_items(message)

    response = HTTParty.post(
      "#{api_base_path}/messages",
      headers: api_headers,
      body: {
        to: phone_number,
        interactive: payload,
        type: 'interactive'
      }.to_json
    )

    process_response(response, message)
  end
end
```

### Step 3: Create Incoming Message Service

Create `app/services/whatsapp/incoming_message_your_provider_service.rb`:

```ruby
class Whatsapp::IncomingMessageYourProviderService < Whatsapp::IncomingMessageBaseService

  private

  def processed_params
    # Transform provider-specific webhook payload to Chatwoot format
    @processed_params ||= {
      from: params[:from],
      message: extract_message_content,
      inbox_id: @inbox.id,
      timestamp: params[:timestamp]
    }
  end

  def extract_message_content
    # Extract message based on provider's webhook format
    case params[:type]
    when 'text'
      params.dig(:text, :body)
    when 'image', 'audio', 'video', 'document'
      {
        type: params[:type],
        url: params.dig(params[:type].to_sym, :url),
        caption: params.dig(params[:type].to_sym, :caption)
      }
    end
  end

  def message_type
    params[:type]&.to_sym || :text
  end
end
```

### Step 4: Update Webhook Handler

Update `app/jobs/webhooks/whatsapp_events_job.rb` to handle your provider:

```ruby
def perform(params = {})
  channel = find_channel_from_whatsapp_business_payload(params)

  if channel_is_inactive?(channel)
    Rails.logger.warn("Inactive WhatsApp channel: #{channel&.phone_number}")
    return
  end

  case channel.provider
  when 'whatsapp_cloud'
    Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: channel.inbox, params: params).perform
  when 'your_new_provider'
    Whatsapp::IncomingMessageYourProviderService.new(inbox: channel.inbox, params: params).perform
  else
    Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
  end
end
```

### Step 5: Update InboxesController

Ensure your provider type is allowed in `app/controllers/api/v1/accounts/inboxes_controller.rb`:

```ruby
def allowed_channel_types
  %w[web_widget api email line telegram whatsapp sms]
end
```

The `whatsapp` type covers all WhatsApp providers (differentiated by the `provider` field).

## Frontend Implementation

### Step 1: Create Provider Configuration Component

Create `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/YourProvider.vue`:

```vue
<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';

const store = useStore();
const router = useRouter();

const inboxName = ref('');
const phoneNumber = ref('');
const apiKey = ref('');
const accountId = ref('');

const uiFlags = computed(() => store.getters['inboxes/getUIFlags']);

const rules = {
  inboxName: { required },
  phoneNumber: { required, isPhoneE164OrEmpty },
  apiKey: { required },
  accountId: { required },
};

const v$ = useVuelidate(rules, { inboxName, phoneNumber, apiKey, accountId });

const createChannel = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) {
    return;
  }

  try {
    const whatsappChannel = await store.dispatch('inboxes/createChannel', {
      name: inboxName.value,
      channel: {
        type: 'whatsapp',
        phone_number: phoneNumber.value,
        provider: 'your_new_provider',
        provider_config: {
          api_key: apiKey.value,
          account_id: accountId.value,
        },
      },
    });

    router.replace({
      name: 'settings_inboxes_add_agents',
      params: {
        page: 'new',
        inbox_id: whatsappChannel.id,
      },
    });
  } catch (error) {
    useAlert(error.message || 'Failed to create WhatsApp channel');
  }
};
</script>

<template>
  <form class="flex flex-wrap flex-col mx-0" @submit.prevent="createChannel">
    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.inboxName.$error }">
        Inbox Name
        <input
          v-model="inboxName"
          type="text"
          placeholder="My WhatsApp Inbox"
          @blur="v$.inboxName.$touch"
        />
        <span v-if="v$.inboxName.$error" class="message">
          Inbox name is required
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.phoneNumber.$error }">
        Phone Number
        <input
          v-model="phoneNumber"
          type="text"
          placeholder="+1234567890"
          @blur="v$.phoneNumber.$touch"
        />
        <span v-if="v$.phoneNumber.$error" class="message">
          Valid phone number is required
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.accountId.$error }">
        Account ID
        <input
          v-model="accountId"
          type="text"
          placeholder="Your provider account ID"
          @blur="v$.accountId.$touch"
        />
        <span v-if="v$.accountId.$error" class="message">
          Account ID is required
        </span>
      </label>
    </div>

    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.apiKey.$error }">
        API Key
        <input
          v-model="apiKey"
          type="text"
          placeholder="Your provider API key"
          @blur="v$.apiKey.$touch"
        />
        <span v-if="v$.apiKey.$error" class="message">
          API Key is required
        </span>
      </label>
    </div>

    <div class="w-full mt-4">
      <NextButton
        :is-loading="uiFlags.isCreating"
        type="submit"
        solid
        blue
        label="Create WhatsApp Channel"
      />
    </div>
  </form>
</template>
```

### Step 2: Register the Component in ChannelFactory

Update `app/javascript/dashboard/routes/dashboard/settings/inbox/ChannelFactory.vue`:

```javascript
import YourProvider from './channels/YourProvider.vue';

const channelViewList = {
  facebook: Facebook,
  website: Website,
  // ... other channels
  your_provider: YourProvider,  // Add your provider
};
```

### Step 3: Update WhatsApp Provider Selection

Update `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Whatsapp.vue`:

```javascript
const PROVIDER_TYPES = {
  WHATSAPP: 'whatsapp',
  TWILIO: 'twilio',
  WHATSAPP_CLOUD: 'whatsapp_cloud',
  YOUR_PROVIDER: 'your_provider', // Add this
};

const availableProviders = computed(() => [
  {
    key: PROVIDER_TYPES.WHATSAPP,
    title: 'WhatsApp Cloud',
    description: 'Official WhatsApp Cloud API',
    icon: 'i-woot-whatsapp',
  },
  {
    key: PROVIDER_TYPES.TWILIO,
    title: 'Twilio',
    description: 'Connect via Twilio WhatsApp',
    icon: 'i-woot-twilio',
  },
  {
    key: PROVIDER_TYPES.YOUR_PROVIDER,
    title: 'Your Provider',
    description: 'Connect via Your Provider',
    icon: 'i-woot-whatsapp',
  },
]);
```

Then add handling in the template:

```vue
<YourProvider
  v-else-if="selectedProvider === PROVIDER_TYPES.YOUR_PROVIDER"
/>
```

### Step 4: Add i18n Translations

Update `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`:

```json
{
  "ADD": {
    "WHATSAPP": {
      "PROVIDERS": {
        "YOUR_PROVIDER": "Your Provider",
        "YOUR_PROVIDER_DESC": "Connect your WhatsApp via Your Provider"
      }
    }
  }
}
```

## Database Schema

The WhatsApp channel uses a flexible schema with a `provider_config` JSONB field:

```sql
CREATE TABLE channel_whatsapp (
  id BIGSERIAL PRIMARY KEY,
  account_id INTEGER NOT NULL,
  phone_number VARCHAR NOT NULL UNIQUE,
  provider VARCHAR DEFAULT 'default',
  provider_config JSONB DEFAULT '{}',
  message_templates JSONB DEFAULT '{}',
  message_templates_last_updated TIMESTAMP,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### Provider Config Structure

Each provider stores its configuration in the `provider_config` JSONB field:

```ruby
# WhatsApp Cloud
{
  api_key: "EAAxxxx",
  phone_number_id: "123456",
  business_account_id: "789012",
  webhook_verify_token: "secure_token"
}

# Your Provider
{
  api_key: "your_api_key",
  account_id: "your_account_id",
  # Any other provider-specific config
}
```

## Webhooks & API Integration

### Webhook Setup

1. **Create webhook route** in `config/routes.rb`:

```ruby
get 'webhooks/whatsapp/:phone_number', to: 'webhooks/whatsapp#verify'
post 'webhooks/whatsapp/:phone_number', to: 'webhooks/whatsapp#process_payload'
```

2. **Handle webhook verification** in `app/controllers/webhooks/whatsapp_controller.rb`:

```ruby
class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  def process_payload
    Webhooks::WhatsappEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  private

  def valid_token?(token)
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token']
    token == whatsapp_webhook_verify_token if whatsapp_webhook_verify_token.present?
  end
end
```

3. **Register webhook with provider** (optional service):

```ruby
# app/services/whatsapp/webhook_setup_service.rb
class Whatsapp::WebhookSetupService
  def initialize(channel, business_account_id, api_key)
    @channel = channel
    @business_account_id = business_account_id
    @api_key = api_key
  end

  def perform
    response = HTTParty.post(
      webhook_url,
      headers: { 'Authorization' => "Bearer #{@api_key}" },
      body: {
        url: "#{ENV['FRONTEND_URL']}/webhooks/whatsapp/#{@channel.phone_number}",
        verify_token: @channel.provider_config['webhook_verify_token']
      }.to_json
    )

    raise "Webhook setup failed: #{response.body}" unless response.success?
  end

  private

  def webhook_url
    "https://api.yourprovider.com/v1/#{@business_account_id}/webhook"
  end
end
```

### Message Processing Flow

```
Webhook Payload (Provider)
  ↓
WhatsappController#process_payload
  ↓
WhatsappEventsJob (background job)
  ↓
IncomingMessageYourProviderService
  ↓
Creates/Updates Contact & Conversation
  ↓
Creates Message in Chatwoot
```

## Testing

### Backend Tests

Create `spec/services/whatsapp/providers/your_new_provider_service_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Whatsapp::Providers::YourNewProviderService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'your_new_provider') }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  describe '#send_message' do
    it 'sends a text message' do
      message = create(:message)

      stub_request(:post, "#{service.send(:api_base_path)}/messages")
        .to_return(status: 200, body: { messages: [{ id: '123' }] }.to_json)

      result = service.send_message('+1234567890', message)
      expect(result).to eq('123')
    end
  end

  describe '#sync_templates' do
    it 'syncs templates from provider' do
      stub_request(:get, "#{service.send(:api_base_path)}/templates")
        .to_return(status: 200, body: { templates: [] }.to_json)

      service.sync_templates
      expect(whatsapp_channel.reload.message_templates).to eq([])
    end
  end

  describe '#validate_provider_config?' do
    it 'validates provider configuration' do
      stub_request(:get, "#{service.send(:api_base_path)}/validate")
        .to_return(status: 200)

      expect(service.validate_provider_config?).to be true
    end
  end
end
```

### Frontend Tests

Create `spec/javascript/dashboard/routes/dashboard/settings/inbox/channels/YourProvider.spec.js`:

```javascript
import { mount } from '@vue/test-utils';
import YourProvider from './YourProvider.vue';
import { createStore } from 'vuex';

describe('YourProvider', () => {
  let store;

  beforeEach(() => {
    store = createStore({
      modules: {
        inboxes: {
          namespaced: true,
          getters: {
            getUIFlags: () => ({ isCreating: false }),
          },
          actions: {
            createChannel: jest.fn(),
          },
        },
      },
    });
  });

  it('validates required fields', async () => {
    const wrapper = mount(YourProvider, {
      global: {
        plugins: [store],
      },
    });

    await wrapper.find('form').trigger('submit');

    expect(store.dispatch).not.toHaveBeenCalled();
  });
});
```

## Complete Checklist

### Backend
- [ ] Add provider to `Channel::Whatsapp::PROVIDERS`
- [ ] Create provider service inheriting from `Whatsapp::Providers::BaseService`
- [ ] Implement required methods: `send_message`, `send_template`, `sync_templates`, `validate_provider_config?`, `api_headers`, `media_url`
- [ ] Create incoming message service
- [ ] Update `WhatsappEventsJob` to handle new provider
- [ ] Add webhook setup service (if needed)
- [ ] Create RSpec tests

### Frontend
- [ ] Create provider configuration component
- [ ] Register component in `ChannelFactory.vue`
- [ ] Update `Whatsapp.vue` provider selection
- [ ] Add i18n translations in `en/inboxMgmt.json`
- [ ] Create frontend tests
- [ ] Add provider icon (optional)

### Configuration
- [ ] Add environment variable for provider API base URL
- [ ] Update `provider_config` JSONB structure documentation
- [ ] Configure webhook routes (if different from default)

### Documentation
- [ ] Update API documentation
- [ ] Add user-facing setup guide
- [ ] Document provider-specific requirements

## Reference Examples

For complete working examples, refer to:

- **WhatsApp Cloud**: `app/services/whatsapp/providers/whatsapp_cloud_service.rb`
- **360Dialog**: `app/services/whatsapp/providers/whatsapp_360_dialog_service.rb`
- **Twilio SMS/WhatsApp**: `app/models/channel/twilio_sms.rb` (alternative pattern without provider service)

## Environment Variables

Add to `.env`:

```bash
# Your WhatsApp Provider Configuration
YOUR_PROVIDER_BASE_URL=https://api.yourprovider.com/v1
FRONTEND_URL=https://your-chatwoot-domain.com
```

## Common Pitfalls

1. **Provider Config Validation**: Always validate provider config in `validate_provider_config?` method
2. **Webhook Token**: Generate secure webhook verify tokens for WhatsApp Cloud-like providers
3. **Template Sync Failures**: Mark templates as updated even on failure to prevent infinite retry loops
4. **Error Handling**: Implement proper error extraction in `error_message(response)` method
5. **Media URLs**: Ensure `media_url` method returns correct format for your provider
6. **Phone Number Format**: Validate E.164 format in frontend

## Advanced Topics

### Multiple Phone Numbers per Provider

If your provider supports multiple phone numbers per account (like WhatsApp Cloud):

```ruby
def find_channel_from_webhook_payload(params)
  phone_number = extract_phone_number(params)
  phone_number_id = extract_phone_number_id(params)

  channel = Channel::Whatsapp.find_by(phone_number: phone_number)

  # Validate phone_number_id matches
  return channel if channel && channel.provider_config['phone_number_id'] == phone_number_id
end
```

### OAuth/Embedded Signup Flow

For OAuth flows (like WhatsApp Embedded Signup):

1. Create authorization controller at `app/controllers/api/v1/accounts/whatsapp/authorizations_controller.rb`
2. Create service to exchange code for access token
3. Update frontend with OAuth callback handling

See `Whatsapp::EmbeddedSignupService` for reference.

### Template Management

For providers with template approval workflows:

- Store templates in `message_templates` JSONB field
- Implement template sync in `sync_templates` method
- Create UI for template selection (see `WhatsAppTemplateReply.vue`)

## Support

For questions or issues:
- Check existing provider implementations in `app/services/whatsapp/providers/`
- Review specs in `spec/services/whatsapp/providers/`
- Consult Chatwoot documentation at https://www.chatwoot.com/docs
