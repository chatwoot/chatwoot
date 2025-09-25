# Complete Guide: Adding a New Messaging Channel to Chatwoot

Based on my analysis of the Chatwoot codebase, here's a comprehensive guide on how to add a new messaging channel, covering the entire message lifecycle from channel configuration to conversation display.

## 1. Backend Channel Configuration

### Channel Model Structure
All channels inherit from the [`Channelable`](app/models/concerns/channelable.rb:1) concern and follow this pattern:

**Required Files:**
- [`app/models/channel/your_channel.rb`](app/models/channel/telegram.rb:17) - Channel model
- Database migration for `channel_your_channel` table
- [`app/controllers/webhooks/your_channel_controller.rb`](app/controllers/webhooks/telegram_controller.rb:1) - Webhook endpoint
- [`app/jobs/webhooks/your_channel_events_job.rb`](app/jobs/webhooks/telegram_events_job.rb:1) - Background job processor
- [`app/services/your_channel/incoming_message_service.rb`](app/services/telegram/incoming_message_service.rb:4) - Message processing service

**Channel Model Example:**
```ruby
class Channel::YourChannel < ApplicationRecord
  include Channelable
  
  self.table_name = 'channel_your_channel'
  EDITABLE_ATTRS = [:api_key, :webhook_url].freeze
  
  validates :api_key, presence: true, uniqueness: true
  before_save :setup_webhook
  
  def name
    'Your Channel'
  end
  
  def send_message(message)
    # Implementation for sending messages to external API
  end
  
  private
  
  def setup_webhook
    # Setup webhook with external service
  end
end
```

### Database Schema
Channel tables follow this pattern:
```ruby
# Schema from telegram example
create_table "channel_your_channel", force: :cascade do |t|
  t.string "api_key", null: false
  t.string "webhook_url"
  t.jsonb "provider_config"
  t.integer "account_id", null: false
  t.timestamps
end

add_index "channel_your_channel", ["api_key"], unique: true
```

### Channel Settings Parameters
Channels define their editable attributes via [`EDITABLE_ATTRS`](app/models/channel/telegram.rb:21) constant:
- Used by [`InboxesController`](app/controllers/api/v1/accounts/inboxes_controller.rb:97) for parameter filtering
- Supports nested attributes for complex configurations
- Example: `[:api_key, { provider_config: {} }]`

## 2. API Endpoint Configuration

### Inbox Management
The [`InboxesController`](app/controllers/api/v1/accounts/inboxes_controller.rb:1) handles channel creation:

**Channel Registration:**
1. Add channel type to [`allowed_channel_types`](app/controllers/api/v1/accounts/inboxes_controller.rb:100-102)
2. Add mapping in [`channel_type_from_params`](app/controllers/api/v1/accounts/inboxes_controller.rb:169-179)

**API Endpoints:**
- `POST /api/v1/accounts/{account_id}/inboxes` - Create inbox with channel
- `PUT /api/v1/accounts/{account_id}/inboxes/{id}` - Update channel settings
- `GET /api/v1/accounts/{account_id}/inboxes` - List inboxes

### Webhook Endpoint
Create webhook controller for incoming messages:
```ruby
class Webhooks::YourChannelController < ActionController::API
  def process_payload
    Webhooks::YourChannelEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end
end
```

**Route Configuration:**
```ruby
# config/routes.rb
post 'webhooks/your_channel/:token', to: 'webhooks/your_channel#process_payload'
```

## 3. Message Payload Processing

### Incoming Message Flow
1. **Webhook Controller** → **Background Job** → **Message Service**
2. [`TelegramEventsJob`](app/jobs/webhooks/telegram_events_job.rb:4) example shows the pattern:
   - Validate channel exists and is active
   - Route to appropriate service based on message type

### Message Service Structure
The [`Telegram::IncomingMessageService`](app/services/telegram/incoming_message_service.rb:4) demonstrates the complete pattern:

**Key Responsibilities:**
1. **Contact Management:** Create/update contact via [`ContactInboxWithContactBuilder`](app/services/telegram/incoming_message_service.rb:41-45)
2. **Conversation Management:** Find existing or create new conversation
3. **Message Creation:** Build message with proper attributes
4. **Attachment Processing:** Handle different media types

**Message Attributes:**
```ruby
@message = @conversation.messages.build(
  content: message_content,
  account_id: @inbox.account_id,
  inbox_id: @inbox.id,
  message_type: :incoming, # or :outgoing
  sender: @contact,
  content_attributes: additional_metadata,
  source_id: external_message_id
)
```

### Rich Content Support
Messages support various [`content_types`](app/models/message.rb:84-97):
- `text` - Plain text messages
- `cards` - Rich card layouts
- `form` - Interactive forms
- `input_select` - Selection menus
- `integrations` - Third-party integrations
- `sticker` - Sticker messages

**Attachment Types:**
The system supports multiple [`attachment types`](app/javascript/dashboard/components-next/message/constants.js:41-52):
- `image`, `audio`, `video`, `file` - Media files
- `location` - Geographic coordinates
- `contact` - Contact cards
- `story_mention` - Social media stories

## 4. Message Storage

### Database Schema
Messages are stored in the [`messages`](app/models/message.rb:1-40) table with these key fields:

**Core Fields:**
- `content` - Message text content
- `content_type` - Type of message (text, cards, form, etc.)
- `content_attributes` - JSON metadata for rich content
- `message_type` - Direction (incoming/outgoing/activity/template)
- `source_id` - External message ID from channel
- `status` - Delivery status (sent/delivered/read/failed)

**Rich Content Storage:**
- [`content_attributes`](app/models/message.rb:105-107) stores structured data as JSON
- [`additional_attributes`](app/models/message.rb:6) for channel-specific metadata
- [`external_source_ids`](app/models/message.rb:109) for multi-platform message tracking

### Attachment Storage
Attachments are separate records linked to messages:
```ruby
# From TelegramIncomingMessageService
@message.attachments.new(
  account_id: @message.account_id,
  file_type: :image, # or :audio, :video, :file, :location, :contact
  file: attachment_data,
  coordinates_lat: lat, # for location
  coordinates_long: lng, # for location
  meta: { custom_data } # for additional metadata
)
```

## 5. Outgoing Message Handling

### Send Service Pattern
Each channel implements a send service inheriting from [`Base::SendOnChannelService`](app/services/base/send_on_channel_service.rb:1):

```ruby
class YourChannel::SendOnYourChannelService < Base::SendOnChannelService
  private
  
  def channel_class
    Channel::YourChannel
  end
  
  def perform_reply
    message_id = channel.send_message(message.conversation.contact_inbox.source_id, message)
    message.update!(source_id: message_id) if message_id.present?
  end
end
```

### Job Integration
Register the service in [`SendReplyJob`](app/jobs/send_reply_job.rb:4-25):
```ruby
services = {
  'Channel::YourChannel' => ::YourChannel::SendOnYourChannelService,
  # ... other services
}
```

## 6. Frontend Message Rendering

### Component Architecture
The frontend uses a component-based system in [`components-next/message/`](app/javascript/dashboard/components-next/message/):

**Core Components:**
- [`Message.vue`](app/javascript/dashboard/components-next/message/Message.vue:1) - Main message wrapper
- [`MessageList.vue`](app/javascript/dashboard/components-next/message/MessageList.vue) - Conversation view
- [`bubbles/`](app/javascript/dashboard/components-next/message/bubbles/) - Message type renderers

### Message Type Rendering
The [`Message.vue`](app/javascript/dashboard/components-next/message/Message.vue:267-315) component maps content types to bubble components:

**Bubble Component Mapping:**
```javascript
// From Message.vue componentToRender computed
if (props.contentType === CONTENT_TYPES.INPUT_CSAT) return CSATBubble;
if (props.contentType === CONTENT_TYPES.FORM) return FormBubble;
if (props.contentType === CONTENT_TYPES.INCOMING_EMAIL) return EmailBubble;

// Attachment-based rendering
if (fileType === ATTACHMENT_TYPES.IMAGE) return ImageBubble;
if (fileType === ATTACHMENT_TYPES.AUDIO) return AudioBubble;
if (fileType === ATTACHMENT_TYPES.VIDEO) return VideoBubble;
if (fileType === ATTACHMENT_TYPES.LOCATION) return LocationBubble;
if (fileType === ATTACHMENT_TYPES.CONTACT) return ContactBubble;

// Default to text bubble
return TextBubble;
```

### Rich Content Display
Each bubble component handles specific content types:
- [`TextBubble`](app/javascript/dashboard/components-next/message/bubbles/Text/Index.vue:1) - Text with formatting and attachments
- [`ImageBubble`](app/javascript/dashboard/components-next/message/bubbles/Image.vue) - Image display with metadata
- [`FormBubble`](app/javascript/dashboard/components-next/message/bubbles/Form.vue) - Interactive forms
- [`LocationBubble`](app/javascript/dashboard/components-next/message/bubbles/Location.vue) - Map integration

### Message Status Indicators
The [`MessageMeta.vue`](app/javascript/dashboard/components-next/message/MessageMeta.vue:1) component shows:
- Delivery status (sent/delivered/read/failed)
- Timestamps
- Channel-specific indicators
- Error states

## 7. Conversation View Features

### Message Grouping
Messages are automatically grouped by:
- Sender continuity
- Time proximity
- Message status

### Interactive Features
The conversation view supports:
- **Context Menus:** Copy, delete, reply actions
- **Message Status:** Real-time delivery tracking  
- **Rich Media:** Inline image/video/audio playback
- **Translations:** Multi-language support
- **Attachments:** File download and preview
- **Forms:** Interactive message responses

### Channel-Specific Features
Different channels can enable specific features:
- **Read Receipts:** For channels supporting read status
- **Typing Indicators:** Real-time typing status
- **Message Reactions:** Emoji reactions
- **Thread Replies:** Threaded conversations
- **Message Editing:** Edit/delete capabilities

## 8. Implementation Checklist

### Backend Requirements
- [ ] Create channel model with `Channelable` concern
- [ ] Add database migration for channel table
- [ ] Implement webhook controller and routes
- [ ] Create background job for event processing
- [ ] Build incoming message service
- [ ] Implement outgoing message service
- [ ] Register channel in `InboxesController`
- [ ] Add channel to `SendReplyJob`

### Frontend Requirements
- [ ] Add channel type to constants
- [ ] Create channel-specific bubble components (if needed)
- [ ] Add channel icon and branding
- [ ] Update inbox management UI
- [ ] Add channel-specific settings forms
- [ ] Test message rendering for all content types

### Testing Requirements
- [ ] Unit tests for channel model
- [ ] Integration tests for webhook processing
- [ ] Message service tests
- [ ] Frontend component tests
- [ ] End-to-end conversation flow tests

## 9. Key Architecture Patterns

### Message Lifecycle
1. **Incoming:** External API → Webhook → Job → Service → Database → Frontend
2. **Outgoing:** Frontend → API → Job → Service → External API → Status Update

### Data Flow
- **Channels** belong to **Accounts** and have one **Inbox**
- **Conversations** belong to **Inboxes** and have many **Messages**
- **Messages** have **Attachments** and belong to **Conversations**
- **Contacts** are linked via **ContactInbox** junction table

### Extension Points
- **Custom Content Types:** Add new message formats
- **Rich Attachments:** Support platform-specific media
- **Interactive Elements:** Forms, buttons, quick replies
- **Status Tracking:** Delivery, read receipts, typing indicators

This comprehensive architecture ensures that new messaging channels integrate seamlessly with Chatwoot's existing conversation management, message storage, and user interface systems.

## 10. Adding New Rich Content Types

### Backend Content Type Registration
To add a new content type, you need to modify several key files:

**1. Message Model Enum:**
Update the [`content_type` enum](app/models/message.rb:84-97) in the Message model:
```ruby
enum content_type: {
  text: 0,
  input_text: 1,
  # ... existing types
  your_new_type: 12  # Next available number
}
```

**2. Content Attribute Validator:**
Add validation rules in [`ContentAttributeValidator`](app/models/concerns/content_attribute_validator.rb:1):
```ruby
class ContentAttributeValidator < ActiveModel::Validator
  ALLOWED_YOUR_TYPE_KEYS = [:title, :data, :custom_field].freeze
  
  def validate(record)
    case record.content_type
    when 'your_new_type'
      validate_items!(record)
      validate_item_attributes!(record, ALLOWED_YOUR_TYPE_KEYS)
    # ... existing validations
    end
  end
end
```

**3. Message Processing:**
Update your channel's incoming message service to handle the new content type:
```ruby
def telegram_params_content_type
  return 'your_new_type' if special_message_condition?
  'text' # default
end
```

### Frontend Content Type Handling

**1. Constants Registration:**
Add to [`constants.js`](app/javascript/dashboard/components-next/message/constants.js:54-67):
```javascript
export const CONTENT_TYPES = {
  // ... existing types
  YOUR_NEW_TYPE: 'your_new_type',
};
```

**2. Component Mapping:**
Update [`Message.vue`](app/javascript/dashboard/components-next/message/Message.vue:267-315) component mapping:
```javascript
const componentToRender = computed(() => {
  if (props.contentType === CONTENT_TYPES.YOUR_NEW_TYPE) {
    return YourNewTypeBubble;
  }
  // ... existing mappings
});
```

**3. Create Bubble Component:**
Create [`bubbles/YourNewType.vue`](app/javascript/dashboard/components-next/message/bubbles/):
```vue
<script setup>
import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';

const { content, contentAttributes } = useMessageContext();
</script>

<template>
  <BaseBubble>
    <!-- Your custom rendering logic -->
    <div class="your-custom-content">
      {{ content }}
    </div>
  </BaseBubble>
</template>
```

## 11. Adding New Attachment Types

### Backend Attachment Type Registration

**1. Attachment Model Enum:**
Update the [`file_type` enum](app/models/attachment.rb:42-43) in the Attachment model:
```ruby
enum file_type: {
  :image => 0, :audio => 1, :video => 2, :file => 3,
  :location => 4, :fallback => 5, :share => 6,
  :story_mention => 7, :contact => 8, :ig_reel => 9,
  :your_new_attachment => 10  # Next available number
}
```

**2. Attachment Metadata:**
Add metadata handling in [`Attachment model`](app/models/attachment.rb:79-92):
```ruby
def metadata_for_file_type
  case file_type.to_sym
  when :your_new_attachment
    your_new_attachment_metadata
  # ... existing cases
  end
end

def your_new_attachment_metadata
  {
    custom_field: meta&.[]('custom_field') || '',
    special_data: meta&.[]('special_data') || {}
  }
end
```

**3. Message Service Integration:**
Update your incoming message service to create the new attachment type:
```ruby
def attach_your_new_type
  return unless your_new_type_data

  @message.attachments.new(
    account_id: @message.account_id,
    file_type: :your_new_attachment,
    meta: {
      custom_field: your_new_type_data['custom_field'],
      special_data: your_new_type_data['special_data']
    }
  )
end
```

### Frontend Attachment Type Handling

**1. Constants Registration:**
Add to [`constants.js`](app/javascript/dashboard/components-next/message/constants.js:41-52):
```javascript
export const ATTACHMENT_TYPES = {
  // ... existing types
  YOUR_NEW_ATTACHMENT: 'your_new_attachment',
};
```

**2. Component Mapping:**
Update [`Message.vue`](app/javascript/dashboard/components-next/message/Message.vue:299-312) attachment mapping:
```javascript
if (Array.isArray(props.attachments) && props.attachments.length === 1) {
  const fileType = props.attachments[0].fileType;
  
  if (fileType === ATTACHMENT_TYPES.YOUR_NEW_ATTACHMENT) return YourNewAttachmentBubble;
  // ... existing mappings
}
```

**3. Create Attachment Bubble:**
Create [`bubbles/YourNewAttachment.vue`](app/javascript/dashboard/components-next/message/bubbles/):
```vue
<script setup>
import { computed } from 'vue';
import { useMessageContext } from '../provider.js';
import BaseAttachmentBubble from './BaseAttachment.vue';

const { attachments } = useMessageContext();

const attachment = computed(() => attachments.value[0]);
const customData = computed(() => attachment.value.meta?.special_data || {});
</script>

<template>
  <BaseAttachmentBubble
    icon="i-your-custom-icon"
    icon-bg-color="bg-[#CustomColor]"
    sender-translation-key="CONVERSATION.SHARED_ATTACHMENT.YOUR_TYPE"
    :title="attachment.meta?.custom_field"
    :content="customData.description"
  />
</template>
```

## 12. Complete New Channel Integration Checklist

### Backend Integration Steps

**1. Channel Model & Database:**
- [ ] Create [`app/models/channel/your_channel.rb`](app/models/channel/telegram.rb:17)
- [ ] Add database migration for `channel_your_channel` table
- [ ] Define `EDITABLE_ATTRS` constant for settings
- [ ] Implement webhook setup and message sending methods

**2. API Controllers:**
- [ ] Create [`app/controllers/webhooks/your_channel_controller.rb`](app/controllers/webhooks/telegram_controller.rb:1)
- [ ] Add route in `config/routes.rb`
- [ ] Register channel in [`InboxesController`](app/controllers/api/v1/accounts/inboxes_controller.rb:100-102):
  ```ruby
  def allowed_channel_types
    %w[web_widget api email line telegram whatsapp sms your_channel]
  end
  ```
- [ ] Add mapping in [`channel_type_from_params`](app/controllers/api/v1/accounts/inboxes_controller.rb:169-179):
  ```ruby
  {
    'your_channel' => Channel::YourChannel,
    # ... existing mappings
  }
  ```

**3. Background Processing:**
- [ ] Create [`app/jobs/webhooks/your_channel_events_job.rb`](app/jobs/webhooks/telegram_events_job.rb:1)
- [ ] Create [`app/services/your_channel/incoming_message_service.rb`](app/services/telegram/incoming_message_service.rb:4)
- [ ] Create [`app/services/your_channel/send_on_your_channel_service.rb`](app/services/telegram/send_on_telegram_service.rb:1)
- [ ] Register in [`SendReplyJob`](app/jobs/send_reply_job.rb:4-25):
  ```ruby
  services = {
    'Channel::YourChannel' => ::YourChannel::SendOnYourChannelService,
    # ... existing services
  }
  ```

### Frontend Integration Steps

**1. Channel Registration:**
- [ ] Add to [`INBOX_TYPES`](app/javascript/dashboard/helper/inbox.js:1-14):
  ```javascript
  export const INBOX_TYPES = {
    YOUR_CHANNEL: 'Channel::YourChannel',
    // ... existing types
  };
  ```

**2. UI Integration:**
- [ ] Add icons to [`INBOX_ICON_MAP_FILL`](app/javascript/dashboard/helper/inbox.js:16-27) and [`INBOX_ICON_MAP_LINE`](app/javascript/dashboard/helper/inbox.js:31-42)
- [ ] Update [`useInbox.js`](app/javascript/dashboard/composables/useInbox.js:49) composable:
  ```javascript
  const isAYourChannelInbox = computed(() => {
    return channelType.value === INBOX_TYPES.YOUR_CHANNEL;
  });
  ```
- [ ] Add channel-specific features to [`INBOX_FEATURES`](app/javascript/dashboard/composables/useInbox.js:14-28)

**3. Settings & Management:**
- [ ] Create channel settings form component
- [ ] Add channel creation wizard step
- [ ] Update inbox management UI
- [ ] Add channel-specific configuration options

### File Type Support Matrix

**Supported File Types by Channel:**
- **Images:** All channels support basic image display
- **Audio:** Transcription support via [`meta.transcribed_text`](app/models/attachment.rb:98)
- **Video:** Inline playback with thumbnail generation
- **Files:** Document preview for [`ACCEPTABLE_FILE_TYPES`](app/models/attachment.rb:27-36)
- **Location:** Coordinate storage with map integration
- **Contact:** vCard-style contact sharing
- **Custom Types:** Extensible via `meta` JSON field

**File Size Limits:**
- Maximum file size: [`40 megabytes`](app/models/attachment.rb:169)
- Validation only applies to [`Channel::WebWidget`](app/models/attachment.rb:152)
- Other channels can implement custom validation

### Rich Content Capabilities

**Interactive Elements:**
- **Forms:** Multi-field input collection with validation
- **Cards:** Rich media cards with action buttons
- **Select Menus:** Dropdown selection with custom options
- **CSAT Surveys:** Customer satisfaction rating collection
- **Articles:** Knowledge base article sharing

**Content Validation:**
Each content type has specific validation rules defined in [`ContentAttributeValidator`](app/models/concerns/content_attribute_validator.rb:1):
- **Cards:** Require `title`, `description`, `media_url`, `actions`
- **Forms:** Support `type`, `placeholder`, `label`, `name`, `options`, `default`, `required`, `pattern`
- **Select:** Need `title` and `value` for each option
- **Articles:** Require `title`, `description`, `link`

This comprehensive integration ensures your new channel supports the full range of Chatwoot's messaging capabilities while maintaining consistency with existing channels.