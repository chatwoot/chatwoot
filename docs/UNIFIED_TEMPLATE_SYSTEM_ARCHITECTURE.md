# Unified Template System Architecture for Bot and API Integration

## Overview

This document outlines the architecture for a unified, API-first template system that enables rich messaging templates to be consumed by human agents, bots (Dialogflow, Rasa, etc.), and third-party systems via standardized APIs.

## Current State Analysis

### Fragmented Template Systems
Currently, Chatwoot has **4 different template implementations**:

1. **Canned Responses**: Simple text templates (`canned_responses` table)
2. **WhatsApp Templates**: Complex structured templates in JSONB (`message_templates` field)
3. **Twilio Content Templates**: Different JSONB schema (`content_templates` field)
4. **Apple Messages Rich Content**: Service-based with 13+ content types

### Key Issues
- ❌ **No unified template system** - Each channel reinvents the wheel
- ❌ **Code duplication** - Similar logic repeated across channels
- ❌ **Inconsistent schemas** - Different JSONB structures for each channel
- ❌ **Limited reusability** - Templates can't be shared across channels
- ❌ **No bot integration** - Templates not accessible via API for external systems

### Current Bot Integration Patterns
- **Dialogflow Integration**: `/lib/integrations/dialogflow/processor_service.rb`
- **Webhook Bots**: `AgentBot` model with `outgoing_url` for bot responses
- **Message API**: `/api/v1/accounts/conversations/{id}/messages` with rich `content_attributes`
- **Webhook System**: Account-level webhooks for external system notifications

## Recommended Architecture

### 1. Database Schema Design

```sql
-- Unified template storage
CREATE TABLE message_templates (
  id bigint PRIMARY KEY,
  account_id bigint NOT NULL,
  name varchar NOT NULL,
  category varchar, -- 'payment', 'scheduling', 'support', etc.
  description text,

  -- Parameter definitions for bots
  parameters jsonb, -- {param_name: {type, required, description}}

  -- Channel compatibility
  supported_channels text[], -- ['apple_messages', 'whatsapp', 'web_widget']

  -- Template status and versioning
  status varchar DEFAULT 'active', -- 'active', 'draft', 'deprecated'
  version integer DEFAULT 1,

  -- Bot integration metadata
  tags text[], -- ['appointment', 'payment', 'urgent']
  use_cases text[], -- ['booking', 'payment_request', 'support_escalation']

  created_at timestamp,
  updated_at timestamp
);

-- Template content blocks for reusability
CREATE TABLE template_content_blocks (
  id bigint PRIMARY KEY,
  message_template_id bigint NOT NULL,
  block_type varchar, -- 'text', 'time_picker', 'payment', 'list', etc.
  properties jsonb, -- Block-specific configuration with parameter placeholders
  conditions jsonb, -- When to show this block: {if: "{{user_type}} == 'premium'"}
  order_index integer,
  created_at timestamp
);

-- Channel-specific adaptations
CREATE TABLE template_channel_mappings (
  id bigint PRIMARY KEY,
  message_template_id bigint NOT NULL,
  channel_type varchar, -- 'apple_messages_for_business', 'whatsapp', etc.
  content_type varchar, -- 'apple_time_picker', 'interactive', etc.
  field_mappings jsonb, -- How template params map to channel-specific fields
  created_at timestamp
);

-- Template usage analytics for bots
CREATE TABLE template_usage_logs (
  id bigint PRIMARY KEY,
  message_template_id bigint NOT NULL,
  account_id bigint NOT NULL,
  conversation_id bigint,
  sender_type varchar, -- 'AgentBot', 'User', 'DialogflowBot'
  sender_id bigint,
  parameters_used jsonb,
  channel_type varchar,
  success boolean,
  created_at timestamp
);
```

### 2. Content Block Types

Standardized content blocks that work across channels:

```ruby
# app/models/template_content_block.rb
class TemplateContentBlock < ApplicationRecord
  BLOCK_TYPES = %w[
    text media button_group list_picker time_picker
    quick_reply payment_request auth_request form
    location_picker file_upload rich_link
  ].freeze

  # Channel adaptation logic
  def render_for_channel(channel_type, parameters = {})
    case channel_type
    when 'apple_messages_for_business'
      AppleMessages::BlockRenderer.new(self, parameters).render
    when 'whatsapp'
      WhatsApp::BlockRenderer.new(self, parameters).render
    when 'web_widget'
      WebWidget::BlockRenderer.new(self, parameters).render
    end
  end
end
```

### 3. API Endpoints for Bot Integration

```ruby
# Template CRUD operations
POST   /api/v1/accounts/{id}/templates
GET    /api/v1/accounts/{id}/templates
GET    /api/v1/accounts/{id}/templates/{template_id}
PUT    /api/v1/accounts/{id}/templates/{template_id}
DELETE /api/v1/accounts/{id}/templates/{template_id}

# Template rendering for specific channels
POST   /api/v1/accounts/{id}/templates/{template_id}/render
POST   /api/v1/accounts/{id}/templates/render  # Inline template

# Bot-friendly endpoints
GET    /api/v1/accounts/{id}/templates/search?category=payment&channel=whatsapp
POST   /api/v1/accounts/{id}/conversations/{id}/messages/from_template

# Bot template management
GET    /api/v1/accounts/{id}/bot_templates/search
POST   /api/v1/accounts/{id}/bot_templates/render
POST   /api/v1/accounts/{id}/bot_templates/send_message
```

### 4. Bot-Friendly Template Schema Format

```json
{
  "id": "template_123",
  "name": "appointment_booking",
  "category": "scheduling",
  "description": "Template for booking appointments with time picker",
  "channels": ["apple_messages", "whatsapp", "web_widget"],
  "tags": ["appointment", "scheduling", "time_picker"],
  "use_cases": ["booking", "rescheduling"],
  "parameters": {
    "business_name": {
      "type": "string",
      "required": true,
      "description": "Name of the business",
      "example": "Acme Corp"
    },
    "available_slots": {
      "type": "array",
      "items": {"type": "datetime"},
      "required": true,
      "description": "Array of available appointment times",
      "example": ["2025-10-01T14:00:00Z", "2025-10-01T15:00:00Z"]
    },
    "appointment_duration": {
      "type": "integer",
      "required": false,
      "default": 60,
      "description": "Duration in minutes"
    }
  },
  "content_blocks": [
    {
      "type": "text",
      "content": "Hi! {{business_name}} has these available slots:",
      "order": 1
    },
    {
      "type": "time_picker",
      "properties": {
        "title": "Select appointment time",
        "slots": "{{available_slots}}",
        "duration": "{{appointment_duration}}",
        "received_title": "Please pick a time",
        "reply_title": "Great! We'll see you then"
      },
      "order": 2
    }
  ],
  "channel_adaptations": {
    "apple_messages": {
      "content_type": "apple_time_picker",
      "mapping": {
        "event.title": "{{title}}",
        "event.timeslots": "{{available_slots}}",
        "received_title": "{{properties.received_title}}"
      }
    },
    "whatsapp": {
      "content_type": "interactive",
      "mapping": {
        "type": "button",
        "body.text": "{{business_name}} - Select time:",
        "action.buttons": "{{available_slots}}"
      }
    },
    "web_widget": {
      "content_type": "form",
      "mapping": {
        "title": "{{properties.title}}",
        "fields": [
          {
            "type": "datetime_picker",
            "options": "{{available_slots}}"
          }
        ]
      }
    }
  }
}
```

## Implementation Architecture

### 1. Service Layer Architecture

```ruby
# app/services/templates/bot_renderer_service.rb
class Templates::BotRendererService
  def initialize(template_id, parameters, channel_type)
    @template = MessageTemplate.find(template_id)
    @parameters = parameters
    @channel_type = channel_type
  end

  def render_for_bot
    # 1. Validate parameters
    validate_parameters!

    # 2. Process template variables
    processed_content = process_template_variables

    # 3. Adapt for specific channel
    channel_content = adapt_for_channel(processed_content)

    # 4. Return bot-friendly format
    {
      template_id: @template.id,
      content_type: channel_content[:content_type],
      content: channel_content[:content],
      content_attributes: channel_content[:content_attributes],
      suggested_responses: generate_suggested_responses,
      webhook_data: generate_webhook_data
    }
  end

  private

  def validate_parameters!
    @template.parameters.each do |param_name, config|
      if config['required'] && @parameters[param_name].blank?
        raise ArgumentError, "Required parameter '#{param_name}' is missing"
      end

      validate_parameter_type(param_name, @parameters[param_name], config['type'])
    end
  end

  def process_template_variables
    content_blocks = @template.content_blocks.order(:order_index)

    content_blocks.map do |block|
      processed_properties = process_block_properties(block.properties)

      {
        type: block.block_type,
        properties: processed_properties,
        conditions: block.conditions
      }
    end
  end

  def process_block_properties(properties)
    # Replace {{parameter_name}} with actual values
    JSON.parse(
      properties.to_json.gsub(/\{\{(\w+)\}\}/) do |match|
        param_name = $1
        @parameters[param_name] || match
      end
    )
  end

  def adapt_for_channel(content)
    case @channel_type
    when 'apple_messages_for_business'
      AppleMessages::TemplateAdapter.new(content, @template).adapt
    when 'whatsapp'
      WhatsApp::TemplateAdapter.new(content, @template).adapt
    when 'web_widget'
      WebWidget::TemplateAdapter.new(content, @template).adapt
    end
  end
end
```

### 2. Channel Adapter Pattern

```ruby
# app/services/templates/adapters/apple_messages_template_adapter.rb
class Templates::Adapters::AppleMessagesTemplateAdapter
  def initialize(content_blocks, template)
    @content_blocks = content_blocks
    @template = template
  end

  def adapt
    channel_mapping = @template.channel_mappings
      .find_by(channel_type: 'apple_messages_for_business')

    if channel_mapping
      adapt_with_mapping(channel_mapping)
    else
      adapt_with_defaults
    end
  end

  private

  def adapt_with_mapping(mapping)
    {
      content_type: mapping.content_type,
      content: generate_content,
      content_attributes: map_attributes(mapping.field_mappings)
    }
  end

  def adapt_with_defaults
    # Default adaptation logic for Apple Messages
    primary_block = @content_blocks.first

    case primary_block[:type]
    when 'time_picker'
      adapt_time_picker(primary_block)
    when 'list_picker'
      adapt_list_picker(primary_block)
    when 'payment_request'
      adapt_payment_request(primary_block)
    else
      adapt_generic_content
    end
  end

  def adapt_time_picker(block)
    properties = block[:properties]

    {
      content_type: 'apple_time_picker',
      content: properties['title'] || 'Select a time',
      content_attributes: {
        event: {
          title: properties['title'],
          description: properties['description'],
          timeslots: format_timeslots(properties['slots'])
        },
        received_title: properties['received_title'],
        reply_title: properties['reply_title']
      }
    }
  end

  def format_timeslots(slots)
    return [] unless slots.is_a?(Array)

    slots.map.with_index do |slot_time, index|
      {
        identifier: "slot_#{index}",
        startTime: slot_time,
        duration: @template.parameters.dig('appointment_duration', 'default') || 3600
      }
    end
  end
end
```

### 3. Bot Integration Controller

```ruby
# app/controllers/api/v1/accounts/bot_templates_controller.rb
class Api::V1::Accounts::BotTemplatesController < Api::V1::Accounts::BaseController
  before_action :authenticate_bot_access

  # GET /api/v1/accounts/{id}/bot_templates/search
  def search
    templates = MessageTemplate
      .where(account: Current.account)
      .by_category(params[:category])
      .compatible_with_channel(params[:channel])
      .with_required_parameters(params[:required_parameters])
      .tagged_with(params[:tags])

    render json: {
      templates: templates.map(&:bot_summary),
      total: templates.count,
      page: params[:page],
      per_page: params[:per_page]
    }
  end

  # POST /api/v1/accounts/{id}/bot_templates/render
  def render
    service = Templates::BotRendererService.new(
      params[:template_id],
      params[:parameters],
      params[:channel_type]
    )

    result = service.render_for_bot

    # Log template usage for analytics
    log_template_usage(result)

    render json: result
  rescue ArgumentError => e
    render json: { error: e.message }, status: :bad_request
  end

  # POST /api/v1/accounts/{id}/bot_templates/send_message
  def send_message
    conversation = Current.account.conversations.find(params[:conversation_id])

    service = Templates::BotMessagingService.new(
      conversation: conversation,
      template_id: params[:template_id],
      parameters: params[:parameters],
      sender: find_bot_sender
    )

    message = service.send_template_message
    render json: { message: message, template_applied: true }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Resource not found: #{e.message}" }, status: :not_found
  end

  private

  def authenticate_bot_access
    # Verify API key or bot authentication token
    unless valid_bot_token? || valid_api_key?
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def log_template_usage(result)
    TemplateUsageLog.create!(
      message_template_id: result[:template_id],
      account_id: Current.account.id,
      conversation_id: params[:conversation_id],
      sender_type: 'ExternalBot',
      sender_id: current_bot&.id,
      parameters_used: params[:parameters],
      channel_type: params[:channel_type],
      success: true
    )
  end
end
```

## Bot Framework Integration Examples

### 1. Dialogflow Integration

```ruby
# Enhanced Dialogflow integration with template support
class Integrations::Dialogflow::TemplateProcessorService < Integrations::Dialogflow::ProcessorService
  def process_response(message, response)
    fulfillment_messages = response.query_result['fulfillment_messages']

    fulfillment_messages.each do |fulfillment_message|
      if fulfillment_message['payload']&.dig('template_id')
        process_template_response(message, fulfillment_message['payload'])
      else
        # Fallback to original processing
        super
      end
    end
  end

  private

  def process_template_response(message, payload)
    service = Templates::BotRendererService.new(
      payload['template_id'],
      payload['parameters'],
      message.conversation.inbox.channel_type.underscore
    )

    rendered = service.render_for_bot

    message.conversation.messages.create!(
      content: rendered[:content],
      content_type: rendered[:content_type],
      content_attributes: rendered[:content_attributes],
      message_type: :outgoing,
      account_id: message.conversation.account_id,
      inbox_id: message.conversation.inbox_id,
      sender: find_bot_sender
    )
  end
end
```

### 2. Rasa Bot Integration Example

```python
# Example Rasa action using Chatwoot templates
import requests
from typing import Any, Text, Dict, List
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher

class ActionSendAppointmentTemplate(Action):
    def name(self) -> Text:
        return "action_send_appointment_template"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        # Extract entities from conversation
        business_name = tracker.get_slot("business_name") or "Our Business"
        appointment_type = tracker.get_slot("appointment_type")

        # Get available slots from booking system
        available_slots = self.get_available_slots(appointment_type)

        # Search for appropriate template
        templates = self.search_chatwoot_templates(
            category="scheduling",
            channel=self.get_channel_type(tracker),
            tags=["appointment", appointment_type]
        )

        if not templates:
            dispatcher.utter_message(text="Sorry, I couldn't find an appointment template.")
            return []

        # Use the first matching template
        template = templates[0]

        # Render template with parameters
        rendered = self.render_chatwoot_template(
            template_id=template["id"],
            parameters={
                "business_name": business_name,
                "available_slots": available_slots,
                "appointment_duration": 60
            },
            channel_type=self.get_channel_type(tracker)
        )

        # Send via Chatwoot API
        success = self.send_chatwoot_template_message(
            conversation_id=tracker.sender_id,
            rendered_template=rendered
        )

        if success:
            dispatcher.utter_message(text="I've sent you our available appointment slots!")
        else:
            dispatcher.utter_message(text="Sorry, there was an issue sending the appointment options.")

        return []

    def search_chatwoot_templates(self, **kwargs):
        response = requests.get(
            f"{CHATWOOT_API_BASE}/accounts/{ACCOUNT_ID}/bot_templates/search",
            params=kwargs,
            headers={"Authorization": f"Bearer {CHATWOOT_API_TOKEN}"}
        )
        return response.json().get("templates", [])

    def render_chatwoot_template(self, template_id, parameters, channel_type):
        response = requests.post(
            f"{CHATWOOT_API_BASE}/accounts/{ACCOUNT_ID}/bot_templates/render",
            json={
                "template_id": template_id,
                "parameters": parameters,
                "channel_type": channel_type
            },
            headers={"Authorization": f"Bearer {CHATWOOT_API_TOKEN}"}
        )
        return response.json()

    def send_chatwoot_template_message(self, conversation_id, rendered_template):
        response = requests.post(
            f"{CHATWOOT_API_BASE}/accounts/{ACCOUNT_ID}/bot_templates/send_message",
            json={
                "conversation_id": conversation_id,
                "template_id": rendered_template["template_id"],
                "parameters": rendered_template.get("parameters_used", {})
            },
            headers={"Authorization": f"Bearer {CHATWOOT_API_TOKEN}"}
        )
        return response.status_code == 200
```

### 3. Third-Party System Integration

```javascript
// Example: External CRM system using Chatwoot templates
class ChatwootTemplateClient {
  constructor(apiBase, accountId, apiToken) {
    this.apiBase = apiBase;
    this.accountId = accountId;
    this.apiToken = apiToken;
  }

  async searchTemplates(filters) {
    const response = await fetch(
      `${this.apiBase}/accounts/${this.accountId}/bot_templates/search?${new URLSearchParams(filters)}`,
      {
        headers: {
          'Authorization': `Bearer ${this.apiToken}`,
          'Content-Type': 'application/json'
        }
      }
    );
    return response.json();
  }

  async sendPaymentRequest(conversationId, amount, currency, description) {
    // Find payment template
    const templates = await this.searchTemplates({
      category: 'payment',
      tags: 'payment_request',
      channel: 'apple_messages'
    });

    if (templates.templates.length === 0) {
      throw new Error('No payment template found');
    }

    // Send payment request using template
    const response = await fetch(
      `${this.apiBase}/accounts/${this.accountId}/bot_templates/send_message`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          conversation_id: conversationId,
          template_id: templates.templates[0].id,
          parameters: {
            amount: amount,
            currency: currency,
            description: description,
            merchant_name: 'Our Business'
          }
        })
      }
    );

    return response.json();
  }

  async scheduleAppointment(conversationId, serviceType, availableSlots) {
    const templates = await this.searchTemplates({
      category: 'scheduling',
      use_cases: 'booking'
    });

    return this.sendTemplateMessage(conversationId, templates.templates[0].id, {
      business_name: 'Our Service',
      service_type: serviceType,
      available_slots: availableSlots
    });
  }

  async sendTemplateMessage(conversationId, templateId, parameters) {
    const response = await fetch(
      `${this.apiBase}/accounts/${this.accountId}/bot_templates/send_message`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          conversation_id: conversationId,
          template_id: templateId,
          parameters: parameters
        })
      }
    );

    return response.json();
  }
}

// Usage example
const chatwoot = new ChatwootTemplateClient(
  'https://app.chatwoot.com/api/v1',
  'account_123',
  'your_api_token'
);

// Send payment request
await chatwoot.sendPaymentRequest(
  'conversation_456',
  99.99,
  'USD',
  'Service consultation fee'
);

// Schedule appointment
await chatwoot.scheduleAppointment(
  'conversation_456',
  'consultation',
  ['2025-10-01T14:00:00Z', '2025-10-01T15:00:00Z']
);
```

## Webhook Integration Strategy

### 1. Template Event Webhooks

```ruby
# Webhook payload for template events
{
  "event": "template.rendered",
  "timestamp": "2025-09-26T10:00:00Z",
  "account_id": 123,
  "conversation_id": 456,
  "template": {
    "id": "appointment_booking",
    "name": "Appointment Booking",
    "category": "scheduling"
  },
  "channel_type": "apple_messages_for_business",
  "parameters": {
    "business_name": "Acme Corp",
    "available_slots": ["2025-10-01T14:00:00Z"]
  },
  "rendered_content": {
    "content_type": "apple_time_picker",
    "content_attributes": {
      "event": {
        "title": "Schedule Appointment",
        "timeslots": [...]
      }
    }
  },
  "sender": {
    "type": "AgentBot",
    "id": 789,
    "name": "Booking Bot"
  },
  "user_response_webhook": "https://bot.example.com/template_response"
}
```

### 2. Template Response Handling

```ruby
# When user responds to a template message
{
  "event": "template.response_received",
  "timestamp": "2025-09-26T10:05:00Z",
  "account_id": 123,
  "conversation_id": 456,
  "template": {
    "id": "appointment_booking",
    "name": "Appointment Booking"
  },
  "original_parameters": {
    "business_name": "Acme Corp",
    "available_slots": ["2025-10-01T14:00:00Z", "2025-10-01T15:00:00Z"]
  },
  "user_response": {
    "selected_slot": "2025-10-01T14:00:00Z",
    "slot_identifier": "slot_0",
    "response_data": {
      "startTime": "2025-10-01T14:00:00Z",
      "duration": 3600
    }
  },
  "next_actions": [
    "confirm_appointment",
    "send_calendar_invite",
    "collect_contact_info"
  ]
}
```

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
- [ ] Create database migration for unified template tables
- [ ] Build base `MessageTemplate` and `TemplateContentBlock` models
- [ ] Implement parameter validation system
- [ ] Create basic template CRUD API endpoints

### Phase 2: Channel Adapters (Week 3-4)
- [ ] Build Apple Messages template adapter
- [ ] Build WhatsApp template adapter
- [ ] Build Web Widget template adapter
- [ ] Implement channel mapping system
- [ ] Add template rendering service

### Phase 3: Bot Integration APIs (Week 5-6)
- [ ] Create bot-specific API endpoints
- [ ] Implement template search and discovery
- [ ] Build template rendering for bot consumption
- [ ] Add webhook integration for template events
- [ ] Create bot authentication system

### Phase 4: Frontend Template Builder (Week 7-8)
- [ ] Build unified template builder UI
- [ ] Create drag-and-drop content block interface
- [ ] Add real-time channel preview
- [ ] Implement template management interface
- [ ] Add template testing and validation tools

### Phase 5: Migration & Integration (Week 9-10)
- [ ] Migrate existing WhatsApp templates
- [ ] Migrate existing Twilio content templates
- [ ] Migrate Apple Messages templates
- [ ] Update ReplyBox to use unified templates
- [ ] Performance optimization and caching

### Phase 6: Advanced Features (Week 11-12)
- [ ] Template versioning system
- [ ] A/B testing for templates
- [ ] Template analytics and reporting
- [ ] Advanced parameter validation (regex, ranges)
- [ ] Template approval workflow

## Benefits Summary

### For Bot Developers
- ✅ **Standardized API** - Same endpoints work for all bot frameworks
- ✅ **Parameter Validation** - Templates define required/optional parameters
- ✅ **Channel Abstraction** - Write once, works on Apple Messages, WhatsApp, Web
- ✅ **Rich Content Made Easy** - No need to understand channel-specific formats
- ✅ **Template Discovery** - Search templates by use case, category, parameters

### For Dialogflow/Rasa Developers
- ✅ **Webhook Integration** - Easy integration with fulfillment webhooks
- ✅ **Entity Mapping** - Template parameters map directly to bot entities
- ✅ **Response Suggestions** - Templates can suggest follow-up actions
- ✅ **Context Preservation** - Template rendering preserves conversation context

### For Third-Party Systems
- ✅ **API-First Design** - All functionality available via REST API
- ✅ **Webhook Events** - Get notified when templates are used/responded to
- ✅ **Bulk Operations** - Send templates to multiple conversations
- ✅ **Analytics** - Track template performance and usage patterns

### For Human Agents
- ✅ **Rich Template Library** - Centralized, searchable template collection
- ✅ **Cross-Channel Consistency** - Same template works across all channels
- ✅ **Easy Customization** - Fill in parameters, send instantly
- ✅ **Template Analytics** - See which templates work best

### For Businesses/
- ✅ **Faster Development** - New rich features benefit all channels
- ✅ **Better User Experience** - Consistent messaging across platforms
- ✅ **Reduced Maintenance** - Single template system instead of 4
- ✅ **Bot Integration** - Enable sophisticated automated conversations

## Technical Considerations

### Performance
- Use database indexes on frequently queried fields (`category`, `tags`, `supported_channels`)
- Implement Redis caching for frequently used templates
- Use JSONB GIN indexes for parameter and property searches
- Consider read replicas for high-volume bot API usage

### Security
- Implement proper API authentication for bot access
- Validate all template parameters to prevent injection attacks
- Use parameterized queries for template searches
- Audit log all template usage for compliance

### Scalability
- Design API endpoints to handle high bot traffic
- Implement rate limiting for bot API endpoints
- Use background jobs for webhook notifications
- Consider async template rendering for complex templates

### Monitoring
- Track template usage metrics and performance
- Monitor API response times for bot endpoints
- Alert on template rendering failures
- Dashboard for template performance analytics

## Conclusion

This unified template system transforms Chatwoot from a fragmented multi-channel platform into a cohesive, API-first messaging platform that serves both human agents and automated systems. By providing standardized APIs and rich template capabilities, it enables sophisticated bot integrations while maintaining the flexibility needed for diverse messaging channels.

The architecture ensures that rich messaging features developed for one channel automatically benefit all other compatible channels, reducing development time and improving consistency across the platform.