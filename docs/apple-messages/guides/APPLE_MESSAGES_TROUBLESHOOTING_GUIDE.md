# Apple Messages for Business - Troubleshooting & Implementation Guide

## Table of Contents
1. [Overview](#overview)
2. [Message Types & Structure](#message-types--structure)
3. [Common Issues & Solutions](#common-issues--solutions)
4. [Validation System](#validation-system)
5. [Frontend Implementation](#frontend-implementation)
6. [Backend Implementation](#backend-implementation)
7. [Debugging Tools](#debugging-tools)
8. [UI Customization](#ui-customization)
9. [Testing Checklist](#testing-checklist)

## Overview

Apple Messages for Business in Chatwoot supports three interactive message types:
- **Quick Reply**: Simple button-based responses
- **List Picker**: Multi-section selection lists
- **Time Picker**: Date/time selection interface

Each message type requires specific content structure and validation to display correctly in the Chatwoot UI.

## Message Types & Structure

### Quick Reply Messages

**Content Type**: `apple_quick_reply`

**Required Structure**:
```json
{
  "content_type": "apple_quick_reply",
  "content_attributes": {
    "summary_text": "Question text",
    "items": [
      {"title": "Option 1"},
      {"title": "Option 2"}
    ],
    "received_title": "Please select an option",
    "received_subtitle": "",
    "received_style": "small",
    "reply_title": "Selected: ${item.title}",
    "reply_subtitle": "",
    "reply_style": "icon"
  }
}
```

### List Picker Messages

**Content Type**: `apple_list_picker`

**Required Structure**:
```json
{
  "content_type": "apple_list_picker",
  "content_attributes": {
    "sections": [
      {
        "title": "Section 1",
        "items": [
          {"title": "Item 1", "subtitle": "Description"},
          {"title": "Item 2", "subtitle": "Description"}
        ]
      }
    ],
    "received_title": "Choose from list",
    "received_subtitle": "",
    "received_style": "large",
    "reply_title": "Selected: ${item.title}",
    "reply_subtitle": "",
    "reply_style": "icon"
  }
}
```

### Time Picker Messages

**Content Type**: `apple_time_picker`

**Required Structure**:
```json
{
  "content_type": "apple_time_picker",
  "content_attributes": {
    "event": {
      "title": "Schedule Meeting",
      "subtitle": "Pick a time",
      "timezone_offset": 120
    },
    "received_title": "Select time",
    "received_subtitle": "",
    "received_style": "large",
    "reply_title": "Scheduled for ${event.title}",
    "reply_subtitle": "",
    "reply_style": "icon"
  }
}
```

## Common Issues & Solutions

### Issue 1: Messages Display as Plain Text

**Symptoms**: Interactive messages show only text content without buttons/pickers

**Root Causes**:
1. Incorrect `content_type` (e.g., "text" instead of "apple_quick_reply")
2. Missing or invalid `content_attributes`
3. Validation failures blocking message creation

**Solution**:
```ruby
# Fix existing message
message = Message.find(MESSAGE_ID)
message.update!(
  content_type: 'apple_quick_reply',
  content_attributes: {
    'summary_text' => 'Your question',
    'items' => [{'title' => 'Yes'}, {'title' => 'No'}],
    'received_title' => 'Please select',
    'received_style' => 'small',
    'reply_title' => 'Selected: ${item.title}',
    'reply_style' => 'icon'
  }
)
```

### Issue 2: Validation Errors During Message Creation

**Symptoms**: 
- "Content attributes [field] is required for [message_type]"
- Messages fail to save with validation errors

**Root Causes**:
1. Missing required fields in `content_attributes`
2. Restrictive validation constants
3. Property name mismatches (camelCase vs snake_case)

**Solution**: Check [`ContentAttributeValidator`](app/models/concerns/content_attribute_validator.rb) constants:

```ruby
# Ensure all required keys are included
ALLOWED_APPLE_QUICK_REPLY_KEYS = [
  :summary_text, :items, :received_title, :received_subtitle, 
  :received_style, :reply_title, :reply_subtitle, :reply_style,
  :reply_image_title, :reply_image_subtitle, :reply_secondary_subtitle, 
  :reply_tertiary_subtitle
].freeze

ALLOWED_APPLE_LIST_PICKER_KEYS = [
  :sections, :received_title, :received_subtitle, :received_style,
  :reply_title, :reply_subtitle, :reply_style, :images, 
  :reply_image_title, :reply_image_subtitle
].freeze

ALLOWED_APPLE_TIME_PICKER_KEYS = [
  :event, :timezone_offset, :received_title, :received_subtitle,
  :received_style, :reply_title, :reply_subtitle, :reply_style
].freeze
```

### Issue 3: Frontend Data Not Reaching Backend

**Symptoms**: Frontend sends data but backend receives empty/filtered content_attributes

**Root Causes**:
1. Missing parameter filtering in controller
2. Property name mapping issues
3. Store accessor filtering

**Solution**: Update [`MessagesController`](app/controllers/api/v1/accounts/conversations/messages_controller.rb):

```ruby
private

def create_params
  params.permit(
    :content, :private, :echo_id, :content_type, :cc_emails, :bcc_emails, :to_emails,
    content_attributes: [
      # Apple Quick Reply
      :summary_text, :received_title, :received_subtitle, :received_style,
      :reply_title, :reply_subtitle, :reply_style, :reply_image_title,
      :reply_image_subtitle, :reply_secondary_subtitle, :reply_tertiary_subtitle,
      { items: [:title, :subtitle, :identifier] },
      
      # Apple List Picker  
      :received_title, :received_subtitle, :received_style,
      :reply_title, :reply_subtitle, :reply_style, :reply_image_title, :reply_image_subtitle,
      { sections: [{ items: [:title, :subtitle, :identifier] }], images: [] },
      
      # Apple Time Picker
      :timezone_offset, :received_title, :received_subtitle, :received_style,
      :reply_title, :reply_subtitle, :reply_style,
      { event: [:title, :subtitle, :timezone_offset] }
    ]
  )
end
```

### Issue 4: Store Accessor Filtering

**Symptoms**: Content attributes saved but missing keys when retrieved

**Root Cause**: [`Message`](app/models/message.rb) model store accessor filtering

**Solution**: Update store accessors to include all Apple Messages keys:

```ruby
store :content_attributes, accessors: [
  :summary_text, :items, :sections, :event, :timezone_offset,
  :received_title, :received_subtitle, :received_style,
  :reply_title, :reply_subtitle, :reply_style,
  :reply_image_title, :reply_image_subtitle, :reply_secondary_subtitle,
  :reply_tertiary_subtitle, :images
], coder: JSON
```

## Validation System

### ContentAttributeValidator

Located in [`app/models/concerns/content_attribute_validator.rb`](app/models/concerns/content_attribute_validator.rb)

**Key Methods**:
- `validate_apple_quick_reply_content_attributes`
- `validate_apple_list_picker_content_attributes` 
- `validate_apple_time_picker_content_attributes`

**Validation Rules**:
1. **Quick Reply**: Requires `summary_text` and `items` array
2. **List Picker**: Requires `sections` array with nested items
3. **Time Picker**: Requires `event` object with title

### Message Model Auto-Detection

The [`Message`](app/models/message.rb) model includes smart content type detection:

```ruby
def ensure_content_type
  return unless content_attributes.present?
  
  if content_attributes['sections'].present?
    self.content_type = 'apple_list_picker'
  elsif content_attributes['event'].present?
    self.content_type = 'apple_time_picker'
  elsif content_attributes['items'].present? && content_attributes['summary_text'].present?
    self.content_type = 'apple_quick_reply'
  end
end
```

## Frontend Implementation

### Component Structure

**Main Components**:
- [`AppleMessagesComposer.vue`](app/javascript/dashboard/components/widgets/conversation/AppleMessagesComposer.vue) - Message creation interface
- [`AppleMessagesButton.vue`](app/javascript/dashboard/components/widgets/conversation/AppleMessagesButton.vue) - Individual message type buttons
- [`ReplyBottomPanel.vue`](app/javascript/dashboard/components/widgets/conversation/ReplyBottomPanel.vue) - Container panel

### Event Flow

1. **User clicks message type** → `AppleMessagesButton` emits event
2. **Button event** → `AppleMessagesComposer` handles modal display
3. **Form submission** → `ReplyBottomPanel` receives data
4. **Message creation** → `ReplyBox` calls API with structured data

### API Integration

**Message Creation API**: [`app/javascript/dashboard/api/inbox/message.js`](app/javascript/dashboard/api/inbox/message.js)

```javascript
const buildCreatePayload = ({ 
  message, 
  contentType, 
  echoId, 
  file, 
  ccEmails, 
  bccEmails, 
  toEmails 
}) => {
  let payload = new FormData();
  payload.append('content', message);
  payload.append('echo_id', echoId);
  
  if (contentType) {
    payload.append('content_type', contentType);
  }
  
  // Handle content_attributes for Apple Messages
  if (message.contentAttributes) {
    Object.keys(message.contentAttributes).forEach(key => {
      const value = message.contentAttributes[key];
      if (typeof value === 'object') {
        payload.append(`content_attributes[${key}]`, JSON.stringify(value));
      } else {
        payload.append(`content_attributes[${key}]`, value);
      }
    });
  }
  
  return payload;
};
```

## Backend Implementation

### Message Builder

**File**: [`app/builders/messages/message_builder.rb`](app/builders/messages/message_builder.rb)

**Key Features**:
- Handles content type detection
- Validates message structure
- Generates unique identifiers for interactive elements

### Apple Messages Service

**File**: [`app/services/apple_messages_for_business/send_on_apple_messages_for_business_service.rb`](app/services/apple_messages_for_business/send_on_apple_messages_for_business_service.rb)

**Routing Logic**:
```ruby
def perform
  case @message.content_type
  when 'apple_quick_reply'
    send_quick_reply_message
  when 'apple_list_picker'
    send_list_picker_message
  when 'apple_time_picker'
    send_time_picker_message
  else
    send_text_message
  end
end
```

## Debugging Tools

### 1. Rails Console Inspection

```ruby
# Check message structure
message = Message.find(MESSAGE_ID)
puts message.content_type
puts message.content_attributes.inspect

# Validate message
message.valid?
puts message.errors.full_messages
```

### 2. Log Analysis

**Development Logs**: `tail -f log/development.log`

**Key Log Patterns**:
- Message creation: `Processing by Api::V1::Accounts::Conversations::MessagesController#create`
- Validation errors: `Content attributes [field] is required`
- Apple Messages routing: `🔥 SendOnAppleMessagesForBusinessService`

### 3. Database Queries

```sql
-- Find messages by content type
SELECT id, content_type, content_attributes 
FROM messages 
WHERE content_type LIKE 'apple_%';

-- Check for validation issues
SELECT id, content_type, content_attributes 
FROM messages 
WHERE content_type = 'apple_quick_reply' 
AND content_attributes NOT LIKE '%received_title%';
```

### 4. Frontend Debugging

**Browser Console**:
```javascript
// Check message payload before sending
console.log('Message payload:', messageData);

// Inspect content attributes
console.log('Content attributes:', message.contentAttributes);
```

## UI Customization

### Apple Messages Modal Customization

The Apple Messages composer modal can be customized through several key files:

#### 1. Modal Structure

**File**: [`AppleMessagesComposer.vue`](app/javascript/dashboard/components/widgets/conversation/AppleMessagesComposer.vue)

**Key Sections**:
- **Header**: Modal title and close button
- **Form Fields**: Input fields for each message type
- **Preview**: Real-time preview of message appearance
- **Actions**: Send/Cancel buttons

#### 2. Styling Customization

**CSS Classes** (using Tailwind):
```vue
<template>
  <div class="apple-messages-modal">
    <!-- Modal Header -->
    <div class="flex items-center justify-between p-4 border-b">
      <h3 class="text-lg font-medium text-slate-800">
        {{ modalTitle }}
      </h3>
      <button class="text-slate-400 hover:text-slate-600">
        <fluent-icon icon="dismiss" size="20" />
      </button>
    </div>
    
    <!-- Form Content -->
    <div class="p-6 space-y-4">
      <!-- Quick Reply Fields -->
      <div v-if="messageType === 'quick_reply'">
        <label class="block text-sm font-medium text-slate-700 mb-2">
          Question Text
        </label>
        <input 
          v-model="formData.summaryText"
          class="w-full px-3 py-2 border border-slate-300 rounded-md focus:ring-2 focus:ring-blue-500"
          placeholder="Enter your question"
        />
      </div>
      
      <!-- UI Customization Fields -->
      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">
            Received Title
          </label>
          <input 
            v-model="formData.receivedTitle"
            class="w-full px-3 py-2 border border-slate-300 rounded-md"
            placeholder="Please select an option"
          />
        </div>
        
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">
            Received Style
          </label>
          <select 
            v-model="formData.receivedStyle"
            class="w-full px-3 py-2 border border-slate-300 rounded-md"
          >
            <option value="small">Small</option>
            <option value="large">Large</option>
          </select>
        </div>
      </div>
    </div>
  </div>
</template>
```

#### 3. Form Field Configuration

**Available UI Customization Fields**:

**For All Message Types**:
- `received_title`: Title shown to customer
- `received_subtitle`: Subtitle shown to customer  
- `received_style`: Display style ("small" or "large")
- `reply_title`: Template for reply confirmation
- `reply_subtitle`: Subtitle for reply confirmation
- `reply_style`: Reply display style ("icon" or "large")

**Advanced Fields**:
- `reply_image_title`: Title for image-based replies
- `reply_image_subtitle`: Subtitle for image-based replies
- `reply_secondary_subtitle`: Secondary subtitle text
- `reply_tertiary_subtitle`: Tertiary subtitle text

#### 4. Dynamic Field Rendering

```vue
<script setup>
const fieldConfig = {
  quick_reply: [
    { key: 'summaryText', label: 'Question Text', type: 'text', required: true },
    { key: 'receivedTitle', label: 'Received Title', type: 'text' },
    { key: 'receivedStyle', label: 'Received Style', type: 'select', options: ['small', 'large'] },
    { key: 'replyTitle', label: 'Reply Title Template', type: 'text' },
    { key: 'replyStyle', label: 'Reply Style', type: 'select', options: ['icon', 'large'] }
  ],
  list_picker: [
    { key: 'receivedTitle', label: 'List Title', type: 'text', required: true },
    { key: 'receivedStyle', label: 'Display Style', type: 'select', options: ['small', 'large'] },
    { key: 'replyTitle', label: 'Selection Confirmation', type: 'text' }
  ],
  time_picker: [
    { key: 'eventTitle', label: 'Event Title', type: 'text', required: true },
    { key: 'eventSubtitle', label: 'Event Description', type: 'text' },
    { key: 'timezoneOffset', label: 'Timezone Offset', type: 'number' }
  ]
};

const renderField = (field) => {
  return {
    text: () => h('input', { 
      type: 'text', 
      value: formData[field.key],
      onInput: (e) => formData[field.key] = e.target.value 
    }),
    select: () => h('select', {
      value: formData[field.key],
      onChange: (e) => formData[field.key] = e.target.value
    }, field.options.map(opt => h('option', { value: opt }, opt)))
  }[field.type]();
};
</script>
```

#### 5. Preview Component

**Real-time Preview**:
```vue
<div class="preview-section bg-slate-50 p-4 rounded-lg">
  <h4 class="text-sm font-medium text-slate-700 mb-3">Preview</h4>
  
  <!-- Quick Reply Preview -->
  <div v-if="messageType === 'quick_reply'" class="space-y-2">
    <div class="bg-white p-3 rounded-lg shadow-sm">
      <p class="text-sm text-slate-800">{{ formData.summaryText }}</p>
      <p class="text-xs text-slate-500 mt-1">{{ formData.receivedTitle }}</p>
    </div>
    
    <div class="flex gap-2">
      <button 
        v-for="item in formData.items" 
        :key="item.title"
        class="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm"
      >
        {{ item.title }}
      </button>
    </div>
  </div>
</div>
```

#### 6. Internationalization

**Translation Keys** in [`app/javascript/dashboard/i18n/locale/en/inboxMgmt.json`](app/javascript/dashboard/i18n/locale/en/inboxMgmt.json):

```json
{
  "APPLE_MESSAGES": {
    "COMPOSER": {
      "TITLE": "Apple Messages Composer",
      "QUICK_REPLY": {
        "TITLE": "Quick Reply",
        "SUMMARY_TEXT": "Question Text",
        "RECEIVED_TITLE": "Title for Customer",
        "RECEIVED_STYLE": "Display Style",
        "REPLY_TITLE": "Reply Confirmation"
      },
      "LIST_PICKER": {
        "TITLE": "List Picker",
        "SECTIONS": "List Sections",
        "ADD_SECTION": "Add Section",
        "ADD_ITEM": "Add Item"
      },
      "TIME_PICKER": {
        "TITLE": "Time Picker",
        "EVENT_TITLE": "Event Title",
        "EVENT_SUBTITLE": "Event Description"
      }
    }
  }
}
```

## Testing Checklist

### Pre-Deployment Checklist

- [ ] **Message Creation**
  - [ ] Quick Reply messages create successfully
  - [ ] List Picker messages create successfully  
  - [ ] Time Picker messages create successfully
  - [ ] Content type auto-detection works
  - [ ] Validation passes for all required fields

- [ ] **UI Display**
  - [ ] Messages display interactive elements (not plain text)
  - [ ] Buttons/pickers are clickable
  - [ ] UI customization fields apply correctly
  - [ ] Preview matches actual display

- [ ] **Backend Processing**
  - [ ] Messages save with correct content_type
  - [ ] Content attributes persist completely
  - [ ] Apple Messages service routes correctly
  - [ ] External API calls succeed

- [ ] **Error Handling**
  - [ ] Validation errors display clearly
  - [ ] Missing fields are caught and reported
  - [ ] Invalid data structures are rejected
  - [ ] Graceful fallback for unsupported types

### Manual Testing Steps

1. **Create Each Message Type**:
   ```bash
   # Test via Rails console
   Message.create!(
     content: "Test Quick Reply",
     content_type: "apple_quick_reply",
     content_attributes: {
       summary_text: "Test question?",
       items: [{"title" => "Yes"}, {"title" => "No"}],
       received_title: "Please choose",
       received_style: "small",
       reply_title: "You selected: ${item.title}",
       reply_style: "icon"
     },
     conversation_id: CONVERSATION_ID,
     account_id: ACCOUNT_ID,
     inbox_id: INBOX_ID,
     sender: User.first
   )
   ```

2. **Verify UI Display**:
   - Check conversation transcript shows interactive elements
   - Verify buttons/pickers are functional
   - Test customer interaction flow

3. **Test Edge Cases**:
   - Empty content_attributes
   - Missing required fields
   - Invalid content_type values
   - Large data payloads

### Automated Testing

**RSpec Examples**:
```ruby
# spec/models/message_spec.rb
describe Message do
  describe 'Apple Messages validation' do
    it 'validates quick reply content attributes' do
      message = build(:message, 
        content_type: 'apple_quick_reply',
        content_attributes: {
          summary_text: 'Question?',
          items: [{ title: 'Yes' }]
        }
      )
      expect(message).to be_valid
    end
    
    it 'requires summary_text for quick replies' do
      message = build(:message,
        content_type: 'apple_quick_reply', 
        content_attributes: { items: [{ title: 'Yes' }] }
      )
      expect(message).not_to be_valid
      expect(message.errors[:content_attributes]).to include(/summary_text/)
    end
  end
end
```

## Troubleshooting Quick Reference

| Issue | Check | Solution |
|-------|-------|----------|
| Plain text display | `content_type` field | Set to `apple_quick_reply/list_picker/time_picker` |
| Validation errors | Required fields | Add missing `summary_text`, `sections`, or `event` |
| Missing UI fields | Store accessors | Add keys to Message model store accessor |
| Frontend data loss | Controller params | Update `create_params` method |
| API failures | Logs | Check `log/development.log` for errors |

## Support Resources

### Apple Messages for Business Specifications

- **API Tutorial**: [`_apple/msp-api-tutorial/`](_apple/msp-api-tutorial/) - Complete API implementation guide
  - [Quick Reply Messages](_apple/msp-api-tutorial/src/docs/quick-reply.md)
  - [List & Time Pickers](_apple/msp-api-tutorial/src/docs/list-time-pickers.md)
  - [Advanced Interactive Messaging](_apple/msp-api-tutorial/src/docs/advanced-interactive-messaging.md)
  - [Authentication](_apple/msp-api-tutorial/src/docs/authentication.md)

- **REST API Reference**: [`_apple/msp-rest-api/`](_apple/msp-rest-api/) - Detailed API specifications
  - [Interactive Message Types](_apple/msp-rest-api/src/docs/type-interactive.md)
  - [Message Construction](_apple/msp-rest-api/src/docs/construct-payload.md)
  - [Common Specifications](_apple/msp-rest-api/src/docs/common-specs.md)
  - [Sample Payloads](_apple/msp-rest-api/src/resources/payloads/)

- **MSP Onboarding**: [`_apple/msp-onboarding/`](_apple/msp-onboarding/) - Setup and integration guide
  - [Business Development](_apple/msp-onboarding/src/docs/business-dev.md)
  - [MSP Registration](_apple/msp-onboarding/src/docs/mspRegistration.md)
  - [Integration Guide](_apple/msp-onboarding/src/docs/integration.md)

- **Sample Code**: [`_apple/sample_python/`](_apple/sample_python/) - Python implementation examples
  - [List Picker Examples](_apple/sample_python/06_send_text_list_picker.py)
  - [Image List Picker](_apple/sample_python/07_send_list_picker_with_image.py)

### Development Resources

- **Chatwoot API Reference**: [API Documentation](https://www.chatwoot.com/developers/api/)
- **Vue.js Components**: [Vue 3 Documentation](https://vuejs.org/)
- **Rails Validation**: [Active Record Validations](https://guides.rubyonrails.org/active_record_validations.html)

---

*Last Updated: September 2025*
*Version: 1.0*