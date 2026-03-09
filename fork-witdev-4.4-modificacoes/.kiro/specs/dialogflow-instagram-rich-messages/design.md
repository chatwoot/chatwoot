# Design Document

## Overview

Este design implementa o processamento de payloads do Dialogflow para enviar mensagens ricas no Instagram através do Chatwoot. A solução integra-se ao fluxo existente do Dialogflow processor, identificando payloads especiais do Socialwise e roteando-os para um processador especializado que utiliza a infraestrutura existente do Instagram.

A arquitetura mantém total compatibilidade com o fluxo atual, adicionando uma camada de processamento especializada que intercepta mensagens com `socialwiseResponse` e as processa de forma diferenciada.

## Architecture

### Current Dialogflow Flow
```
Dialogflow Response → ProcessorService.process_response() → generate_content_params() → create_conversation()
                                                                      ↓
                                                              Standard text message created
```

### Enhanced Flow with Rich Messages
```
Dialogflow Response → ProcessorService.process_response() → generate_content_params()
                                                                      ↓
                                                            Check for socialwiseResponse
                                                                      ↓
                                                    ┌─────────────────┴─────────────────┐
                                                    ↓                                   ↓
                                        Has socialwiseResponse                No socialwiseResponse
                                                    ↓                                   ↓
                                    SocialwiseResponseProcessor           create_conversation()
                                                    ↓                     (existing flow)
                                        Route by message_format
                                                    ↓
                            ┌───────────────────────┼───────────────────────┐
                            ↓                       ↓                       ↓
                    GENERIC_TEMPLATE        BUTTON_TEMPLATE        QUICK_REPLIES
                            ↓                       ↓                       ↓
                Instagram Rich Message      Instagram Rich Message  Instagram Rich Message
                    (Carousel)                  (Buttons)              (Quick Replies)
```

## Components and Interfaces

### 1. Enhanced Dialogflow Processor Service

**Location**: `lib/integrations/dialogflow/processor_service.rb`

**Changes**: Modify `process_response` method to detect and route `socialwiseResponse` payloads

**Enhanced Logic**:
```ruby
def process_response(message, response)
  fulfillment_messages = response.query_result['fulfillment_messages']
  
  fulfillment_messages.each do |fulfillment_message|
    content_params = generate_content_params(fulfillment_message)
    
    # Check for socialwiseResponse
    if content_params['socialwiseResponse'].present?
      Rails.logger.info "[SOCIALWISE-INSTAGRAM] Processing socialwiseResponse"
      Integrations::Socialwise::InstagramResponseProcessor.process(
        content_params['socialwiseResponse'], 
        message
      )
      # Skip other messages when socialwiseResponse is present (priority rule)
      break
    elsif content_params['action'].present?
      process_action(message, content_params['action'])
    else
      create_conversation(message, content_params)
    end
  end
end
```

### 2. SocialWise Instagram Response Processor

**Location**: `lib/integrations/socialwise/instagram_response_processor.rb`

**Purpose**: Central router for processing socialwiseResponse payloads and sending rich messages

**Interface**:
```ruby
class Integrations::Socialwise::InstagramResponseProcessor
  def self.process(socialwise_data, message)
    # Main entry point for processing socialwiseResponse
  end
  
  private
  
  def self.route_message(message_format, payload, message)
    # Routes to appropriate handler based on message_format
  end
  
  def self.send_generic_template(payload, message)
    # Handles GENERIC_TEMPLATE format
  end
  
  def self.send_button_template(payload, message)
    # Handles BUTTON_TEMPLATE format
  end
  
  def self.send_quick_replies(payload, message)
    # Handles QUICK_REPLIES format
  end
  
  def self.log_unknown_format(message_format)
    # Handles unknown message formats
  end
end
```

### 3. Instagram Rich Message Service

**Location**: `app/services/instagram/rich_message_service.rb`

**Purpose**: Specialized service for sending rich messages to Instagram API using existing infrastructure

**Interface**:
```ruby
class Instagram::RichMessageService < Instagram::BaseSendService
  def initialize(message, rich_payload)
    super(message)
    @rich_payload = rich_payload
  end
  
  def perform
    # Send rich message using existing Instagram infrastructure
  end
  
  private
  
  def rich_message_params
    # Build message params for rich content
  end
  
  def send_message(message_content)
    # Override parent method to send rich content
  end
end
```

## Data Models

### SocialWise Response Structure

The `socialwiseResponse` object received from Dialogflow:

```json
{
  "socialwiseResponse": {
    "message_format": "GENERIC_TEMPLATE|BUTTON_TEMPLATE|QUICK_REPLIES",
    "payload": {
      // Format-specific payload ready for Instagram API
    }
  }
}
```

### Message Format Payloads

#### GENERIC_TEMPLATE Payload
```json
{
  "template_type": "generic",
  "elements": [
    {
      "title": "Card Title",
      "subtitle": "Card Subtitle",
      "image_url": "https://example.com/image.jpg",
      "buttons": [
        {
          "type": "postback",
          "title": "Button Text",
          "payload": "button_payload"
        },
        {
          "type": "web_url",
          "url": "https://example.com",
          "title": "Visit Website"
        }
      ]
    }
  ]
}
```

#### BUTTON_TEMPLATE Payload
```json
{
  "template_type": "button",
  "text": "Choose an option:",
  "buttons": [
    {
      "type": "postback",
      "title": "Option 1",
      "payload": "option_1"
    },
    {
      "type": "web_url",
      "url": "https://example.com",
      "title": "Visit Website"
    }
  ]
}
```

#### QUICK_REPLIES Payload
```json
{
  "text": "Select an option:",
  "quick_replies": [
    {
      "content_type": "text",
      "title": "Option 1",
      "payload": "option_1"
    },
    {
      "content_type": "text",
      "title": "Option 2",
      "payload": "option_2"
    }
  ]
}
```

### Instagram API Message Structure

The final message structure sent to Instagram Graph API:

#### For Templates (Generic/Button)
```json
{
  "recipient": {
    "id": "<INSTAGRAM_USER_ID>"
  },
  "message": {
    "attachment": {
      "type": "template",
      "payload": {
        // socialwiseResponse.payload content goes here
      }
    }
  },
  "messaging_type": "RESPONSE"
}
```

#### For Quick Replies
```json
{
  "recipient": {
    "id": "<INSTAGRAM_USER_ID>"
  },
  "message": {
    // socialwiseResponse.payload content goes here
  },
  "messaging_type": "RESPONSE"
}
```

## Error Handling

### 1. SocialWise Response Processing Failures

**Strategy**: Graceful fallback to standard text message

```ruby
def self.process(socialwise_data, message)
  message_format = socialwise_data['message_format']
  payload = socialwise_data['payload']
  
  route_message(message_format, payload, message)
rescue => e
  Rails.logger.error "[SOCIALWISE-INSTAGRAM] Processing failed: #{e.message}"
  # Fallback to standard text message
  fallback_to_text_message(message, socialwise_data)
end

def self.fallback_to_text_message(message, socialwise_data)
  # Extract text from payload or use generic fallback
  fallback_text = extract_fallback_text(socialwise_data) || "Message received"
  
  conversation = message.conversation
  conversation.messages.create!(
    content: fallback_text,
    message_type: :outgoing,
    account_id: conversation.account_id,
    inbox_id: conversation.inbox_id
  )
end
```

### 2. Instagram API Failures

**Strategy**: Leverage existing error handling from `BaseSendService`

```ruby
def perform
  send_rich_message
rescue StandardError => e
  Rails.logger.error "[SOCIALWISE-INSTAGRAM] Rich message send failed: #{e.message}"
  handle_error(e) # Uses existing error handling
end
```

### 3. Unknown Message Formats

**Strategy**: Log warning and fallback to text

```ruby
def self.log_unknown_format(message_format)
  Rails.logger.warn "[SOCIALWISE-INSTAGRAM] Unknown message format: #{message_format}"
  # Could implement fallback logic here
end
```

### 4. Payload Validation

**Strategy**: Validate payload structure before sending

```ruby
def self.validate_payload(message_format, payload)
  case message_format
  when 'GENERIC_TEMPLATE'
    validate_generic_template(payload)
  when 'BUTTON_TEMPLATE'
    validate_button_template(payload)
  when 'QUICK_REPLIES'
    validate_quick_replies(payload)
  else
    false
  end
end

def self.validate_generic_template(payload)
  payload.is_a?(Hash) &&
    payload['template_type'] == 'generic' &&
    payload['elements'].is_a?(Array) &&
    payload['elements'].any?
end
```

## Testing Strategy

### 1. Unit Tests

**Dialogflow Processor Tests**:
- Test socialwiseResponse detection and routing
- Test priority rule (socialwiseResponse over text messages)
- Test fallback when socialwiseResponse processing fails
- Test existing functionality remains unaffected

**SocialWise Response Processor Tests**:
- Test routing logic for each message format
- Test payload validation
- Test error handling and fallback scenarios
- Test logging functionality

**Rich Message Service Tests**:
- Test message parameter construction for each format
- Test Instagram API integration
- Test error handling using existing infrastructure

### 2. Integration Tests

**End-to-End Flow Tests**:
- Test complete flow from Dialogflow response to Instagram message
- Test different message formats in realistic scenarios
- Test error scenarios and fallback behavior
- Test coexistence with standard text messages

### 3. Instagram API Tests

**Mock API Tests**:
- Test API call structure for each message format
- Test authentication and rate limiting
- Test response handling and error scenarios

### 4. Backward Compatibility Tests

**Existing Flow Tests**:
- Ensure standard Dialogflow processing remains unchanged
- Test that non-Instagram channels are unaffected
- Verify existing error handling continues to work

## Implementation Details

### 1. Message Format Detection

```ruby
def self.process(socialwise_data, message)
  Rails.logger.info "[SOCIALWISE-INSTAGRAM] Processing socialwiseResponse: #{socialwise_data.inspect}"
  
  message_format = socialwise_data['message_format']
  payload = socialwise_data['payload']
  
  unless validate_payload(message_format, payload)
    Rails.logger.error "[SOCIALWISE-INSTAGRAM] Invalid payload for format: #{message_format}"
    return fallback_to_text_message(message, socialwise_data)
  end
  
  route_message(message_format, payload, message)
end
```

### 2. Instagram Channel Validation

```ruby
def self.route_message(message_format, payload, message)
  conversation = message.conversation
  
  unless conversation.inbox.instagram?
    Rails.logger.warn "[SOCIALWISE-INSTAGRAM] Rich messages only supported for Instagram channels"
    return fallback_to_text_message(message, { 'payload' => payload })
  end
  
  case message_format
  when 'GENERIC_TEMPLATE'
    send_generic_template(payload, message)
  when 'BUTTON_TEMPLATE'
    send_button_template(payload, message)
  when 'QUICK_REPLIES'
    send_quick_replies(payload, message)
  else
    log_unknown_format(message_format)
    fallback_to_text_message(message, { 'payload' => payload })
  end
end
```

### 3. Rich Message Service Integration

```ruby
def self.send_generic_template(payload, message)
  Rails.logger.info "[SOCIALWISE-INSTAGRAM] Sending Generic Template"
  
  rich_service = Instagram::RichMessageService.new(message, payload)
  rich_service.perform
rescue => e
  Rails.logger.error "[SOCIALWISE-INSTAGRAM] Generic Template send failed: #{e.message}"
  fallback_to_text_message(message, { 'payload' => payload })
end
```

### 4. Payload Transformation

```ruby
class Instagram::RichMessageService < Instagram::BaseSendService
  def initialize(message, rich_payload)
    super(message)
    @rich_payload = rich_payload
  end
  
  private
  
  def rich_message_params
    base_params = {
      recipient: { id: contact.get_source_id(inbox.id) }
    }
    
    if template_format?
      base_params[:message] = {
        attachment: {
          type: 'template',
          payload: @rich_payload
        }
      }
    else
      # Quick replies format
      base_params[:message] = @rich_payload
    end
    
    merge_human_agent_tag(base_params)
  end
  
  def template_format?
    %w[generic button].include?(@rich_payload['template_type'])
  end
  
  def send_message(message_content)
    # Use existing Instagram send infrastructure
    super(message_content)
  end
end
```

## Migration Strategy

### Phase 1: Core Infrastructure
1. Create SocialWise Instagram Response Processor
2. Create Instagram Rich Message Service
3. Implement basic routing and validation logic

### Phase 2: Dialogflow Integration
1. Enhance Dialogflow Processor Service
2. Implement socialwiseResponse detection
3. Add priority rule implementation

### Phase 3: Message Format Support
1. Implement Generic Template support
2. Implement Button Template support
3. Implement Quick Replies support

### Phase 4: Error Handling and Testing
1. Comprehensive error handling implementation
2. Fallback mechanisms
3. Complete test suite
4. Integration testing

### Phase 5: Logging and Monitoring
1. Detailed logging implementation
2. Performance monitoring
3. Error tracking and alerting

## Backward Compatibility

### Existing Dialogflow Flow
- All existing functionality remains unchanged
- Standard text messages continue to work as before
- Non-Instagram channels are unaffected
- Error handling maintains existing behavior

### Instagram Channel Compatibility
- Existing Instagram text messaging remains functional
- Rich messages are additive functionality
- Fallback ensures no message loss
- API usage follows existing patterns

### SocialWise Integration
- Maintains compatibility with existing webhook enhancement
- Uses same infrastructure for data collection
- Follows established logging patterns
- Preserves existing configuration options