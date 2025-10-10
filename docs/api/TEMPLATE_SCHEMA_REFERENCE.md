# Template Schema Reference

## Overview

This document provides a complete reference for the JSON schema used to define message templates in the Unified Template System. Templates define reusable, parameterized rich message structures that can be adapted across different messaging channels.

## Template Schema

### Root Template Object

```json
{
  "id": 123,
  "name": "template_name",
  "category": "scheduling",
  "description": "Template description",
  "parameters": {...},
  "supported_channels": ["apple_messages_for_business", "whatsapp", "web_widget"],
  "status": "active",
  "version": 1,
  "tags": ["tag1", "tag2"],
  "use_cases": ["use_case1", "use_case2"],
  "content_blocks": [...],
  "channel_mappings": {...}
}
```

### Field Definitions

#### `id` (integer, read-only)
Unique identifier for the template.

#### `name` (string, required)
Unique name for the template within the account. Used for identification and programmatic access.

**Constraints**:
- Required
- Must be unique within the account
- Recommended format: `snake_case`

**Example**: `"appointment_booking"`, `"payment_request"`, `"support_escalation"`

#### `category` (string, optional)
Category classification for the template.

**Valid Values**:
- `payment` - Payment requests, invoices, receipts
- `scheduling` - Appointments, bookings, calendar events
- `support` - Customer support, help requests
- `marketing` - Promotions, announcements
- `feedback` - Surveys, ratings, reviews
- `notification` - Alerts, reminders, updates
- `confirmation` - Order confirmations, acknowledgments

**Example**: `"scheduling"`

#### `description` (string, optional)
Human-readable description of the template's purpose and usage.

**Example**: `"Template for booking appointments with time picker"`

#### `parameters` (object, optional)
Defines the parameters that must be provided when using this template. Each parameter is a key-value pair where the key is the parameter name and the value is a configuration object.

**Parameter Configuration Object**:

```json
{
  "parameter_name": {
    "type": "string|integer|boolean|array|object|datetime",
    "required": true|false,
    "description": "Parameter description",
    "default": "default_value",
    "example": "example_value"
  }
}
```

**Parameter Types**:

- `string` - Text value
- `integer` - Whole number
- `boolean` - `true` or `false`
- `array` - List of values
- `object` - Nested object/hash
- `datetime` - ISO 8601 datetime string

**Example**:

```json
{
  "business_name": {
    "type": "string",
    "required": true,
    "description": "Name of the business",
    "example": "Acme Corp"
  },
  "available_slots": {
    "type": "array",
    "required": true,
    "description": "Array of available appointment times (ISO 8601)",
    "example": ["2025-10-15T09:00:00Z", "2025-10-15T11:00:00Z"]
  },
  "appointment_duration": {
    "type": "integer",
    "required": false,
    "default": 60,
    "description": "Duration in minutes",
    "example": 30
  },
  "include_location": {
    "type": "boolean",
    "required": false,
    "default": false,
    "description": "Whether to include location information"
  }
}
```

#### `supported_channels` (array of strings, optional)
List of messaging channels that support this template.

**Valid Channel Values**:
- `apple_messages_for_business` - Apple Messages for Business
- `whatsapp` - WhatsApp Business
- `web_widget` - Web chat widget
- `sms` - SMS channel
- `email` - Email channel
- `telegram` - Telegram
- `line` - LINE
- `facebook` - Facebook Messenger
- `twitter` - Twitter/X DMs

**Example**: `["apple_messages_for_business", "whatsapp", "web_widget"]`

#### `status` (string, required)
Current status of the template.

**Valid Values**:
- `active` - Template is ready to use
- `draft` - Template is being edited
- `deprecated` - Template is old but still accessible

**Default**: `"active"`

#### `version` (integer, required)
Version number of the template. Increments when creating new versions.

**Default**: `1`

#### `tags` (array of strings, optional)
Searchable tags for template discovery.

**Example**: `["appointment", "scheduling", "time_picker", "urgent"]`

#### `use_cases` (array of strings, optional)
Specific use cases this template addresses.

**Example**: `["booking", "rescheduling", "cancellation"]`

## Content Block Schema

Content blocks are the building blocks of a template. Each block represents a specific type of content (text, button, picker, etc.).

### Content Block Object

```json
{
  "id": 456,
  "block_type": "time_picker",
  "order_index": 0,
  "properties": {...},
  "conditions": {...}
}
```

### Content Block Types

#### 1. `text`
Simple text message.

**Properties**:

```json
{
  "content": "Hello {{customer_name}}, welcome to {{business_name}}!",
  "style": "plain|bold|italic"
}
```

**Example**:

```json
{
  "block_type": "text",
  "order_index": 0,
  "properties": {
    "content": "Hi! {{business_name}} has these available slots:"
  }
}
```

#### 2. `media`
Image, video, or audio content.

**Properties**:

```json
{
  "type": "image|video|audio",
  "url": "https://example.com/media.jpg",
  "caption": "Optional caption text",
  "thumbnail_url": "https://example.com/thumb.jpg"
}
```

**Example**:

```json
{
  "block_type": "media",
  "order_index": 0,
  "properties": {
    "type": "image",
    "url": "{{product_image_url}}",
    "caption": "{{product_name}} - ${{price}}"
  }
}
```

#### 3. `button_group`
Group of interactive buttons.

**Properties**:

```json
{
  "buttons": [
    {
      "title": "Button text",
      "value": "button_value",
      "style": "primary|secondary|link"
    }
  ]
}
```

**Example**:

```json
{
  "block_type": "button_group",
  "order_index": 1,
  "properties": {
    "buttons": [
      {
        "title": "Confirm",
        "value": "confirm",
        "style": "primary"
      },
      {
        "title": "Cancel",
        "value": "cancel",
        "style": "secondary"
      }
    ]
  }
}
```

#### 4. `list_picker`
Interactive list selection.

**Properties**:

```json
{
  "title": "Select an option",
  "items": [
    {
      "identifier": "item_1",
      "title": "Item title",
      "subtitle": "Item subtitle",
      "imageIdentifier": "image_id",
      "order": 0
    }
  ],
  "multipleSelection": false
}
```

**Example**:

```json
{
  "block_type": "list_picker",
  "order_index": 0,
  "properties": {
    "title": "Choose a service",
    "items": "{{service_list}}",
    "multipleSelection": false
  }
}
```

#### 5. `time_picker`
Interactive datetime selection (Apple Messages for Business).

**Properties**:

```json
{
  "event": {
    "title": "Event title",
    "description": "Event description",
    "timeslots": [
      {
        "identifier": "slot_1",
        "startTime": "2025-10-15T09:00:00Z",
        "duration": 3600
      }
    ],
    "timezone": "America/New_York",
    "location": {
      "latitude": 40.7128,
      "longitude": -74.0060,
      "radius": 100,
      "title": "Location name"
    }
  },
  "receivedMessage": {
    "title": "Title shown to user",
    "subtitle": "Subtitle text",
    "imageIdentifier": "image_id",
    "style": "icon|small|large"
  },
  "replyMessage": {
    "title": "Confirmation title",
    "subtitle": "Confirmation subtitle",
    "imageIdentifier": "image_id"
  }
}
```

**Example**:

```json
{
  "block_type": "time_picker",
  "order_index": 1,
  "properties": {
    "event": {
      "title": "Schedule Appointment",
      "description": "{{appointment_description}}",
      "timeslots": "{{available_slots}}",
      "timezone": "{{timezone}}"
    },
    "receivedMessage": {
      "title": "Please pick a time",
      "style": "icon"
    },
    "replyMessage": {
      "title": "Great! We'll see you then"
    }
  }
}
```

#### 6. `quick_reply`
Quick response suggestions.

**Properties**:

```json
{
  "items": [
    {
      "title": "Reply text",
      "value": "reply_value",
      "imageUrl": "https://example.com/icon.png"
    }
  ]
}
```

**Example**:

```json
{
  "block_type": "quick_reply",
  "order_index": 2,
  "properties": {
    "items": [
      {"title": "Yes", "value": "yes"},
      {"title": "No", "value": "no"},
      {"title": "Maybe", "value": "maybe"}
    ]
  }
}
```

#### 7. `payment_request` / `apple_pay`
Payment request (Apple Pay).

**Properties**:

```json
{
  "payment": {
    "merchantIdentifier": "merchant.com.example",
    "merchantName": "Acme Corp",
    "countryCode": "US",
    "currencyCode": "USD",
    "lineItems": [
      {
        "label": "Item name",
        "amount": "10.00",
        "type": "final"
      }
    ],
    "total": {
      "label": "Total",
      "amount": "10.00",
      "type": "final"
    },
    "supportedNetworks": ["visa", "mastercard", "amex"],
    "merchantCapabilities": ["supports3DS"]
  },
  "receivedMessage": {
    "title": "Payment Request",
    "subtitle": "Tap to pay",
    "imageIdentifier": "payment_icon"
  },
  "replyMessage": {
    "title": "Payment Successful",
    "subtitle": "Thank you!"
  }
}
```

**Example**:

```json
{
  "block_type": "apple_pay",
  "order_index": 0,
  "properties": {
    "payment": {
      "merchantName": "{{business_name}}",
      "currencyCode": "USD",
      "total": {
        "label": "{{service_name}}",
        "amount": "{{amount}}"
      }
    }
  }
}
```

#### 8. `form`
Interactive form (Apple Messages for Business).

**Properties**:

```json
{
  "form": {
    "title": "Form title",
    "fields": [
      {
        "identifier": "field_1",
        "title": "Field label",
        "type": "text|email|phone|number|date",
        "required": true,
        "placeholder": "Placeholder text"
      }
    ]
  },
  "receivedMessage": {
    "title": "Please fill out this form",
    "style": "icon"
  },
  "replyMessage": {
    "title": "Thanks for your response!"
  }
}
```

**Example**:

```json
{
  "block_type": "form",
  "order_index": 0,
  "properties": {
    "form": {
      "title": "Contact Information",
      "fields": "{{form_fields}}"
    },
    "receivedMessage": {
      "title": "Please provide your details"
    }
  }
}
```

#### 9. `location_picker`
Location selection interface.

**Properties**:

```json
{
  "title": "Select a location",
  "locations": [
    {
      "identifier": "loc_1",
      "title": "Location name",
      "latitude": 40.7128,
      "longitude": -74.0060,
      "radius": 100
    }
  ]
}
```

#### 10. `rich_link`
Rich preview link card.

**Properties**:

```json
{
  "url": "https://example.com",
  "title": "Link title",
  "description": "Link description",
  "imageUrl": "https://example.com/preview.jpg"
}
```

### Content Block Conditions

Conditions allow you to show/hide blocks based on parameter values.

**Conditions Object**:

```json
{
  "if": "{{parameter_name}} == 'value'"
}
```

**Supported Operators**:
- `==` - Equals
- `!=` - Not equals
- `>` - Greater than
- `<` - Less than
- `>=` - Greater than or equal
- `<=` - Less than or equal

**Examples**:

```json
{
  "conditions": {
    "if": "{{user_type}} == 'premium'"
  }
}
```

```json
{
  "conditions": {
    "if": "{{order_amount}} >= 100"
  }
}
```

## Channel Mapping Schema

Channel mappings define how template data is transformed for specific channels.

### Channel Mapping Object

```json
{
  "channel_type": "apple_messages_for_business",
  "content_type": "apple_time_picker",
  "field_mappings": {
    "target.field.path": "{{source_parameter}}",
    "event.title": "{{title}}",
    "event.timeslots": "{{available_slots}}"
  }
}
```

### Field Mappings

Field mappings use dot notation to specify nested field paths.

**Format**: `"target.path": "source.path"` or `"target.path": "{{parameter_name}}"`

**Examples**:

```json
{
  "field_mappings": {
    "event.title": "{{appointment_title}}",
    "event.description": "{{appointment_description}}",
    "receivedMessage.title": "{{received_title}}",
    "replyMessage.title": "{{reply_title}}"
  }
}
```

### Channel-Specific Adaptations

#### Apple Messages for Business

**Content Types**:
- `apple_time_picker` - Time picker interactive message
- `apple_list_picker` - List picker interactive message
- `apple_pay` - Apple Pay payment request
- `apple_form` - Form interactive message
- `apple_auth` - Authentication request

**Example Mapping**:

```json
{
  "channel_type": "apple_messages_for_business",
  "content_type": "apple_time_picker",
  "field_mappings": {
    "event.title": "{{event_title}}",
    "event.timeslots": "{{timeslots}}",
    "event.timezone": "{{timezone}}",
    "receivedMessage.title": "{{received_title}}",
    "receivedMessage.imageIdentifier": "{{image_id}}",
    "replyMessage.title": "{{reply_title}}"
  }
}
```

#### WhatsApp

**Content Types**:
- `interactive` - Interactive message (buttons, lists)
- `template` - WhatsApp template message
- `media` - Media message (image, video, document)

**Example Mapping**:

```json
{
  "channel_type": "whatsapp",
  "content_type": "interactive",
  "field_mappings": {
    "type": "button",
    "body.text": "{{message_text}}",
    "action.buttons": "{{button_list}}",
    "header.text": "{{header_text}}"
  }
}
```

#### Web Widget

**Content Types**:
- `text` - Text message
- `form` - Form widget
- `card` - Card with buttons
- `carousel` - Multiple cards

**Example Mapping**:

```json
{
  "channel_type": "web_widget",
  "content_type": "card",
  "field_mappings": {
    "title": "{{card_title}}",
    "description": "{{card_description}}",
    "imageUrl": "{{image_url}}",
    "actions": "{{button_actions}}"
  }
}
```

## Parameter Validation Rules

### Type Validation

Templates validate parameter types at runtime:

| Type | Validation Rule | Examples |
|------|----------------|----------|
| `string` | Must be a string value | `"Hello"`, `"123"` |
| `integer` | Must be a whole number | `42`, `0`, `-10` |
| `boolean` | Must be `true` or `false` | `true`, `false` |
| `array` | Must be an array/list | `[1, 2, 3]`, `["a", "b"]` |
| `object` | Must be an object/hash | `{"key": "value"}` |
| `datetime` | Must be ISO 8601 datetime | `"2025-10-15T09:00:00Z"` |

### Required vs Optional

**Required Parameters**:
- Must be provided in every template render call
- Cannot be `null`, `undefined`, or empty string
- Missing required parameters result in `400 Bad Request` error

**Optional Parameters**:
- Can be omitted
- Can have default values defined in schema
- Missing optional parameters use default or are skipped

### Default Values

Parameters can specify default values used when not provided:

```json
{
  "appointment_duration": {
    "type": "integer",
    "required": false,
    "default": 60,
    "description": "Duration in minutes"
  }
}
```

If `appointment_duration` is not provided, it defaults to `60`.

## Complete Template Example

### Appointment Booking Template

```json
{
  "name": "appointment_booking",
  "category": "scheduling",
  "description": "Template for booking appointments with time picker",
  "status": "active",
  "version": 1,
  "tags": ["appointment", "scheduling", "time_picker"],
  "use_cases": ["booking", "rescheduling"],
  "supported_channels": [
    "apple_messages_for_business",
    "whatsapp",
    "web_widget"
  ],
  "parameters": {
    "business_name": {
      "type": "string",
      "required": true,
      "description": "Name of the business",
      "example": "Acme Medical"
    },
    "service_type": {
      "type": "string",
      "required": true,
      "description": "Type of service being booked",
      "example": "Consultation"
    },
    "available_slots": {
      "type": "array",
      "required": true,
      "description": "Array of available appointment times (ISO 8601)",
      "example": ["2025-10-15T09:00:00Z", "2025-10-15T11:00:00Z"]
    },
    "appointment_duration": {
      "type": "integer",
      "required": false,
      "default": 60,
      "description": "Duration in minutes",
      "example": 30
    },
    "timezone": {
      "type": "string",
      "required": false,
      "default": "UTC",
      "description": "Timezone for appointment times",
      "example": "America/New_York"
    }
  },
  "content_blocks": [
    {
      "block_type": "text",
      "order_index": 0,
      "properties": {
        "content": "Hi! {{business_name}} has these available slots for {{service_type}}:"
      }
    },
    {
      "block_type": "time_picker",
      "order_index": 1,
      "properties": {
        "event": {
          "title": "Schedule {{service_type}}",
          "description": "Select your preferred time slot",
          "timeslots": "{{available_slots}}",
          "timezone": "{{timezone}}"
        },
        "receivedMessage": {
          "title": "Please pick a time",
          "style": "icon"
        },
        "replyMessage": {
          "title": "Great! We'll see you then"
        }
      }
    }
  ],
  "channel_mappings": [
    {
      "channel_type": "apple_messages_for_business",
      "content_type": "apple_time_picker",
      "field_mappings": {
        "event.title": "{{event.title}}",
        "event.description": "{{event.description}}",
        "event.timeslots": "{{available_slots}}",
        "event.timezone": "{{timezone}}",
        "receivedMessage.title": "{{receivedMessage.title}}",
        "replyMessage.title": "{{replyMessage.title}}"
      }
    },
    {
      "channel_type": "whatsapp",
      "content_type": "interactive",
      "field_mappings": {
        "type": "button",
        "body.text": "{{business_name}} - {{service_type}}. Select time:",
        "action.buttons": "{{available_slots}}"
      }
    }
  ]
}
```

### Usage Example

**Render Request**:

```bash
curl -X POST \
  https://your-chatwoot-instance.com/api/v1/accounts/1/bot_templates/render \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "template_id": 123,
    "channel_type": "apple_messages_for_business",
    "parameters": {
      "business_name": "Acme Medical Center",
      "service_type": "Doctor Consultation",
      "available_slots": [
        "2025-10-15T09:00:00Z",
        "2025-10-15T11:00:00Z",
        "2025-10-15T14:00:00Z"
      ],
      "appointment_duration": 30,
      "timezone": "America/Los_Angeles"
    }
  }'
```

**Rendered Output**:

```json
{
  "templateId": 123,
  "contentType": "apple_time_picker",
  "content": "Hi! Acme Medical Center has these available slots for Doctor Consultation:",
  "contentAttributes": {
    "event": {
      "title": "Schedule Doctor Consultation",
      "description": "Select your preferred time slot",
      "timeslots": [
        {
          "identifier": "slot_0",
          "startTime": "2025-10-15T09:00:00Z",
          "duration": 1800
        },
        {
          "identifier": "slot_1",
          "startTime": "2025-10-15T11:00:00Z",
          "duration": 1800
        },
        {
          "identifier": "slot_2",
          "startTime": "2025-10-15T14:00:00Z",
          "duration": 1800
        }
      ],
      "timezone": "America/Los_Angeles"
    },
    "receivedMessage": {
      "title": "Please pick a time",
      "style": "icon"
    },
    "replyMessage": {
      "title": "Great! We'll see you then"
    }
  }
}
```

## Validation Error Examples

### Missing Required Parameter

**Request**:
```json
{
  "template_id": 123,
  "channel_type": "apple_messages_for_business",
  "parameters": {
    "business_name": "Acme Medical"
    // Missing required "available_slots"
  }
}
```

**Response** (400):
```json
{
  "error": "Parameter validation failed",
  "details": "Required parameter 'available_slots' is missing"
}
```

### Invalid Parameter Type

**Request**:
```json
{
  "template_id": 123,
  "channel_type": "apple_messages_for_business",
  "parameters": {
    "business_name": "Acme Medical",
    "available_slots": "not-an-array",
    "appointment_duration": "not-an-integer"
  }
}
```

**Response** (400):
```json
{
  "error": "Parameter validation failed",
  "details": "Parameter 'available_slots' must be an array"
}
```

### Unsupported Channel

**Request**:
```json
{
  "template_id": 123,
  "channel_type": "telegram",
  "parameters": {...}
}
```

**Response** (422):
```json
{
  "error": "Channel not supported",
  "supportedChannels": ["apple_messages_for_business", "whatsapp", "web_widget"]
}
```

## Best Practices

### 1. Parameter Naming

Use descriptive, snake_case parameter names:

```json
{
  "business_name": {...},          // Good
  "available_time_slots": {...},   // Good
  "bn": {...},                      // Bad - unclear
  "AvailableSlots": {...}           // Bad - inconsistent casing
}
```

### 2. Required vs Optional

Make parameters optional when reasonable defaults exist:

```json
{
  "timezone": {
    "type": "string",
    "required": false,
    "default": "UTC"  // Sensible default
  },
  "customer_name": {
    "type": "string",
    "required": true  // No reasonable default
  }
}
```

### 3. Content Block Order

Use logical ordering with `order_index`:

```json
[
  {"block_type": "text", "order_index": 0},      // Intro text first
  {"block_type": "media", "order_index": 1},     // Supporting image
  {"block_type": "time_picker", "order_index": 2}, // Main interaction
  {"block_type": "quick_reply", "order_index": 3}  // Follow-up options
]
```

### 4. Channel Compatibility

Only include channels that can meaningfully support the template:

```json
{
  "supported_channels": [
    "apple_messages_for_business",  // Supports time picker
    "web_widget"                     // Can render custom time picker
    // NOT including "sms" - can't display interactive time picker
  ]
}
```

### 5. Example Values

Always provide example values to help bot developers:

```json
{
  "available_slots": {
    "type": "array",
    "required": true,
    "description": "Array of available appointment times (ISO 8601)",
    "example": ["2025-10-15T09:00:00Z", "2025-10-15T11:00:00Z"]  // Clear example
  }
}
```

## Versioning

When updating templates, consider creating new versions:

```json
{
  "name": "appointment_booking",
  "version": 2,  // Incremented version
  "status": "active"
}
```

Previous version:
```json
{
  "name": "appointment_booking",
  "version": 1,
  "status": "deprecated"  // Mark old version as deprecated
}
```

## Additional Resources

- [Bot Templates API Reference](./BOT_TEMPLATES_API.md)
- [Bot Integration Guide](../guides/BOT_INTEGRATION_GUIDE.md)
- [Unified Template System Architecture](../UNIFIED_TEMPLATE_SYSTEM_ARCHITECTURE.md)
