# Apple Messages for Business - Save as Template Feature

## Overview

The "Save as Template" feature allows agents to convert sent Apple Messages into reusable templates. This streamlines workflow by enabling agents to save successful message patterns and reuse them across conversations.

### Key Benefits

- **Time Savings**: Convert proven message patterns into reusable templates instantly
- **Consistency**: Ensure consistent messaging across customer interactions
- **Knowledge Capture**: Preserve effective message configurations for team reuse
- **Quick Access**: Saved templates are accessible via the `/` shortcut in the composer
- **Multi-Channel**: Templates work across all supported channels including Apple Messages for Business

### Where It Appears

The "Save as Template" button appears in the message context menu for outgoing Apple Messages for Business messages that include:

- List Pickers
- Time Pickers
- Apple Pay requests
- Quick Replies
- Rich Links
- Custom Forms
- Interactive Messages

## User Guide

### How to Save a Message as Template

1. **Send an Apple Messages for Business message**
   - Create and send any interactive message (List Picker, Time Picker, Form, etc.)
   - Wait for the message to be successfully sent

2. **Open the context menu**
   - Right-click on the sent message
   - Or click the three-dot menu icon on the message bubble

3. **Select "Save as Template"**
   - Click the "Save as Template" option from the menu
   - A modal dialog will appear with a suggested template configuration

4. **Review and customize**
   - **Name**: Auto-generated based on message type (e.g., "List Picker - Product Selection")
   - **Shortcode**: Auto-generated kebab-case shortcode (e.g., `/list-picker-product-selection`)
   - **Category**: Suggested category based on content (e.g., "support", "scheduling", "payment")
   - **Description**: Auto-generated description of the template's purpose
   - **Tags**: Suggested tags for easy searching

5. **Save the template**
   - Review the auto-generated configuration
   - Edit any fields as needed
   - Click "Save Template"
   - The template is immediately available for use

### How to Use Saved Templates

1. **In the composer, type `/`**
   - The template selector will appear
   - Type to search by name, shortcode, or tags

2. **Select your template**
   - Click on the desired template
   - Or use arrow keys and press Enter

3. **Customize parameters**
   - Fill in any required parameters (names, dates, amounts, etc.)
   - Preview the message in real-time

4. **Send the message**
   - Review the final message
   - Click Send

### Template Name and Shortcode Generation

The system automatically generates intuitive names and shortcodes:

| Message Type | Name Pattern | Shortcode Pattern |
|--------------|--------------|-------------------|
| List Picker | `List Picker - {title}` | `/list-picker-{title}` |
| Time Picker | `Time Picker - {title}` | `/time-picker-{title}` |
| Apple Pay | `Apple Pay - {description}` | `/apple-pay-{description}` |
| Form | `Form - {title}` | `/form-{title}` |
| Quick Reply | `Quick Reply - {question}` | `/quick-reply-{question}` |
| Rich Link | `Rich Link - {title}` | `/rich-link-{title}` |

**Example**: A List Picker message with title "Choose Your Appointment" becomes:
- Name: `List Picker - Choose Your Appointment`
- Shortcode: `/list-picker-choose-your-appointment`

## Technical Details

### Message Type to Template Conversion Logic

The system uses intelligent extraction to convert Apple Messages properties into template content blocks:

#### List Picker Conversion

```ruby
# Source: content_attributes
{
  "title": "Select a service",
  "subtitle": "Choose from our services",
  "multipleSelection": false,
  "sections": [
    {
      "title": "Services",
      "items": [
        {
          "identifier": "service-1",
          "title": "Oil Change",
          "subtitle": "$49.99",
          "imageIdentifier": "oil-change-img"
        }
      ]
    }
  ],
  "images": [...]
}

# Becomes: Template Content Block
{
  "block_type": "apple_list_picker",
  "properties": {
    "title": "Select a service",
    "subtitle": "Choose from our services",
    "multipleSelection": false,
    "sections": [...],
    "images": [...]
  },
  "order_index": 0
}

# With Parameters
{
  "service_name": {
    "type": "string",
    "required": true,
    "description": "Name of the service",
    "example": "Oil Change"
  }
}
```

#### Time Picker Conversion

```ruby
# Source: content_attributes
{
  "event": {
    "identifier": "apt-001",
    "title": "Schedule Appointment",
    "timeslots": [...]
  },
  "receivedMessage": {
    "title": "Select your appointment time",
    "imageIdentifier": "calendar-img"
  },
  "replyMessage": {
    "title": "Appointment confirmed!",
    "imageIdentifier": "calendar-img"
  }
}

# Becomes: Template Content Block
{
  "block_type": "apple_time_picker",
  "properties": {
    "event": {...},
    "receivedMessage": {...},
    "replyMessage": {...}
  },
  "order_index": 0
}
```

#### Apple Pay Conversion

```ruby
# Source: content_attributes
{
  "paymentRequest": {
    "merchantIdentifier": "merchant.com.example",
    "merchantName": "Example Store",
    "lineItems": [...]
  }
}

# Becomes: Template Content Block
{
  "block_type": "apple_pay",
  "properties": {
    "paymentRequest": {...}
  },
  "order_index": 0
}
```

#### Form Conversion

```ruby
# Source: content_attributes
{
  "formConfig": {
    "title": "Contact Form",
    "pages": [...],
    "receivedMessage": {...},
    "replyMessage": {...}
  }
}

# Becomes: Template Content Block
{
  "block_type": "apple_form",
  "properties": {
    "formConfig": {...}
  },
  "order_index": 0
}
```

### Database Schema

#### MessageTemplate Table

```ruby
create_table "message_templates" do |t|
  t.bigint "account_id", null: false
  t.string "name", null: false
  t.string "category"
  t.text "description"
  t.string "status", default: "active"
  t.text "supported_channels", array: true, default: []
  t.text "tags", array: true, default: []
  t.text "use_cases", array: true, default: []
  t.jsonb "parameters", default: {}
  t.jsonb "metadata", default: {}
  t.integer "version", default: 1
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false

  t.index ["account_id"]
  t.index ["account_id", "category"]
  t.index ["account_id", "status"]
  t.index ["supported_channels"], using: :gin
  t.index ["tags"], using: :gin
end
```

#### TemplateContentBlock Table

```ruby
create_table "template_content_blocks" do |t|
  t.bigint "message_template_id", null: false
  t.string "block_type", null: false
  t.jsonb "properties", default: {}
  t.jsonb "conditions", default: {}
  t.integer "order_index", default: 0
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false

  t.index ["message_template_id"]
  t.index ["block_type"]
end
```

## API Documentation

### Endpoint

```
POST /api/v1/accounts/:account_id/templates/from_apple_message
```

**Authentication**: Required (Bearer token)

**Authorization**: Administrator role required

### Request Structure

#### Headers

```http
Content-Type: application/json
Authorization: Bearer <access_token>
```

#### Body

```json
{
  "message_id": 12345,
  "name": "Custom Template Name (optional)",
  "category": "support (optional)",
  "tags": ["appointment", "scheduling"] (optional),
  "description": "Custom description (optional)"
}
```

**Parameters**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `message_id` | integer | Yes | ID of the message to convert to template |
| `name` | string | No | Custom template name (auto-generated if omitted) |
| `category` | string | No | Template category (auto-detected if omitted) |
| `tags` | array | No | Custom tags (auto-generated if omitted) |
| `description` | string | No | Template description (auto-generated if omitted) |

### Response Examples

#### List Picker Template

**Request**:
```json
{
  "message_id": 12345
}
```

**Response** (201 Created):
```json
{
  "id": 789,
  "name": "List Picker - Service Selection",
  "category": "support",
  "description": "Interactive list picker for service selection",
  "status": "active",
  "supportedChannels": ["apple_messages_for_business"],
  "tags": ["list-picker", "services", "selection"],
  "useCases": ["service_booking", "product_selection"],
  "parameters": {
    "service_title": {
      "type": "string",
      "required": true,
      "description": "Title of the service section",
      "example": "Services"
    }
  },
  "contentBlocks": [
    {
      "id": 1234,
      "blockType": "apple_list_picker",
      "properties": {
        "title": "Select a service",
        "subtitle": "Choose from our available services",
        "multipleSelection": false,
        "sections": [...]
      },
      "orderIndex": 0
    }
  ],
  "version": 1,
  "createdAt": "2025-10-10T12:00:00Z",
  "updatedAt": "2025-10-10T12:00:00Z"
}
```

#### Time Picker Template

**Request**:
```json
{
  "message_id": 12346,
  "name": "Appointment Booking",
  "tags": ["appointments", "scheduling", "calendar"]
}
```

**Response** (201 Created):
```json
{
  "id": 790,
  "name": "Appointment Booking",
  "category": "scheduling",
  "description": "Time picker for appointment booking",
  "status": "active",
  "supportedChannels": ["apple_messages_for_business"],
  "tags": ["appointments", "scheduling", "calendar"],
  "useCases": ["appointment_booking", "time_selection"],
  "parameters": {
    "event_title": {
      "type": "string",
      "required": true,
      "description": "Title of the event",
      "example": "Appointment Booking"
    },
    "duration_minutes": {
      "type": "integer",
      "required": true,
      "description": "Duration in minutes",
      "example": 30
    }
  },
  "contentBlocks": [
    {
      "id": 1235,
      "blockType": "apple_time_picker",
      "properties": {
        "event": {...},
        "receivedMessage": {...},
        "replyMessage": {...}
      },
      "orderIndex": 0
    }
  ],
  "version": 1,
  "createdAt": "2025-10-10T12:05:00Z",
  "updatedAt": "2025-10-10T12:05:00Z"
}
```

#### Apple Pay Template

**Request**:
```json
{
  "message_id": 12347,
  "category": "payment"
}
```

**Response** (201 Created):
```json
{
  "id": 791,
  "name": "Apple Pay - Product Purchase",
  "category": "payment",
  "description": "Apple Pay payment request for product purchase",
  "status": "active",
  "supportedChannels": ["apple_messages_for_business"],
  "tags": ["apple-pay", "payment", "checkout"],
  "useCases": ["payment_collection", "checkout"],
  "parameters": {
    "total_amount": {
      "type": "string",
      "required": true,
      "description": "Total payment amount",
      "example": "49.99"
    },
    "currency_code": {
      "type": "string",
      "required": true,
      "description": "Currency code (ISO 4217)",
      "example": "USD"
    }
  },
  "contentBlocks": [
    {
      "id": 1236,
      "blockType": "apple_pay",
      "properties": {
        "paymentRequest": {...}
      },
      "orderIndex": 0
    }
  ],
  "version": 1,
  "createdAt": "2025-10-10T12:10:00Z",
  "updatedAt": "2025-10-10T12:10:00Z"
}
```

#### Form Template

**Request**:
```json
{
  "message_id": 12348,
  "name": "Customer Feedback Form",
  "tags": ["feedback", "survey"]
}
```

**Response** (201 Created):
```json
{
  "id": 792,
  "name": "Customer Feedback Form",
  "category": "feedback",
  "description": "Interactive form for collecting customer feedback",
  "status": "active",
  "supportedChannels": ["apple_messages_for_business"],
  "tags": ["feedback", "survey"],
  "useCases": ["feedback_collection", "surveys"],
  "parameters": {
    "form_title": {
      "type": "string",
      "required": true,
      "description": "Title of the form",
      "example": "Customer Feedback"
    }
  },
  "contentBlocks": [
    {
      "id": 1237,
      "blockType": "apple_form",
      "properties": {
        "formConfig": {...}
      },
      "orderIndex": 0
    }
  ],
  "version": 1,
  "createdAt": "2025-10-10T12:15:00Z",
  "updatedAt": "2025-10-10T12:15:00Z"
}
```

### Error Responses

#### Message Not Found

**Status**: 404 Not Found

```json
{
  "error": "Message not found",
  "details": "Message with ID 12345 does not exist"
}
```

#### Unsupported Message Type

**Status**: 422 Unprocessable Entity

```json
{
  "error": "Unsupported message type",
  "details": "Only Apple Messages for Business interactive messages can be saved as templates"
}
```

#### Missing Required Data

**Status**: 422 Unprocessable Entity

```json
{
  "error": "Invalid message content",
  "details": "Message does not contain required content_attributes for template creation"
}
```

#### Duplicate Template Name

**Status**: 422 Unprocessable Entity

```json
{
  "error": "Template name already exists",
  "details": "A template with the name 'List Picker - Service Selection' already exists in this account"
}
```

#### Unauthorized

**Status**: 403 Forbidden

```json
{
  "error": "Unauthorized",
  "details": "Administrator access required to create templates"
}
```

## Developer Guide

### How to Add "Save as Template" to New Message Types

To enable "Save as Template" for a new Apple Messages message type:

#### 1. Add Message Type Detection

In `app/services/apple_messages_for_business/template_creator_service.rb`:

```ruby
class AppleMessagesForBusiness::TemplateCreatorService
  # Add your new message type to SUPPORTED_TYPES
  SUPPORTED_TYPES = %w[
    list_picker
    time_picker
    apple_pay
    form
    quick_reply
    rich_link
    your_new_type  # Add here
  ].freeze

  def detect_message_type
    return 'your_new_type' if content_attributes['yourNewTypeData'].present?
    # ... existing detection logic
  end
end
```

#### 2. Create Content Block Extractor

Add a new method to extract content block properties:

```ruby
def extract_your_new_type_properties
  {
    block_type: 'apple_your_new_type',
    properties: {
      # Extract relevant properties from content_attributes
      title: content_attributes.dig('yourNewTypeData', 'title'),
      description: content_attributes.dig('yourNewTypeData', 'description'),
      # ... other properties
    },
    order_index: 0
  }
end
```

#### 3. Create Parameter Extractor

Add a method to extract dynamic parameters:

```ruby
def extract_your_new_type_parameters
  parameters = {}

  # Example: Extract title as parameter if it exists
  if content_attributes.dig('yourNewTypeData', 'title').present?
    parameters['title'] = {
      type: 'string',
      required: true,
      description: 'Title of the message',
      example: content_attributes.dig('yourNewTypeData', 'title')
    }
  end

  parameters
end
```

#### 4. Add Name Generation Logic

In the `generate_template_name` method:

```ruby
def generate_template_name
  case @message_type
  when 'your_new_type'
    title = content_attributes.dig('yourNewTypeData', 'title')
    "Your New Type - #{title || 'Untitled'}"
  # ... existing cases
  end
end
```

#### 5. Add Category Detection

In the `detect_category` method:

```ruby
def detect_category
  case @message_type
  when 'your_new_type'
    # Return appropriate category based on content
    'support' # or 'notification', 'marketing', etc.
  # ... existing cases
  end
end
```

#### 6. Register Block Type

In `app/models/template_content_block.rb`:

```ruby
class TemplateContentBlock < ApplicationRecord
  BLOCK_TYPES = %w[
    text
    apple_list_picker
    apple_time_picker
    apple_pay
    apple_form
    apple_quick_reply
    apple_rich_link
    apple_your_new_type  # Add here
  ].freeze

  validates :block_type, inclusion: { in: BLOCK_TYPES }
end
```

#### 7. Add Frontend Support

In the message context menu (`MessageContextMenu.vue`):

```vue
<script>
export default {
  computed: {
    canSaveAsTemplate() {
      const supportedTypes = [
        'list_picker',
        'time_picker',
        'apple_pay',
        'form',
        'quick_reply',
        'rich_link',
        'your_new_type'  // Add here
      ];

      const contentType = this.contentAttributes?.apple_msp_type;
      return supportedTypes.includes(contentType);
    }
  }
}
</script>
```

### Name Generation Patterns

The system follows consistent naming patterns for generated template names:

```ruby
class AppleMessagesForBusiness::TemplateCreatorService
  def generate_template_name
    case @message_type
    when 'list_picker'
      title = content_attributes.dig('title') || 'Selection'
      "List Picker - #{title.titleize}"

    when 'time_picker'
      event_title = content_attributes.dig('event', 'title') || 'Appointment'
      "Time Picker - #{event_title.titleize}"

    when 'apple_pay'
      merchant = content_attributes.dig('paymentRequest', 'merchantName')
      "Apple Pay - #{merchant || 'Payment Request'}"

    when 'form'
      form_title = content_attributes.dig('formConfig', 'title') || 'Form'
      "Form - #{form_title.titleize}"

    when 'quick_reply'
      question = content_attributes.dig('quickReply', 'question')
      "Quick Reply - #{question&.truncate(50) || 'Question'}"

    when 'rich_link'
      title = content_attributes.dig('richLink', 'title') || 'Link'
      "Rich Link - #{title.titleize}"
    end
  end

  def generate_shortcode(name)
    # Convert to kebab-case, remove special chars, truncate
    name.parameterize(separator: '-').truncate(50, omission: '')
  end
end
```

### Customizing Template Suggestions

To customize how templates are suggested and categorized:

```ruby
class AppleMessagesForBusiness::TemplateCreatorService
  # Customize category detection based on content analysis
  def detect_category
    # Analyze content for keywords
    content_text = extract_all_text.downcase

    return 'payment' if content_text.include?('pay') || content_text.include?('price')
    return 'scheduling' if content_text.include?('appointment') || content_text.include?('time')
    return 'support' if content_text.include?('help') || content_text.include?('support')
    return 'feedback' if content_text.include?('feedback') || content_text.include?('survey')

    'notification' # Default category
  end

  # Generate smart tags based on content
  def generate_tags
    tags = [@message_type.parameterize]
    content_text = extract_all_text.downcase

    # Add contextual tags
    tags << 'urgent' if content_text.include?('urgent') || content_text.include?('asap')
    tags << 'confirmation' if content_text.include?('confirm') || content_text.include?('verified')
    tags << 'reminder' if content_text.include?('remind') || content_text.include?('upcoming')

    # Add category-based tags
    tags << 'transactional' if detect_category == 'payment'
    tags << 'interactive' if ['list_picker', 'time_picker', 'form'].include?(@message_type)

    tags.uniq
  end

  # Extract use cases based on message analysis
  def extract_use_cases
    use_cases = []

    case @message_type
    when 'list_picker'
      use_cases << 'product_selection'
      use_cases << 'service_booking' if content_includes?('service', 'appointment')
    when 'time_picker'
      use_cases << 'appointment_booking'
      use_cases << 'event_registration' if content_includes?('event', 'register')
    when 'apple_pay'
      use_cases << 'payment_collection'
      use_cases << 'checkout'
    when 'form'
      use_cases << 'data_collection'
      use_cases << 'feedback_collection' if content_includes?('feedback', 'survey')
    end

    use_cases
  end

  private

  def content_includes?(*keywords)
    content_text = extract_all_text.downcase
    keywords.any? { |keyword| content_text.include?(keyword) }
  end

  def extract_all_text
    # Extract all text content from the message for analysis
    [
      content_attributes.dig('title'),
      content_attributes.dig('subtitle'),
      content_attributes.dig('event', 'title'),
      content_attributes.dig('formConfig', 'title'),
      # ... extract from all relevant fields
    ].compact.join(' ')
  end
end
```

## Screenshots

### Context Menu with "Save as Template" Option

```
[Screenshot placeholder: Message bubble with right-click context menu showing "Save as Template" option]
```

### Template Creation Modal

```
[Screenshot placeholder: Modal dialog showing auto-generated template configuration with fields for name, category, tags, and description]
```

### Template Selector in Composer

```
[Screenshot placeholder: Composer with / shortcut showing list of templates with search functionality]
```

### Template Preview

```
[Screenshot placeholder: Template preview showing the rendered message with parameter placeholders]
```

## Code Examples

### Backend: Template Creation Service

```ruby
# app/services/apple_messages_for_business/template_creator_service.rb
class AppleMessagesForBusiness::TemplateCreatorService
  def initialize(message, custom_attributes = {})
    @message = message
    @custom_attributes = custom_attributes
    @content_attributes = message.content_attributes || {}
    @message_type = detect_message_type
  end

  def create_template
    return { error: 'Unsupported message type' } unless supported_message_type?

    template = MessageTemplate.create!(
      account: @message.account,
      name: custom_name || generate_template_name,
      category: custom_category || detect_category,
      description: custom_description || generate_description,
      status: 'active',
      supported_channels: ['apple_messages_for_business'],
      tags: custom_tags || generate_tags,
      use_cases: extract_use_cases,
      parameters: extract_parameters,
      version: 1
    )

    create_content_blocks(template)

    { success: true, template: template }
  rescue StandardError => e
    { error: 'Failed to create template', details: e.message }
  end

  private

  def detect_message_type
    return 'list_picker' if @content_attributes['sections'].present?
    return 'time_picker' if @content_attributes['event'].present?
    return 'apple_pay' if @content_attributes['paymentRequest'].present?
    return 'form' if @content_attributes['formConfig'].present?
    return 'quick_reply' if @content_attributes['quickReply'].present?
    return 'rich_link' if @content_attributes['richLink'].present?

    nil
  end

  def create_content_blocks(template)
    block_data = case @message_type
                 when 'list_picker'
                   extract_list_picker_properties
                 when 'time_picker'
                   extract_time_picker_properties
                 when 'apple_pay'
                   extract_apple_pay_properties
                 when 'form'
                   extract_form_properties
                 end

    template.content_blocks.create!(block_data) if block_data
  end
end
```

### Frontend: Save as Template Action

```vue
<!-- MessageContextMenu.vue -->
<script setup>
import { ref } from 'vue';
import { useAlert } from 'dashboard/composables';
import TemplatesAPI from 'dashboard/api/templates';

const props = defineProps({
  message: { type: Object, required: true }
});

const emit = defineEmits(['close']);

const saving = ref(false);

const canSaveAsTemplate = computed(() => {
  const contentType = props.message.contentAttributes?.apple_msp_type;
  const supportedTypes = [
    'list_picker',
    'time_picker',
    'apple_pay',
    'form',
    'quick_reply',
    'rich_link'
  ];
  return supportedTypes.includes(contentType);
});

const handleSaveAsTemplate = async () => {
  saving.value = true;

  try {
    const response = await TemplatesAPI.createFromAppleMessage({
      messageId: props.message.id
    });

    useAlert('Template created successfully!');
    emit('close');
  } catch (error) {
    useAlert('Failed to create template: ' + error.message);
  } finally {
    saving.value = false;
  }
};
</script>

<template>
  <MenuItem
    v-if="canSaveAsTemplate"
    icon="i-lucide-bookmark-plus"
    :disabled="saving"
    @click="handleSaveAsTemplate"
  >
    {{ $t('CONVERSATION.CONTEXT_MENU.SAVE_AS_TEMPLATE') }}
  </MenuItem>
</template>
```

### API Client

```javascript
// app/javascript/dashboard/api/templates.js
class TemplatesAPI extends ApiClient {
  constructor() {
    super('templates', { accountScoped: true });
  }

  createFromAppleMessage(data) {
    return axios.post(`${this.url}/from_apple_message`, data);
  }
}

export default new TemplatesAPI();
```

## Related Documentation

- [Unified Template System Architecture](./UNIFIED_TEMPLATE_SYSTEM_ARCHITECTURE.md)
- [Template Migration Guide](./TEMPLATE_MIGRATION_GUIDE.md)
- [Apple Messages for Business Integration](./apple-messages/README.md)
- [Apple MSP Outgoing Services](./apple-messages/APPLE_MSP_OUTGOING_SERVICES.md)

## Best Practices

1. **Use Descriptive Names**: Create clear, searchable template names
2. **Add Relevant Tags**: Tag templates for easy discovery
3. **Document Parameters**: Provide clear descriptions for required parameters
4. **Test Templates**: Preview and test templates before sharing with team
5. **Version Control**: Create new versions for significant changes
6. **Regular Cleanup**: Archive outdated templates
7. **Permissions**: Restrict template creation to administrators
8. **Validation**: Ensure templates work across all target channels

## Troubleshooting

### Template Not Created

**Issue**: "Save as Template" fails silently

**Solutions**:
- Verify message has `content_attributes` with complete data
- Check message type is supported
- Ensure user has administrator permissions
- Check Rails logs for validation errors

### Template Missing Parameters

**Issue**: Template created but parameters not extracted

**Solutions**:
- Verify `content_attributes` structure matches expected format
- Check parameter extraction logic for message type
- Review template content blocks for missing properties

### Template Not Appearing in Selector

**Issue**: Saved template doesn't show in `/` selector

**Solutions**:
- Verify template status is "active"
- Check supported_channels includes current inbox channel
- Refresh the page to reload template cache
- Search by shortcode instead of name

### Images Not Saving with Template

**Issue**: Images referenced in template but not included

**Solutions**:
- Ensure images are stored in `AppleListPickerImage` model
- Verify `imageIdentifier` is correctly mapped in content blocks
- Check image storage permissions and availability

---

**Last Updated**: 2025-10-10

**Version**: 1.0.0

**Maintained By**: Chatwoot Development Team
