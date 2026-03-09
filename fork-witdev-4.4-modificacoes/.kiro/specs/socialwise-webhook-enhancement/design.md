# Design Document

## Overview

This design enhances the SocialWise integration to provide comprehensive WhatsApp metadata in all webhook types while maintaining backward compatibility. The solution involves:

1. **Decoupling SocialWise from Dialogflow**: Remove the requirement for Dialogflow configuration
2. **Universal Webhook Enhancement**: Add SocialWise data to all webhook types (not just Dialogflow)
3. **Structured Data Organization**: Place all SocialWise data under a dedicated "socialwise-chatwit" field
4. **Backward Compatibility**: Maintain existing Dialogflow payload structure and ACCESS_TOKEN functionality

## Architecture

### Current Architecture
```
Webhook Event → WebhookListener → deliver_webhook_payloads() → WebhookJob
                                      ↓
                                 ACCESS_TOKEN added (if configured)
                                      ↓
                                 Webhook delivered
```

### Enhanced Architecture
```
Webhook Event → WebhookListener → deliver_webhook_payloads() → SocialWise Enhancement → WebhookJob
                                      ↓                              ↓
                                 ACCESS_TOKEN added          socialwise-chatwit data added
                                 (if configured)             (if SocialWise active)
                                      ↓                              ↓
                                 Enhanced webhook payload delivered
```

## Components and Interfaces

### 1. SocialWise Service Enhancement

**Location**: `lib/integrations/socialwise/webhook_enhancer_service.rb`

**Purpose**: Centralized service to generate SocialWise metadata for any webhook payload

**Interface**:
```ruby
class Integrations::Socialwise::WebhookEnhancerService
  def self.enhance_payload(payload, account)
    # Returns enhanced payload with socialwise-chatwit data
  end
  
  def self.socialwise_active?(account)
    # Checks if SocialWise integration is enabled
  end
  
  private
  
  def self.build_socialwise_data(payload, account)
    # Builds the socialwise-chatwit data structure
  end
end
```

### 2. Webhook Listener Enhancement

**Location**: `app/listeners/webhook_listener.rb`

**Changes**: Modify `deliver_account_webhooks` method to include SocialWise data

**Enhanced Flow**:
1. Check if SocialWise is active for the account
2. If active, enhance payload with socialwise-chatwit data
3. Continue with existing ACCESS_TOKEN logic
4. Deliver enhanced webhook

### 3. Dialogflow Processor Service Update

**Location**: `lib/integrations/dialogflow/processor_service.rb`

**Changes**: 
- Remove Dialogflow dependency check from SocialWise activation
- Maintain existing payload structure for backward compatibility
- Use shared SocialWise service for data generation

### 4. SocialWise Setup Task Update

**Location**: `lib/tasks/setup_socialwise.rake`

**Changes**: Remove Dialogflow dependency warning and checks

## Data Models

### SocialWise Data Structure

The `socialwise-chatwit` field will contain:

```json
{
  "socialwise-chatwit": {
    "whatsapp_identifiers": {
      "wamid": "wamid.HBgMNTU4NTk3NTUwMTM2FQIAEhgUM0EwQkZFMzZBMzg1RTc3MzQ3MTUA",
      "whatsapp_id": "wamid.HBgMNTU4NTk3NTUwMTM2FQIAEhgUM0EwQkZFMzZBMzg1RTc3MzQ3MTUA",
      "contact_source": "558597550136"
    },
    "contact_data": {
      "id": 1447,
      "name": "Witalo Rocha",
      "phone_number": "+558597550136",
      "email": null,
      "identifier": null,
      "custom_attributes": {
        "whatsapp_token": "XzqGPinpcBhwkfyyjuyShBgD"
      }
    },
    "conversation_data": {
      "id": 1933,
      "status": "pending",
      "assignee_id": null,
      "created_at": "2025-07-14T01:04:30Z",
      "updated_at": "2025-07-19T10:04:46Z"
    },
    "message_data": {
      "id": 30747,
      "content": "Olá",
      "content_type": "text",
      "message_type": "incoming",
      "created_at": "2025-07-19T10:04:46Z"
    },
    "inbox_data": {
      "id": 4,
      "name": "WhatsApp - ANA",
      "channel_type": "Channel::Whatsapp"
    },
    "account_data": {
      "id": 3,
      "name": "DraAmandaSousa"
    },
    "metadata": {
      "socialwise_active": true,
      "is_whatsapp_channel": true,
      "payload_version": "2.0",
      "timestamp": "2025-07-19T10:04:47Z"
    }
  }
}
```

### Webhook Payload Structure

**Standard Webhooks** (message_created, conversation_updated, etc.):
```json
{
  "event": "message_created",
  "account": { ... },
  "message": { ... },
  "conversation": { ... },
  "ACCESS_TOKEN": "token_if_configured",
  "socialwise-chatwit": { ... }
}
```

**Dialogflow Webhooks** (maintains backward compatibility):
```json
{
  "originalDetectIntentRequest": {
    "payload": {
      "message_content": "Olá",
      "contact_name": "Witalo Rocha",
      "socialwise_active": true,
      "whatsapp_token": "XzqGPinpcBhwkfyyjuyShBgD",
      ...
    }
  },
  "queryResult": { ... }
}
```

## Error Handling

### 1. SocialWise Data Collection Failures

**Strategy**: Graceful degradation with fallback data

```ruby
def build_socialwise_data(payload, account)
  # Full data collection with comprehensive error handling
rescue => e
  Rails.logger.error "[SOCIALWISE] Error building data: #{e.message}"
  # Return minimal fallback data
  {
    "metadata": {
      "socialwise_active": true,
      "error": "Data collection failed: #{e.class}: #{e.message}",
      "timestamp": Time.current.iso8601
    }
  }
end
```

### 2. Webhook Delivery Resilience

**Strategy**: Never block webhook delivery due to SocialWise failures

```ruby
def enhance_payload(payload, account)
  return payload unless socialwise_active?(account)
  
  enhanced_payload = payload.dup
  enhanced_payload['socialwise-chatwit'] = build_socialwise_data(payload, account)
  enhanced_payload
rescue => e
  Rails.logger.error "[SOCIALWISE] Enhancement failed: #{e.message}"
  payload # Return original payload
end
```

### 3. Integration State Validation

**Strategy**: Validate SocialWise hook state before processing

```ruby
def socialwise_active?(account)
  hook = account.hooks.find_by(app_id: 'socialwise_chatwit', status: 'enabled')
  return false unless hook
  
  hook.settings&.dig('enabled') == true
rescue => e
  Rails.logger.error "[SOCIALWISE] State check failed: #{e.message}"
  false
end
```

## Testing Strategy

### 1. Unit Tests

**SocialWise Service Tests**:
- Test data structure generation
- Test error handling and fallback scenarios
- Test integration state validation
- Test payload enhancement logic

**Webhook Listener Tests**:
- Test SocialWise data inclusion in standard webhooks
- Test ACCESS_TOKEN and SocialWise coexistence
- Test webhook delivery with SocialWise failures

### 2. Integration Tests

**End-to-End Webhook Tests**:
- Test complete webhook flow with SocialWise active
- Test Dialogflow webhook backward compatibility
- Test webhook delivery without SocialWise
- Test mixed scenarios (some webhooks with SocialWise, others without)

### 3. Performance Tests

**Load Testing**:
- Test webhook delivery performance with SocialWise enhancement
- Test memory usage with large payloads
- Test concurrent webhook processing

### 4. Error Scenario Tests

**Failure Mode Tests**:
- Test webhook delivery when SocialWise data collection fails
- Test system behavior with invalid SocialWise configuration
- Test recovery from temporary failures

## Migration Strategy

### Phase 1: Core Service Implementation
1. Create SocialWise webhook enhancer service
2. Implement data structure generation
3. Add comprehensive error handling

### Phase 2: Webhook Integration
1. Enhance webhook listener with SocialWise support
2. Update Dialogflow processor to use shared service
3. Remove Dialogflow dependency from SocialWise setup

### Phase 3: Testing and Validation
1. Comprehensive test suite implementation
2. Backward compatibility validation
3. Performance testing and optimization

### Phase 4: Documentation and Deployment
1. Update integration documentation
2. Create migration guide for existing users
3. Deploy with feature flag for gradual rollout

## Backward Compatibility

### Existing Dialogflow Integrations
- Maintain current payload structure in `originalDetectIntentRequest.payload`
- Continue supporting existing field names and data types
- Preserve all current functionality

### ACCESS_TOKEN Functionality
- Keep existing ACCESS_TOKEN logic unchanged
- Ensure both ACCESS_TOKEN and socialwise-chatwit can coexist
- Maintain current configuration options

### Webhook Consumers
- New socialwise-chatwit field is additive (won't break existing consumers)
- Existing webhook data structure remains unchanged
- Optional nature ensures non-breaking changes