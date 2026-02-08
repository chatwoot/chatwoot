# Design Document

## Overview

This design completes the SocialWise Flow integration by implementing response processing capabilities. The system already sends webhooks to SocialWise Flow via `Integrations::SocialwiseFlow::ProcessorService` and receives responses, but needs to process the returned payloads to deliver rich messages and handle bot handoff.

The solution leverages existing Chatwoot native services:

- `Whatsapp::RichMessageService` for WhatsApp interactive messages
- `Instagram::RichMessageService` for Instagram rich messages
- `Facebook::RawDeliverService` for Facebook Messenger messages
- Native conversation handoff mechanisms

## Architecture

### Current Flow

```
Message Event → SocialwiseFlow::ProcessorService → HTTP Request to SocialWise Flow
                                                        ↓
                                                   Response received
                                                        ↓
                                                   [MISSING] Response Processing
```

### Enhanced Flow

```
Message Event → SocialwiseFlow::ProcessorService → HTTP Request to SocialWise Flow
                                                        ↓
                                                   Response received
                                                        ↓
                                               process_response() method
                                                        ↓
                                    ┌─────────────────┼─────────────────┐
                                    ↓                 ↓                 ↓
                            WhatsApp Response   Instagram Response  Facebook Response
                                    ↓                 ↓                 ↓
                        Whatsapp::RichMessageService  Instagram::RichMessageService  Facebook::RawDeliverService
                                    ↓                 ↓                 ↓
                            Interactive Messages   Rich Templates    Raw Payloads
                                    ↓                 ↓                 ↓
                                          Button Click Processing
                                                   ↓
                                            Handoff Processing
```

## Components and Interfaces

### 1. Enhanced SocialwiseFlow::ProcessorService

**Location**: `lib/integrations/socialwise_flow/processor_service.rb`

**Current State**: Already implemented with basic structure
**Enhancement Needed**: Complete the response processing methods

**Key Methods**:

```ruby
def process_response(message, response)
  # Route response by channel type
  # Handle actions (handoff)
  # Process rich message payloads
end

def process_whatsapp_response(message, whatsapp_payload)
  # Create mirror message for dashboard
  # Call Whatsapp::RichMessageService
end

def process_instagram_response(message, instagram_payload)
  # Create mirror message for dashboard
  # Call Instagram::RichMessageService
end

def process_facebook_response(message, facebook_payload)
  # Handle text messages
  # Call Facebook::RawDeliverService for rich content
end
```

### 2. Button Click Response Processing

**Purpose**: Handle button_reaction responses with emoji reactions and contextual text

**Implementation**: Extend existing response processing methods

**WhatsApp Button Click Flow**:

```ruby
# Response format from SocialWise Flow:
{
  "action_type": "button_reaction",
  "buttonId": "btn_1756139209769_0_u8bq",
  "processed": true,
  "mappingFound": true,
  "emoji": "❤️",
  "text": "VAI ser atendido em instantes",
  "action": "handoff",
  "whatsapp": {
    "message_id": "wamid.HBgMNTU4NTk3NTUwMTM2FQIAEhgU84KOMYKRCYMRHGF1LYCQ9PA",
    "reaction_emoji": "❤️",
    "response_text": "VAI ser atendido em instantes"
  }
}
```

**Instagram Button Click Flow**:

```ruby
# Response format from SocialWise Flow:
{
  "action_type": "button_reaction",
  "buttonId": "ig_btn_1756139332989_pm6hd9wau",
  "processed": true,
  "mappingFound": true,
  "emoji": "😅",
  "text": "VAI ser atendido em instantes",
  "action": "handoff",
  "instagram": {
    "message_id": "aWdfZAG1faXRlbToxOklHTWVzc2FnZAUlE0Jhw/PIwCG8Wwwn4SUIpa6HJagW2ekt1vbrB/EUlZDZD",
    "reaction_emoji": "😅",
    "response_text": "VAI ser atendido em instantes"
  }
}
```

### 3. Handoff Processing

**Purpose**: Transfer conversations from bot to human agents

**Implementation**: Use existing Chatwoot handoff mechanisms

```ruby
def process_action(message, action)
  case action
  when 'handoff'
    message.conversation.bot_handoff!
    # This changes status from 'pending' to 'open'
    # Dispatches CONVERSATION_BOT_HANDOFF event
  end
end
```

### 4. Rich Message Services Integration

**WhatsApp Integration**:

```ruby
# Use existing Whatsapp::RichMessageService
service = Whatsapp::RichMessageService.new(
  message: outgoing_message,
  interactive_payload: whatsapp_payload
)
service.perform
```

**Instagram Integration**:

```ruby
# Use existing Instagram::RichMessageService
service = Instagram::RichMessageService.new(
  message: outgoing_message,
  rich_payload: instagram_payload
)
service.perform
```

**Facebook Integration**:

```ruby
# Use existing Facebook::RawDeliverService
service = Facebook::RawDeliverService.new(
  message: outgoing_message,
  payload: facebook_payload
)
service.perform
```

## Data Models

### SocialWise Flow Response Formats

**WhatsApp Interactive Message**:

```json
{
  "whatsapp": {
    "type": "interactive",
    "interactive": {
      "body": {
        "text": "> Sr(a) *Cliente*, \nSomos especializados em mandado de segurança..."
      },
      "header": {
        "type": "image",
        "image": {
          "link": "https://objstoreapi.witdev.com.br/chatwit-social/33ad7e6c-7524-4bbb-a7f5-80d35768b3f8.png"
        }
      },
      "footer": {
        "text": "Dra. Amanda Sousa Advocacia e Consultoria Jurídica™"
      },
      "type": "button",
      "action": {
        "buttons": [
          {
            "type": "reply",
            "reply": {
              "id": "btn_1756139209769_0_u8bq",
              "title": "Falar com a Dra"
            }
          }
        ]
      }
    }
  }
}
```

**Instagram Rich Messages**:

_Generic Template_:

```json
{
  "instagram": {
    "message_format": "GENERIC_TEMPLATE",
    "template_type": "generic",
    "elements": [
      {
        "title": "mandado de segurança\n\nDra. Amanda Sousa Advocacia e Consultoria Jurídica™",
        "buttons": [
          {
            "type": "postback",
            "title": "atendimento",
            "payload": "ig_btn_1756139332989_pm6hd9wau"
          }
        ],
        "image_url": "https://objstoreapi.witdev.com.br/chatwit-social/1b2024eb-ecd3-486d-8629-57a1df029b08.png"
      }
    ]
  }
}
```

_Button Template_:

```json
{
  "instagram": {
    "message_format": "BUTTON_TEMPLATE",
    "template_type": "button",
    "text": "BUTTON_TEMPLATE pode ter até 640 caractrees e 3 botoes postback ou web_url (mistura)",
    "buttons": [
      {
        "type": "postback",
        "title": "finalizar",
        "payload": "ig_btn_1756164895605_betjxtlxr"
      },
      {
        "type": "postback",
        "title": "atendimento",
        "payload": "ig_btn_1756164897692_r4p8f1btg"
      },
      {
        "type": "web_url",
        "title": "meu site",
        "url": "https://witdev.com.br"
      }
    ]
  }
}
```

_Quick Replies_:

```json
{
  "instagram": {
    "message_format": "QUICK_REPLIES",
    "text": "QUICK_REPLY_2  PODE TER ATÉ 1000 CARACTERES E 13 BOTOES",
    "quick_replies": [
      {
        "content_type": "text",
        "title": "1",
        "payload": "ig_btn_1756164551022_58syso7j0"
      },
      {
        "content_type": "text",
        "title": "2",
        "payload": "ig_btn_1756164552127_2allygt3l"
      },
      {
        "content_type": "text",
        "title": "3",
        "payload": "ig_btn_1756164553169_fwo24yr8e"
      },
      {
        "content_type": "text",
        "title": "4",
        "payload": "ig_btn_1756164554152_stll7gg63"
      }
    ]
  }
}
```

### Message Creation Structure

**Outgoing Message for Dashboard**:

```ruby
{
  content_type: 'integrations',
  content: nil,
  content_attributes: {
    'whatsapp_interactive' => whatsapp_payload,  # or
    'instagram_rich' => instagram_payload,       # or
    'facebook_rich' => facebook_payload
  },
  message_type: :outgoing,
  account_id: conversation.account_id,
  inbox_id: conversation.inbox_id
}
```

## Error Handling

### 1. Response Processing Failures

**Strategy**: Graceful degradation with detailed logging

```ruby
def process_response(message, response)
  return if response.blank?

  # Process actions first (handoff)
  if (action = response['action']).present?
    process_action(message, action)
    return
  end

  # Route by channel with error handling
  channel_type = message.conversation.inbox.channel_type

  case channel_type
  when 'Channel::Whatsapp'
    process_whatsapp_response(message, response['whatsapp'])
  when 'Channel::Instagram'
    process_instagram_response(message, response['instagram'])
  when 'Channel::FacebookPage'
    process_facebook_response(message, response['facebook'])
  else
    # Fallback to text message
    create_conversation(message, { content: response['text'].presence || response.to_s })
  end
rescue StandardError => e
  Rails.logger.error("[SOCIALWISE-FLOW] Response processing failed: #{e.class}: #{e.message}")
  # Create fallback text message
  create_conversation(message, { content: "Response processing failed" })
end
```

### 2. Rich Message Service Failures

**Strategy**: Continue processing even if rich message sending fails

```ruby
def process_whatsapp_response(message, whatsapp_payload)
  if whatsapp_payload.blank?
    create_conversation(message, { content: default_text(response: whatsapp_payload) })
    return
  end

  # Create mirror message for dashboard
  mirror_params = {
    content_type: 'integrations',
    content: nil,
    content_attributes: { 'whatsapp_interactive' => whatsapp_payload }
  }
  create_conversation(message, mirror_params)

  # Send via WhatsApp service
  Whatsapp::RichMessageService.new(
    message: message.conversation.messages.last,
    interactive_payload: whatsapp_payload
  ).perform
rescue StandardError => e
  Rails.logger.error("[SOCIALWISE-FLOW][WHATSAPP] send failed: #{e.class}: #{e.message}")
  # Message already created for dashboard, continue processing
end
```

### 3. Button Click Processing Failures

**Strategy**: Process handoff even if reaction sending fails

```ruby
def process_button_reaction(message, reaction_data)
  # Send emoji reaction and text
  send_reaction_response(message, reaction_data)

  # Process handoff if specified
  if reaction_data['action'] == 'handoff'
    process_action(message, 'handoff')
  end
rescue StandardError => e
  Rails.logger.error("[SOCIALWISE-FLOW] Button reaction failed: #{e.class}: #{e.message}")

  # Still process handoff even if reaction failed
  if reaction_data['action'] == 'handoff'
    process_action(message, 'handoff')
  end
end
```

## Testing Strategy

### 1. Unit Tests

**SocialwiseFlow::ProcessorService Tests**:

- Test `process_response` method with different response formats
- Test channel-specific processing methods
- Test handoff action processing
- Test button click reaction processing
- Test error handling and fallback scenarios

**Rich Message Service Integration Tests**:

- Test WhatsApp interactive message processing
- Test Instagram rich message processing
- Test Facebook raw payload processing
- Test message creation and dashboard mirroring

### 2. Integration Tests

**End-to-End Flow Tests**:

- Test complete flow from SocialWise Flow response to message delivery
- Test button click processing with handoff
- Test conversation status changes during handoff
- Test error scenarios and fallback behavior

### 3. Channel-Specific Tests

**WhatsApp Tests**:

- Test interactive button messages (≤3 buttons)
- Test interactive list messages (>3 buttons)
- Test button click responses with emoji reactions

**Instagram Tests**:

- Test Generic Template messages
- Test Button Template messages
- Test Quick Replies messages
- Test postback processing with emoji reactions

**Facebook Tests**:

- Test raw payload delivery
- Test recipient ID handling
- Test text message fallbacks

## Performance Considerations

### 1. Message Creation Optimization

**Strategy**: Batch message creation when possible

```ruby
def create_conversation(message, content_params)
  return if content_params.blank?

  conversation = message.conversation
  conversation.messages.create!(
    content_params.merge(
      {
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id
      }
    )
  )
end
```

### 2. Error Logging Optimization

**Strategy**: Structured logging with appropriate levels

```ruby
# Use appropriate log levels
Rails.logger.info("[SOCIALWISE-FLOW] Processing response for message #{message.id}")
Rails.logger.warn("[SOCIALWISE-FLOW] Empty payload received")
Rails.logger.error("[SOCIALWISE-FLOW] Processing failed: #{e.class}: #{e.message}")
```

### 3. Service Call Optimization

**Strategy**: Reuse message objects and avoid unnecessary database queries

```ruby
# Reuse the created message object
outgoing_message = message.conversation.messages.last
service.new(message: outgoing_message, payload: payload).perform
```

## Migration Strategy

### Phase 1: Complete Response Processing

1. Implement missing methods in `SocialwiseFlow::ProcessorService`
2. Add comprehensive error handling
3. Test with existing SocialWise Flow integration

### Phase 2: Button Click Enhancement

1. Add button_reaction processing
2. Implement emoji reaction sending
3. Test handoff functionality

### Phase 3: Testing and Validation

1. Comprehensive test suite implementation
2. Integration testing with real SocialWise Flow responses
3. Performance testing and optimization

### Phase 4: Documentation and Deployment

1. Update integration documentation
2. Create troubleshooting guide
3. Deploy with monitoring and logging

## Backward Compatibility

### Existing SocialWise Flow Integration

- Maintain current webhook sending functionality
- Preserve existing processor service structure
- Keep current error handling patterns

### Message Creation Patterns

- Use existing message creation methods
- Maintain current content_attributes structure
- Preserve dashboard display compatibility

### Service Integration

- Use existing rich message services without modification
- Maintain current service interfaces
- Preserve existing error handling in services
