# Bot Integration Guide

## Overview

This guide provides step-by-step instructions for integrating external bot frameworks (Dialogflow, Rasa, custom bots) with the Chatwoot Unified Template System. Learn how to search, render, and send rich messaging templates from your bot.

## Prerequisites

- Active Chatwoot account
- API access token (User or Agent Bot token)
- Basic understanding of REST APIs
- Bot framework installed (Dialogflow, Rasa, or custom)

## Table of Contents

1. [Getting Started](#getting-started)
2. [Dialogflow Integration](#dialogflow-integration)
3. [Rasa Integration](#rasa-integration)
4. [Custom Webhook Bot Integration](#custom-webhook-bot-integration)
5. [Third-Party System Integration](#third-party-system-integration)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

## Getting Started

### 1. Create an Agent Bot

First, create an Agent Bot in Chatwoot to get an API token:

1. Navigate to **Settings > Agent Bots**
2. Click **Add a new Agent Bot**
3. Fill in bot details:
   - **Name**: Your bot name (e.g., "Appointment Bot")
   - **Description**: Bot purpose
   - **Bot Type**: Select "Webhook" or integration type
4. Copy the **API Access Token**
5. Save the bot

### 2. Test API Access

Verify your API token works:

```bash
curl -H "Authorization: Bearer YOUR_BOT_TOKEN" \
     https://your-chatwoot-instance.com/api/v1/accounts/1/bot_templates/search
```

Expected response:
```json
{
  "templates": [...],
  "total": 0,
  "page": 1,
  "perPage": 20,
  "totalPages": 0
}
```

### 3. Create Your First Template

Create a simple template via the Chatwoot UI or API:

```bash
curl -X POST \
  https://your-chatwoot-instance.com/api/v1/accounts/1/templates \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "simple_greeting",
    "category": "support",
    "description": "Simple greeting template",
    "status": "active",
    "supported_channels": ["apple_messages_for_business", "whatsapp", "web_widget"],
    "parameters": {
      "customer_name": {
        "type": "string",
        "required": true,
        "description": "Customer name"
      }
    },
    "content_blocks": [
      {
        "block_type": "text",
        "order_index": 0,
        "properties": {
          "content": "Hello {{customer_name}}! How can I help you today?"
        }
      }
    ]
  }'
```

## Dialogflow Integration

### Architecture Overview

```
User Message → Chatwoot → Dialogflow
                ↓
        Intent Matched
                ↓
        Fulfillment Webhook → Your Server
                ↓
        Search Template → Chatwoot API
                ↓
        Render Template → Chatwoot API
                ↓
        Send Message → Conversation
```

### Setup Steps

#### 1. Configure Dialogflow in Chatwoot

1. Navigate to **Settings > Applications**
2. Select **Dialogflow**
3. Enter your Dialogflow credentials:
   - Project ID
   - JSON key file content
4. Enable Dialogflow for desired inboxes

#### 2. Create Dialogflow Fulfillment Webhook

Create a webhook server to handle Dialogflow fulfillment requests:

**Node.js Example**:

```javascript
const express = require('express');
const axios = require('axios');
const app = express();

app.use(express.json());

const CHATWOOT_API = 'https://your-chatwoot-instance.com/api/v1';
const CHATWOOT_TOKEN = 'YOUR_BOT_TOKEN';
const ACCOUNT_ID = 1;

// Dialogflow fulfillment endpoint
app.post('/dialogflow/fulfillment', async (req, res) => {
  const { queryResult, session } = req.body;
  const intent = queryResult.intent.displayName;
  const parameters = queryResult.parameters;

  console.log('Intent:', intent);
  console.log('Parameters:', parameters);

  try {
    let response;

    switch (intent) {
      case 'book.appointment':
        response = await handleAppointmentBooking(parameters, session);
        break;
      case 'make.payment':
        response = await handlePaymentRequest(parameters, session);
        break;
      default:
        response = {
          fulfillmentText: "I'm not sure how to help with that."
        };
    }

    res.json(response);
  } catch (error) {
    console.error('Fulfillment error:', error);
    res.json({
      fulfillmentText: "Sorry, I encountered an error. Please try again."
    });
  }
});

async function handleAppointmentBooking(parameters, session) {
  const { service_type } = parameters;

  // Search for appointment booking template
  const searchResponse = await axios.get(
    `${CHATWOOT_API}/accounts/${ACCOUNT_ID}/bot_templates/search`,
    {
      headers: { Authorization: `Bearer ${CHATWOOT_TOKEN}` },
      params: {
        category: 'scheduling',
        tags: 'appointment',
        channel: 'apple_messages_for_business'
      }
    }
  );

  const template = searchResponse.data.templates[0];
  if (!template) {
    return { fulfillmentText: "I couldn't find an appointment template." };
  }

  // Get available slots from your booking system
  const availableSlots = await getAvailableSlots(service_type);

  // Extract conversation ID from session
  const conversationId = extractConversationId(session);

  // Send template message
  await axios.post(
    `${CHATWOOT_API}/accounts/${ACCOUNT_ID}/bot_templates/send_message`,
    {
      conversation_id: conversationId,
      template_id: template.id,
      parameters: {
        business_name: 'Acme Medical',
        service_type: service_type,
        available_slots: availableSlots,
        appointment_duration: 30
      }
    },
    {
      headers: {
        Authorization: `Bearer ${CHATWOOT_TOKEN}`,
        'Content-Type': 'application/json'
      }
    }
  );

  return {
    fulfillmentText: "I've sent you our available appointment slots. Please select one that works for you."
  };
}

async function getAvailableSlots(serviceType) {
  // Integration with your booking system
  // For demo, return mock slots
  const now = new Date();
  return [
    new Date(now.getTime() + 24 * 60 * 60 * 1000).toISOString(),
    new Date(now.getTime() + 48 * 60 * 60 * 1000).toISOString(),
    new Date(now.getTime() + 72 * 60 * 60 * 1000).toISOString()
  ];
}

function extractConversationId(session) {
  // Extract conversation ID from Dialogflow session
  // Format: projects/{project}/agent/sessions/{sessionId}
  const parts = session.split('/');
  return parts[parts.length - 1];
}

app.listen(3000, () => {
  console.log('Dialogflow fulfillment server running on port 3000');
});
```

#### 3. Configure Dialogflow Intent with Fulfillment

In Dialogflow Console:

1. Create or edit an intent (e.g., "book.appointment")
2. Add training phrases:
   - "I want to book an appointment"
   - "Schedule a consultation"
   - "Book a meeting"
3. Add parameters:
   - `service_type` (string, optional)
4. Enable **Webhook call for this intent**
5. Set webhook URL to your server: `https://your-server.com/dialogflow/fulfillment`

#### 4. Test the Integration

Test in Dialogflow Console or via Chatwoot conversation:

```
User: I want to book an appointment
Bot: I've sent you our available appointment slots. Please select one that works for you.
[Interactive time picker message appears]
```

### Advanced Dialogflow Integration

#### Using Custom Payloads

Return custom payloads to trigger template rendering on Chatwoot side:

**Dialogflow Response**:

```json
{
  "fulfillmentMessages": [
    {
      "payload": {
        "template_id": 123,
        "parameters": {
          "business_name": "Acme Corp",
          "available_slots": [...]
        }
      }
    }
  ]
}
```

**Chatwoot Dialogflow Processor** (handles custom payloads):

```ruby
# lib/integrations/dialogflow/template_processor_service.rb
class Integrations::Dialogflow::TemplateProcessorService
  def process_response(message, response)
    fulfillment_messages = response['queryResult']['fulfillmentMessages']

    fulfillment_messages.each do |fulfillment_message|
      if fulfillment_message['payload']&.dig('template_id')
        process_template_payload(message, fulfillment_message['payload'])
      else
        process_standard_message(message, fulfillment_message)
      end
    end
  end

  private

  def process_template_payload(message, payload)
    service = Templates::BotRendererService.new(
      template_id: payload['template_id'],
      parameters: payload['parameters'] || {},
      channel_type: message.conversation.inbox.channel_type
    )

    rendered = service.render_for_bot

    message.conversation.messages.create!(
      content: rendered[:content],
      content_type: rendered[:content_type],
      content_attributes: rendered[:content_attributes],
      message_type: :outgoing,
      account_id: message.conversation.account_id,
      inbox_id: message.conversation.inbox_id,
      sender: find_dialogflow_bot
    )
  end
end
```

## Rasa Integration

### Architecture Overview

```
User Message → Chatwoot → Rasa
                ↓
        Intent Classified
                ↓
        Custom Action → Rasa Action Server
                ↓
        Search/Render Template → Chatwoot API
                ↓
        Send Message → Chatwoot Conversation
```

### Setup Steps

#### 1. Install Rasa

```bash
pip install rasa
rasa init --no-prompt
```

#### 2. Configure Rasa Credentials

Edit `credentials.yml`:

```yaml
rest:
  # Configuration for Rasa REST channel (webhook from Chatwoot)

chatwoot:
  # Custom channel connector for Chatwoot
  verify: true
  webhook_url: "https://your-chatwoot-instance.com/webhooks/chatwoot"
```

#### 3. Create Chatwoot Template Action

Create `actions/chatwoot_templates.py`:

```python
import os
import requests
from typing import Any, Text, Dict, List
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
from rasa_sdk.events import SlotSet

CHATWOOT_API = os.getenv('CHATWOOT_API_URL', 'https://your-instance.com/api/v1')
CHATWOOT_TOKEN = os.getenv('CHATWOOT_BOT_TOKEN')
ACCOUNT_ID = os.getenv('CHATWOOT_ACCOUNT_ID', '1')


class ActionSendAppointmentTemplate(Action):
    """Send appointment booking template via Chatwoot"""

    def name(self) -> Text:
        return "action_send_appointment_template"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any]
    ) -> List[Dict[Text, Any]]:
        # Extract slots
        business_name = tracker.get_slot("business_name") or "Our Business"
        service_type = tracker.get_slot("service_type") or "consultation"
        conversation_id = tracker.sender_id

        # Search for template
        templates = self.search_templates(
            category="scheduling",
            channel="apple_messages_for_business",
            tags=["appointment"]
        )

        if not templates:
            dispatcher.utter_message(
                text="Sorry, I couldn't find an appointment template."
            )
            return []

        template = templates[0]

        # Get available slots from external system
        available_slots = self.get_available_slots(service_type)

        # Send template message
        success = self.send_template_message(
            conversation_id=conversation_id,
            template_id=template['id'],
            parameters={
                'business_name': business_name,
                'service_type': service_type,
                'available_slots': available_slots,
                'appointment_duration': 30
            }
        )

        if success:
            dispatcher.utter_message(
                text="I've sent you our available appointment slots!"
            )
        else:
            dispatcher.utter_message(
                text="Sorry, there was an issue sending the appointment options."
            )

        return []

    def search_templates(
        self,
        category: str = None,
        channel: str = None,
        tags: List[str] = None
    ) -> List[Dict]:
        """Search Chatwoot templates"""
        params = {}
        if category:
            params['category'] = category
        if channel:
            params['channel'] = channel
        if tags:
            params['tags'] = ','.join(tags) if isinstance(tags, list) else tags

        try:
            response = requests.get(
                f'{CHATWOOT_API}/accounts/{ACCOUNT_ID}/bot_templates/search',
                headers={'Authorization': f'Bearer {CHATWOOT_TOKEN}'},
                params=params,
                timeout=10
            )
            response.raise_for_status()
            return response.json().get('templates', [])
        except requests.RequestException as e:
            print(f"Error searching templates: {e}")
            return []

    def send_template_message(
        self,
        conversation_id: int,
        template_id: int,
        parameters: Dict
    ) -> bool:
        """Send template message to Chatwoot conversation"""
        try:
            response = requests.post(
                f'{CHATWOOT_API}/accounts/{ACCOUNT_ID}/bot_templates/send_message',
                headers={
                    'Authorization': f'Bearer {CHATWOOT_TOKEN}',
                    'Content-Type': 'application/json'
                },
                json={
                    'conversation_id': conversation_id,
                    'template_id': template_id,
                    'parameters': parameters
                },
                timeout=10
            )
            response.raise_for_status()
            return True
        except requests.RequestException as e:
            print(f"Error sending template: {e}")
            return False

    def get_available_slots(self, service_type: str) -> List[str]:
        """Get available slots from booking system"""
        # Integration with your booking system
        # For demo, return mock slots
        from datetime import datetime, timedelta
        now = datetime.now()
        return [
            (now + timedelta(days=1)).isoformat(),
            (now + timedelta(days=2)).isoformat(),
            (now + timedelta(days=3)).isoformat()
        ]


class ActionSendPaymentRequest(Action):
    """Send payment request template via Chatwoot"""

    def name(self) -> Text:
        return "action_send_payment_request"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any]
    ) -> List[Dict[Text, Any]]:
        # Extract payment details from slots
        amount = tracker.get_slot("payment_amount")
        currency = tracker.get_slot("payment_currency") or "USD"
        description = tracker.get_slot("payment_description") or "Payment"
        conversation_id = tracker.sender_id

        # Search for payment template
        templates = self.search_templates(
            category="payment",
            tags=["apple_pay"]
        )

        if not templates:
            dispatcher.utter_message(
                text="Sorry, payment requests are not available right now."
            )
            return []

        template = templates[0]

        # Send payment request
        success = self.send_template_message(
            conversation_id=conversation_id,
            template_id=template['id'],
            parameters={
                'merchant_name': 'Acme Corp',
                'amount': str(amount),
                'currency': currency,
                'description': description
            }
        )

        if success:
            dispatcher.utter_message(
                text=f"I've sent you a payment request for {currency} {amount}."
            )
        else:
            dispatcher.utter_message(
                text="Sorry, I couldn't send the payment request."
            )

        return []

    def search_templates(self, category: str = None, tags: List[str] = None):
        # Same as ActionSendAppointmentTemplate.search_templates
        pass

    def send_template_message(self, conversation_id, template_id, parameters):
        # Same as ActionSendAppointmentTemplate.send_template_message
        pass
```

#### 4. Configure Rasa Domain

Edit `domain.yml`:

```yaml
intents:
  - book_appointment
  - request_payment
  - greet
  - goodbye

entities:
  - service_type
  - payment_amount
  - payment_currency

slots:
  business_name:
    type: text
  service_type:
    type: text
  payment_amount:
    type: float
  payment_currency:
    type: text

actions:
  - action_send_appointment_template
  - action_send_payment_request

responses:
  utter_greet:
    - text: "Hello! How can I help you today?"

  utter_goodbye:
    - text: "Goodbye! Have a great day!"
```

#### 5. Configure Rasa Stories

Edit `data/stories.yml`:

```yaml
stories:
  - story: book appointment happy path
    steps:
      - intent: book_appointment
        entities:
          - service_type: "consultation"
      - action: action_send_appointment_template

  - story: payment request
    steps:
      - intent: request_payment
        entities:
          - payment_amount: 99.99
          - payment_currency: "USD"
      - action: action_send_payment_request
```

#### 6. Configure NLU Training Data

Edit `data/nlu.yml`:

```yaml
nlu:
  - intent: book_appointment
    examples: |
      - I want to book an appointment
      - Schedule a [consultation](service_type)
      - Book a [doctor visit](service_type)
      - Can I schedule a meeting
      - I need to see the [dentist](service_type)

  - intent: request_payment
    examples: |
      - I want to pay
      - Send me a payment request
      - How much do I owe
      - I need to make a payment of [99.99](payment_amount) [USD](payment_currency)
```

#### 7. Run Rasa

```bash
# Train the model
rasa train

# Run action server
rasa run actions

# Run Rasa server
rasa run --enable-api --cors "*"
```

#### 8. Connect Chatwoot to Rasa

Configure webhook in Chatwoot:

1. Navigate to **Settings > Applications > Custom**
2. Add webhook URL: `http://your-rasa-server:5005/webhooks/rest/webhook`
3. Enable for desired inboxes

## Custom Webhook Bot Integration

### Python Flask Example

```python
from flask import Flask, request, jsonify
import requests
import os

app = Flask(__name__)

CHATWOOT_API = os.getenv('CHATWOOT_API_URL')
CHATWOOT_TOKEN = os.getenv('CHATWOOT_BOT_TOKEN')
ACCOUNT_ID = os.getenv('CHATWOOT_ACCOUNT_ID')


@app.route('/webhook', methods=['POST'])
def webhook():
    """Handle incoming webhook from Chatwoot"""
    data = request.json
    event = data.get('event')

    if event == 'message_created':
        handle_message(data)

    return jsonify({'status': 'ok'})


def handle_message(data):
    """Process incoming message and respond"""
    message = data['message']
    conversation = data['conversation']

    # Only process incoming messages
    if message['message_type'] != 'incoming':
        return

    content = message['content'].lower()
    conversation_id = conversation['id']

    # Intent detection (simple keyword matching)
    if 'appointment' in content or 'book' in content:
        send_appointment_template(conversation_id)
    elif 'payment' in content or 'pay' in content:
        send_payment_template(conversation_id)
    elif 'hello' in content or 'hi' in content:
        send_text_message(conversation_id, "Hello! How can I help you today?")


def send_appointment_template(conversation_id):
    """Send appointment booking template"""
    # Search for template
    templates = search_templates(
        category='scheduling',
        tags='appointment'
    )

    if not templates:
        send_text_message(conversation_id, "Sorry, appointments are not available.")
        return

    template = templates[0]

    # Get available slots (mock data)
    from datetime import datetime, timedelta
    now = datetime.now()
    available_slots = [
        (now + timedelta(days=i)).isoformat()
        for i in range(1, 4)
    ]

    # Send template
    send_template_message(
        conversation_id=conversation_id,
        template_id=template['id'],
        parameters={
            'business_name': 'Acme Services',
            'service_type': 'Consultation',
            'available_slots': available_slots
        }
    )


def search_templates(category=None, tags=None, channel=None):
    """Search Chatwoot templates"""
    params = {}
    if category:
        params['category'] = category
    if tags:
        params['tags'] = tags
    if channel:
        params['channel'] = channel

    response = requests.get(
        f'{CHATWOOT_API}/accounts/{ACCOUNT_ID}/bot_templates/search',
        headers={'Authorization': f'Bearer {CHATWOOT_TOKEN}'},
        params=params
    )
    return response.json().get('templates', [])


def send_template_message(conversation_id, template_id, parameters):
    """Send template message"""
    response = requests.post(
        f'{CHATWOOT_API}/accounts/{ACCOUNT_ID}/bot_templates/send_message',
        headers={
            'Authorization': f'Bearer {CHATWOOT_TOKEN}',
            'Content-Type': 'application/json'
        },
        json={
            'conversation_id': conversation_id,
            'template_id': template_id,
            'parameters': parameters
        }
    )
    return response.json()


def send_text_message(conversation_id, text):
    """Send simple text message"""
    response = requests.post(
        f'{CHATWOOT_API}/accounts/{ACCOUNT_ID}/conversations/{conversation_id}/messages',
        headers={
            'Authorization': f'Bearer {CHATWOOT_TOKEN}',
            'Content-Type': 'application/json'
        },
        json={
            'content': text,
            'message_type': 'outgoing'
        }
    )
    return response.json()


if __name__ == '__main__':
    app.run(port=5000)
```

### Setup Webhook in Chatwoot

1. Navigate to **Settings > Integrations > Webhooks**
2. Click **Add Webhook**
3. Configure:
   - **URL**: `https://your-server.com/webhook`
   - **Events**: Select `message_created`
4. Save webhook

## Third-Party System Integration

### CRM Integration Example (Salesforce, HubSpot, etc.)

```javascript
// crm-integration.js
const axios = require('axios');

class CRMChatwootIntegration {
  constructor(chatwootConfig, crmConfig) {
    this.chatwoot = {
      apiUrl: chatwootConfig.apiUrl,
      token: chatwootConfig.token,
      accountId: chatwootConfig.accountId
    };
    this.crm = crmConfig;
  }

  // Trigger appointment booking when opportunity reaches certain stage
  async onOpportunityStageChange(opportunityId, stage) {
    if (stage === 'Appointment Needed') {
      const opportunity = await this.getCRMOpportunity(opportunityId);
      const contact = await this.getCRMContact(opportunity.contactId);

      // Find or create Chatwoot conversation
      const conversation = await this.findOrCreateConversation(contact.email);

      // Get available slots from calendar integration
      const availableSlots = await this.getAvailableSlots(opportunity.type);

      // Send appointment template
      await this.sendAppointmentTemplate(
        conversation.id,
        contact.firstName,
        opportunity.type,
        availableSlots
      );
    }
  }

  async sendAppointmentTemplate(conversationId, contactName, serviceType, slots) {
    // Search for template
    const response = await axios.get(
      `${this.chatwoot.apiUrl}/accounts/${this.chatwoot.accountId}/bot_templates/search`,
      {
        headers: { Authorization: `Bearer ${this.chatwoot.token}` },
        params: {
          category: 'scheduling',
          tags: 'appointment'
        }
      }
    );

    const template = response.data.templates[0];
    if (!template) {
      console.error('No appointment template found');
      return;
    }

    // Send template message
    await axios.post(
      `${this.chatwoot.apiUrl}/accounts/${this.chatwoot.accountId}/bot_templates/send_message`,
      {
        conversation_id: conversationId,
        template_id: template.id,
        parameters: {
          business_name: 'Acme Corp',
          service_type: serviceType,
          available_slots: slots,
          customer_name: contactName
        }
      },
      {
        headers: {
          Authorization: `Bearer ${this.chatwoot.token}`,
          'Content-Type': 'application/json'
        }
      }
    );
  }

  async getCRMOpportunity(opportunityId) {
    // CRM API call
    // ...
  }

  async getCRMContact(contactId) {
    // CRM API call
    // ...
  }

  async findOrCreateConversation(email) {
    // Find conversation by contact email or create new one
    // ...
  }

  async getAvailableSlots(serviceType) {
    // Calendar/booking system integration
    // ...
  }
}

// Usage
const integration = new CRMChatwootIntegration(
  {
    apiUrl: 'https://your-chatwoot.com/api/v1',
    token: 'YOUR_TOKEN',
    accountId: 1
  },
  {
    apiUrl: 'https://api.salesforce.com',
    token: 'CRM_TOKEN'
  }
);

// Listen for CRM webhook events
app.post('/crm/webhook', async (req, res) => {
  const event = req.body;
  if (event.type === 'opportunity.stage_changed') {
    await integration.onOpportunityStageChange(
      event.opportunityId,
      event.newStage
    );
  }
  res.json({ status: 'ok' });
});
```

## Best Practices

### 1. Error Handling

Always implement robust error handling:

```python
def send_template_with_retry(conversation_id, template_id, parameters, max_retries=3):
    """Send template with retry logic"""
    for attempt in range(max_retries):
        try:
            response = requests.post(
                f'{CHATWOOT_API}/accounts/{ACCOUNT_ID}/bot_templates/send_message',
                headers={
                    'Authorization': f'Bearer {CHATWOOT_TOKEN}',
                    'Content-Type': 'application/json'
                },
                json={
                    'conversation_id': conversation_id,
                    'template_id': template_id,
                    'parameters': parameters
                },
                timeout=10
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            if attempt == max_retries - 1:
                raise
            time.sleep(2 ** attempt)  # Exponential backoff
```

### 2. Template Caching

Cache frequently used templates:

```python
from functools import lru_cache
from datetime import datetime, timedelta

class TemplateCache:
    def __init__(self, ttl_seconds=3600):
        self.cache = {}
        self.ttl = timedelta(seconds=ttl_seconds)

    def get_template(self, category, tags):
        cache_key = f"{category}:{','.join(sorted(tags))}"

        if cache_key in self.cache:
            template, cached_at = self.cache[cache_key]
            if datetime.now() - cached_at < self.ttl:
                return template

        # Fetch from API
        templates = search_templates(category=category, tags=tags)
        if templates:
            self.cache[cache_key] = (templates[0], datetime.now())
            return templates[0]

        return None

# Usage
cache = TemplateCache()
template = cache.get_template('scheduling', ['appointment'])
```

### 3. Parameter Validation

Validate parameters before sending:

```javascript
function validateParameters(template, parameters) {
  const errors = [];

  for (const [paramName, config] of Object.entries(template.parameters)) {
    if (config.required && !parameters[paramName]) {
      errors.push(`Missing required parameter: ${paramName}`);
    }

    if (parameters[paramName]) {
      const value = parameters[paramName];
      const expectedType = config.type;

      if (expectedType === 'array' && !Array.isArray(value)) {
        errors.push(`Parameter ${paramName} must be an array`);
      } else if (expectedType === 'string' && typeof value !== 'string') {
        errors.push(`Parameter ${paramName} must be a string`);
      }
      // Add more type checks...
    }
  }

  return errors;
}

// Usage
const errors = validateParameters(template, parameters);
if (errors.length > 0) {
  console.error('Parameter validation failed:', errors);
  return;
}
```

### 4. Logging and Monitoring

Log all template operations:

```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def send_template_message_logged(conversation_id, template_id, parameters):
    logger.info(
        f"Sending template {template_id} to conversation {conversation_id}",
        extra={
            'conversation_id': conversation_id,
            'template_id': template_id,
            'parameters': parameters
        }
    )

    try:
        result = send_template_message(conversation_id, template_id, parameters)
        logger.info(f"Template sent successfully: {result}")
        return result
    except Exception as e:
        logger.error(
            f"Failed to send template: {e}",
            exc_info=True,
            extra={
                'conversation_id': conversation_id,
                'template_id': template_id
            }
        )
        raise
```

### 5. Rate Limiting

Implement rate limit handling:

```javascript
class RateLimitedClient {
  constructor(maxRequestsPerMinute = 60) {
    this.maxRequests = maxRequestsPerMinute;
    this.requests = [];
  }

  async request(url, options) {
    await this.waitForRateLimit();

    try {
      const response = await axios(url, options);
      this.recordRequest();
      return response;
    } catch (error) {
      if (error.response?.status === 429) {
        const retryAfter = parseInt(error.response.headers['retry-after'] || '60');
        await this.sleep(retryAfter * 1000);
        return this.request(url, options);
      }
      throw error;
    }
  }

  async waitForRateLimit() {
    const now = Date.now();
    this.requests = this.requests.filter(time => now - time < 60000);

    if (this.requests.length >= this.maxRequests) {
      const oldestRequest = this.requests[0];
      const waitTime = 60000 - (now - oldestRequest);
      await this.sleep(waitTime);
    }
  }

  recordRequest() {
    this.requests.push(Date.now());
  }

  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

## Troubleshooting

### Common Issues

#### 1. "Template not found"

**Symptom**: API returns 404 when trying to render/send template

**Solutions**:
- Verify template exists: Search templates first
- Check template belongs to correct account
- Ensure template status is "active"

#### 2. "Parameter validation failed"

**Symptom**: 400 error with parameter validation message

**Solutions**:
- Check all required parameters are provided
- Verify parameter types match schema
- Review template parameter definitions

#### 3. "Channel not supported"

**Symptom**: 422 error when rendering template

**Solutions**:
- Check template's `supported_channels` array
- Verify conversation's channel type
- Consider creating channel-specific template

#### 4. Rate Limit Errors

**Symptom**: 429 Too Many Requests

**Solutions**:
- Implement exponential backoff
- Reduce request frequency
- Batch operations when possible
- Cache template searches

#### 5. Webhook Not Receiving Events

**Symptom**: Bot doesn't respond to messages

**Solutions**:
- Verify webhook URL is accessible (publicly)
- Check webhook signature validation
- Review Chatwoot webhook settings
- Check server logs for errors

### Debug Checklist

1. **API Token**: Verify token has correct permissions
2. **Account ID**: Confirm using correct account ID
3. **Template ID**: Verify template exists and is active
4. **Parameters**: Check all required parameters provided
5. **Channel Compatibility**: Verify template supports channel
6. **Network**: Check firewall/proxy settings
7. **Logs**: Review bot and Chatwoot logs

### Getting Help

- **Documentation**: https://chatwoot.com/docs
- **Community**: https://github.com/chatwoot/chatwoot/discussions
- **Issues**: https://github.com/chatwoot/chatwoot/issues
- **API Reference**: [BOT_TEMPLATES_API.md](../api/BOT_TEMPLATES_API.md)

## Additional Resources

- [Bot Templates API Reference](../api/BOT_TEMPLATES_API.md)
- [Template Schema Reference](../api/TEMPLATE_SCHEMA_REFERENCE.md)
- [Unified Template System Architecture](../UNIFIED_TEMPLATE_SYSTEM_ARCHITECTURE.md)
- [Dialogflow Documentation](https://cloud.google.com/dialogflow/docs)
- [Rasa Documentation](https://rasa.com/docs/)
