# Bot Templates API Reference

## Overview

The Bot Templates API provides a standardized way for bots (Dialogflow, Rasa, custom webhooks) and third-party systems to search, render, and send rich messaging templates across multiple channels (Apple Messages for Business, WhatsApp, Web Widget, etc.).

**Base URL**: `https://your-chatwoot-instance.com/api/v1`

## Authentication

All Bot Templates API endpoints require authentication via API access tokens.

### Authentication Methods

#### 1. User API Token
Use your personal access token from Chatwoot profile settings.

```bash
curl -H "Authorization: Bearer YOUR_USER_API_TOKEN" \
     https://your-chatwoot-instance.com/api/v1/accounts/1/bot_templates/search
```

#### 2. Agent Bot Token
Use an agent bot's access token (recommended for automated systems).

```bash
curl -H "Authorization: Bearer YOUR_BOT_API_TOKEN" \
     https://your-chatwoot-instance.com/api/v1/accounts/1/bot_templates/search
```

### Creating a Bot Token

1. Navigate to Settings > Agent Bots
2. Create a new Agent Bot or select an existing one
3. Copy the API access token
4. Use this token in the `Authorization` header

## Rate Limiting

- **Rate Limit**: 100 requests per minute per account
- **Burst Limit**: 20 requests per second
- **Headers**:
  - `X-RateLimit-Limit`: Maximum requests per window
  - `X-RateLimit-Remaining`: Remaining requests in current window
  - `X-RateLimit-Reset`: Unix timestamp when the rate limit resets

**Example Response Headers**:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1633024800
```

**Rate Limit Exceeded Response** (429):
```json
{
  "error": "Rate limit exceeded",
  "retryAfter": 30
}
```

## Endpoints

### 1. Search Templates

Search for templates by category, channel compatibility, tags, or use cases.

**Endpoint**: `GET /api/v1/accounts/:account_id/bot_templates/search`

**Query Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `category` | string | No | Filter by category (payment, scheduling, support, etc.) |
| `channel` | string | No | Filter by channel compatibility (apple_messages_for_business, whatsapp, web_widget) |
| `tags` | string/array | No | Filter by tags (comma-separated or array) |
| `use_cases` | string/array | No | Filter by use cases (booking, payment_request, etc.) |
| `page` | integer | No | Page number (default: 1) |
| `per_page` | integer | No | Results per page (default: 20, max: 100) |

**Request Example**:

```bash
curl -X GET \
  "https://your-chatwoot-instance.com/api/v1/accounts/1/bot_templates/search?category=scheduling&channel=apple_messages_for_business&tags=appointment" \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

**Response** (200 OK):

```json
{
  "templates": [
    {
      "id": 123,
      "name": "appointment_booking",
      "category": "scheduling",
      "description": "Template for booking appointments with time picker",
      "channels": ["apple_messages_for_business", "whatsapp", "web_widget"],
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
          "order": 0,
          "has_conditions": false
        },
        {
          "type": "time_picker",
          "order": 1,
          "has_conditions": false
        }
      ],
      "version": 1,
      "status": "active"
    }
  ],
  "total": 1,
  "page": 1,
  "perPage": 20,
  "totalPages": 1
}
```

**Error Responses**:

- **401 Unauthorized**: Invalid or missing API token
- **500 Internal Server Error**: Template search failed

### 2. Render Template

Render a template with specific parameters for a target channel. This validates parameters and returns the channel-specific message format.

**Endpoint**: `POST /api/v1/accounts/:account_id/bot_templates/render`

**Request Body**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `template_id` | integer | Yes | ID of the template to render |
| `parameters` | object | Yes | Parameter values for template variables |
| `channel_type` | string | Yes | Target channel (apple_messages_for_business, whatsapp, web_widget) |
| `conversation_id` | integer | No | Optional conversation ID for logging |

**Request Example**:

```bash
curl -X POST \
  https://your-chatwoot-instance.com/api/v1/accounts/1/bot_templates/render \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "template_id": 123,
    "channel_type": "apple_messages_for_business",
    "parameters": {
      "business_name": "Acme Medical",
      "available_slots": [
        "2025-10-15T09:00:00Z",
        "2025-10-15T11:00:00Z",
        "2025-10-15T14:00:00Z"
      ],
      "appointment_duration": 30
    },
    "conversation_id": 456
  }'
```

**Response** (200 OK):

```json
{
  "templateId": 123,
  "contentType": "apple_time_picker",
  "content": "Please select an appointment time",
  "contentAttributes": {
    "event": {
      "title": "Schedule Appointment",
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
      ]
    },
    "receivedTitle": "Please pick a time",
    "replyTitle": "Great! We'll see you then"
  },
  "suggestedResponses": [],
  "webhookData": {
    "templateId": 123,
    "templateName": "appointment_booking",
    "category": "scheduling",
    "parameters": {
      "business_name": "Acme Medical",
      "available_slots": [
        "2025-10-15T09:00:00Z",
        "2025-10-15T11:00:00Z",
        "2025-10-15T14:00:00Z"
      ],
      "appointment_duration": 30
    },
    "channelType": "apple_messages_for_business",
    "renderedAt": "2025-10-10T15:30:00Z"
  }
}
```

**Error Responses**:

- **400 Bad Request**: Parameter validation failed
  ```json
  {
    "error": "Parameter validation failed",
    "details": "Required parameter 'business_name' is missing"
  }
  ```

- **404 Not Found**: Template not found
  ```json
  {
    "error": "Template not found"
  }
  ```

- **422 Unprocessable Entity**: Channel not supported
  ```json
  {
    "error": "Channel not supported",
    "supportedChannels": ["apple_messages_for_business", "whatsapp"]
  }
  ```

- **500 Internal Server Error**: Template rendering failed
  ```json
  {
    "error": "Template rendering failed",
    "details": "Error message"
  }
  ```

### 3. Send Template Message

Render and send a template message directly to a conversation.

**Endpoint**: `POST /api/v1/accounts/:account_id/bot_templates/send_message`

**Request Body**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `conversation_id` | integer | Yes | Target conversation ID |
| `template_id` | integer | Yes | ID of the template to send |
| `parameters` | object | Yes | Parameter values for template variables |

**Request Example**:

```bash
curl -X POST \
  https://your-chatwoot-instance.com/api/v1/accounts/1/bot_templates/send_message \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "conversation_id": 456,
    "template_id": 123,
    "parameters": {
      "business_name": "Acme Medical",
      "available_slots": [
        "2025-10-15T09:00:00Z",
        "2025-10-15T11:00:00Z"
      ]
    }
  }'
```

**Response** (200 OK):

```json
{
  "message": {
    "id": 789,
    "content": "Please select an appointment time",
    "message_type": "outgoing",
    "content_type": "apple_time_picker",
    "content_attributes": {
      "event": {
        "title": "Schedule Appointment",
        "timeslots": [...]
      }
    },
    "created_at": 1633024800,
    "conversation_id": 456,
    "sender": {
      "id": 10,
      "name": "Template Bot",
      "type": "agent_bot"
    }
  },
  "templateApplied": true,
  "templateId": 123
}
```

**Error Responses**:

- **404 Not Found**: Conversation or template not found
  ```json
  {
    "error": "Conversation not found"
  }
  ```

- **422 Unprocessable Entity**: Failed to send message
  ```json
  {
    "error": "Failed to send template message",
    "details": "Channel does not support this template type"
  }
  ```

## Webhook Integration

### Template Event Webhooks

Configure webhooks at the account level (Settings > Integrations > Webhooks) to receive notifications when templates are used or when users respond to template messages.

#### Event: `template.rendered`

Triggered when a template is successfully rendered and sent.

**Payload**:

```json
{
  "event": "template.rendered",
  "timestamp": "2025-10-10T15:30:00Z",
  "account_id": 1,
  "conversation_id": 456,
  "template": {
    "id": 123,
    "name": "appointment_booking",
    "category": "scheduling"
  },
  "channel_type": "apple_messages_for_business",
  "parameters": {
    "business_name": "Acme Medical",
    "available_slots": ["2025-10-15T09:00:00Z"]
  },
  "rendered_content": {
    "content_type": "apple_time_picker",
    "content": "Please select an appointment time",
    "content_attributes": {...}
  },
  "sender": {
    "type": "AgentBot",
    "id": 10,
    "name": "Booking Bot"
  },
  "user_response_webhook": "https://bot.example.com/template_response"
}
```

#### Event: `template.response_received`

Triggered when a user responds to a template message (e.g., selects a time slot, clicks a button).

**Payload**:

```json
{
  "event": "template.response_received",
  "timestamp": "2025-10-10T15:35:00Z",
  "account_id": 1,
  "conversation_id": 456,
  "template": {
    "id": 123,
    "name": "appointment_booking"
  },
  "original_parameters": {
    "business_name": "Acme Medical",
    "available_slots": ["2025-10-15T09:00:00Z", "2025-10-15T11:00:00Z"]
  },
  "user_response": {
    "selected_slot": "2025-10-15T09:00:00Z",
    "slot_identifier": "slot_0",
    "response_data": {
      "startTime": "2025-10-15T09:00:00Z",
      "duration": 1800
    }
  },
  "next_actions": [
    "confirm_appointment",
    "send_calendar_invite",
    "collect_contact_info"
  ]
}
```

### Webhook Security

- All webhook requests include an `X-Chatwoot-Signature` header for verification
- Verify the signature using HMAC-SHA256 with your webhook secret
- Reject requests with invalid signatures

**Signature Verification (Ruby)**:

```ruby
def verify_webhook_signature(payload, signature, secret)
  expected_signature = OpenSSL::HMAC.hexdigest(
    OpenSSL::Digest.new('sha256'),
    secret,
    payload
  )
  Rack::Utils.secure_compare(expected_signature, signature)
end
```

**Signature Verification (Python)**:

```python
import hmac
import hashlib

def verify_webhook_signature(payload: bytes, signature: str, secret: str) -> bool:
    expected_signature = hmac.new(
        secret.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected_signature, signature)
```

**Signature Verification (JavaScript/Node.js)**:

```javascript
const crypto = require('crypto');

function verifyWebhookSignature(payload, signature, secret) {
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}
```

## Code Examples

### Ruby

```ruby
require 'httparty'
require 'json'

class ChatwootBotTemplates
  BASE_URL = 'https://your-chatwoot-instance.com/api/v1'

  def initialize(api_token, account_id)
    @api_token = api_token
    @account_id = account_id
    @headers = {
      'Authorization' => "Bearer #{@api_token}",
      'Content-Type' => 'application/json'
    }
  end

  def search_templates(category: nil, channel: nil, tags: nil)
    params = { category: category, channel: channel, tags: tags }.compact
    response = HTTParty.get(
      "#{BASE_URL}/accounts/#{@account_id}/bot_templates/search",
      headers: @headers,
      query: params
    )
    JSON.parse(response.body)
  end

  def render_template(template_id, parameters, channel_type)
    response = HTTParty.post(
      "#{BASE_URL}/accounts/#{@account_id}/bot_templates/render",
      headers: @headers,
      body: {
        template_id: template_id,
        parameters: parameters,
        channel_type: channel_type
      }.to_json
    )
    JSON.parse(response.body)
  end

  def send_template_message(conversation_id, template_id, parameters)
    response = HTTParty.post(
      "#{BASE_URL}/accounts/#{@account_id}/bot_templates/send_message",
      headers: @headers,
      body: {
        conversation_id: conversation_id,
        template_id: template_id,
        parameters: parameters
      }.to_json
    )
    JSON.parse(response.body)
  end
end

# Usage
client = ChatwootBotTemplates.new('YOUR_API_TOKEN', 1)

# Search for scheduling templates
templates = client.search_templates(
  category: 'scheduling',
  channel: 'apple_messages_for_business'
)

# Send appointment booking template
client.send_template_message(
  456,
  123,
  {
    business_name: 'Acme Medical',
    available_slots: ['2025-10-15T09:00:00Z', '2025-10-15T11:00:00Z']
  }
)
```

### Python

```python
import requests
from typing import Dict, List, Optional

class ChatwootBotTemplates:
    BASE_URL = 'https://your-chatwoot-instance.com/api/v1'

    def __init__(self, api_token: str, account_id: int):
        self.api_token = api_token
        self.account_id = account_id
        self.headers = {
            'Authorization': f'Bearer {api_token}',
            'Content-Type': 'application/json'
        }

    def search_templates(
        self,
        category: Optional[str] = None,
        channel: Optional[str] = None,
        tags: Optional[List[str]] = None
    ) -> Dict:
        params = {}
        if category:
            params['category'] = category
        if channel:
            params['channel'] = channel
        if tags:
            params['tags'] = ','.join(tags)

        response = requests.get(
            f'{self.BASE_URL}/accounts/{self.account_id}/bot_templates/search',
            headers=self.headers,
            params=params
        )
        response.raise_for_status()
        return response.json()

    def render_template(
        self,
        template_id: int,
        parameters: Dict,
        channel_type: str
    ) -> Dict:
        response = requests.post(
            f'{self.BASE_URL}/accounts/{self.account_id}/bot_templates/render',
            headers=self.headers,
            json={
                'template_id': template_id,
                'parameters': parameters,
                'channel_type': channel_type
            }
        )
        response.raise_for_status()
        return response.json()

    def send_template_message(
        self,
        conversation_id: int,
        template_id: int,
        parameters: Dict
    ) -> Dict:
        response = requests.post(
            f'{self.BASE_URL}/accounts/{self.account_id}/bot_templates/send_message',
            headers=self.headers,
            json={
                'conversation_id': conversation_id,
                'template_id': template_id,
                'parameters': parameters
            }
        )
        response.raise_for_status()
        return response.json()

# Usage
client = ChatwootBotTemplates('YOUR_API_TOKEN', 1)

# Search for scheduling templates
templates = client.search_templates(
    category='scheduling',
    channel='apple_messages_for_business',
    tags=['appointment']
)

# Send appointment booking template
result = client.send_template_message(
    conversation_id=456,
    template_id=123,
    parameters={
        'business_name': 'Acme Medical',
        'available_slots': [
            '2025-10-15T09:00:00Z',
            '2025-10-15T11:00:00Z'
        ]
    }
)
```

### JavaScript/Node.js

```javascript
const axios = require('axios');

class ChatwootBotTemplates {
  constructor(apiToken, accountId) {
    this.baseURL = 'https://your-chatwoot-instance.com/api/v1';
    this.accountId = accountId;
    this.headers = {
      'Authorization': `Bearer ${apiToken}`,
      'Content-Type': 'application/json'
    };
  }

  async searchTemplates({ category, channel, tags } = {}) {
    const params = new URLSearchParams();
    if (category) params.append('category', category);
    if (channel) params.append('channel', channel);
    if (tags) params.append('tags', Array.isArray(tags) ? tags.join(',') : tags);

    const response = await axios.get(
      `${this.baseURL}/accounts/${this.accountId}/bot_templates/search?${params}`,
      { headers: this.headers }
    );
    return response.data;
  }

  async renderTemplate(templateId, parameters, channelType) {
    const response = await axios.post(
      `${this.baseURL}/accounts/${this.accountId}/bot_templates/render`,
      {
        template_id: templateId,
        parameters: parameters,
        channel_type: channelType
      },
      { headers: this.headers }
    );
    return response.data;
  }

  async sendTemplateMessage(conversationId, templateId, parameters) {
    const response = await axios.post(
      `${this.baseURL}/accounts/${this.accountId}/bot_templates/send_message`,
      {
        conversation_id: conversationId,
        template_id: templateId,
        parameters: parameters
      },
      { headers: this.headers }
    );
    return response.data;
  }
}

// Usage
const client = new ChatwootBotTemplates('YOUR_API_TOKEN', 1);

// Search for scheduling templates
const templates = await client.searchTemplates({
  category: 'scheduling',
  channel: 'apple_messages_for_business',
  tags: ['appointment']
});

// Send appointment booking template
const result = await client.sendTemplateMessage(
  456,
  123,
  {
    business_name: 'Acme Medical',
    available_slots: [
      '2025-10-15T09:00:00Z',
      '2025-10-15T11:00:00Z'
    ]
  }
);
```

## Best Practices

### 1. Parameter Validation

Always validate parameters before sending to avoid errors:

```python
def validate_parameters(template, parameters):
    """Validate parameters against template requirements"""
    errors = []

    for param_name, config in template['parameters'].items():
        if config.get('required') and param_name not in parameters:
            errors.append(f"Missing required parameter: {param_name}")

        if param_name in parameters:
            value = parameters[param_name]
            expected_type = config.get('type')

            # Type validation logic
            if expected_type == 'string' and not isinstance(value, str):
                errors.append(f"Parameter {param_name} must be a string")
            elif expected_type == 'array' and not isinstance(value, list):
                errors.append(f"Parameter {param_name} must be an array")

    return errors
```

### 2. Error Handling

Implement robust error handling:

```javascript
try {
  const result = await client.sendTemplateMessage(conversationId, templateId, params);
  console.log('Template sent successfully:', result);
} catch (error) {
  if (error.response) {
    // Server responded with error
    console.error('API Error:', error.response.data);
    if (error.response.status === 400) {
      // Handle parameter validation errors
    } else if (error.response.status === 404) {
      // Handle not found errors
    } else if (error.response.status === 422) {
      // Handle channel compatibility errors
    }
  } else if (error.request) {
    // Request made but no response
    console.error('No response from server');
  } else {
    // Error setting up request
    console.error('Error:', error.message);
  }
}
```

### 3. Rate Limit Handling

Implement exponential backoff for rate limits:

```ruby
def send_with_retry(max_retries: 3)
  retries = 0

  begin
    yield
  rescue RateLimitError => e
    retries += 1
    if retries <= max_retries
      wait_time = [2 ** retries, 60].min
      sleep(wait_time)
      retry
    else
      raise
    end
  end
end
```

### 4. Caching Templates

Cache frequently used templates to reduce API calls:

```python
from functools import lru_cache
from datetime import datetime, timedelta

class CachedTemplateClient(ChatwootBotTemplates):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._cache = {}
        self._cache_duration = timedelta(hours=1)

    def search_templates_cached(self, **kwargs):
        cache_key = str(sorted(kwargs.items()))

        if cache_key in self._cache:
            cached_data, cached_time = self._cache[cache_key]
            if datetime.now() - cached_time < self._cache_duration:
                return cached_data

        data = self.search_templates(**kwargs)
        self._cache[cache_key] = (data, datetime.now())
        return data
```

### 5. Logging and Monitoring

Log all template operations for debugging:

```javascript
class LoggedTemplateClient extends ChatwootBotTemplates {
  async sendTemplateMessage(conversationId, templateId, parameters) {
    console.log('Sending template:', {
      conversationId,
      templateId,
      parameters,
      timestamp: new Date().toISOString()
    });

    try {
      const result = await super.sendTemplateMessage(
        conversationId,
        templateId,
        parameters
      );
      console.log('Template sent successfully:', result);
      return result;
    } catch (error) {
      console.error('Failed to send template:', {
        conversationId,
        templateId,
        error: error.message
      });
      throw error;
    }
  }
}
```

## Troubleshooting

### Common Issues

#### 1. "Template not found"

**Cause**: Invalid template ID or template doesn't belong to your account.

**Solution**: Use the search endpoint to verify the template exists and get the correct ID.

#### 2. "Channel not supported"

**Cause**: The template doesn't support the specified channel.

**Solution**: Check the template's `channels` array in the search response.

#### 3. "Parameter validation failed"

**Cause**: Missing required parameters or incorrect parameter types.

**Solution**: Check the template's `parameters` schema and ensure all required parameters are provided with correct types.

#### 4. "Rate limit exceeded"

**Cause**: Too many requests in a short period.

**Solution**: Implement exponential backoff and respect the rate limit headers.

#### 5. "Authentication required"

**Cause**: Missing or invalid API token.

**Solution**: Verify your API token is correct and included in the Authorization header.

## Support

For additional support:

- Documentation: https://chatwoot.com/docs
- Community Forum: https://github.com/chatwoot/chatwoot/discussions
- GitHub Issues: https://github.com/chatwoot/chatwoot/issues
