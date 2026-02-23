# Inboxes Controller API Documentation

**Controller Location:** `app/controllers/api/v1/accounts/inboxes_controller.rb`

**Base Path:** `/api/v1/accounts/:account_id/inboxes`

**Authentication:** Required (API key via `api_access_token` header)

**Authorization:** User must have appropriate access to the account (Pundit policy-based)

---

## Overview

The Inboxes Controller manages communication channels (inboxes) across different platforms including Email, WhatsApp, Web Widget, API, Telegram, Line, and SMS. It handles CRUD operations, channel configuration, agent assignment, and health monitoring.

---

## Endpoints

### 1. GET /api/v1/accounts/:account_id/inboxes
**Action:** `index`

**Description:** List all inboxes for an account.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Query Parameters:** None

**Response Format:** JSON with `"payload"` wrapper containing inboxes array

**Example Response:**
```json
{
  "payload": [
    {
      "id": 5,
      "avatar_url": "https://cdn.example.com/inbox-avatar.jpg",
      "channel_id": 1,
      "name": "WhatsApp Inbox",
      "channel_type": "Channel::Whatsapp",
      "greeting_enabled": true,
      "greeting_message": "Welcome to our support",
      "working_hours_enabled": false,
      "enable_email_collect": false,
      "csat_survey_enabled": false,
      "csat_config": {},
      "enable_auto_assignment": true,
      "auto_assignment_config": {},
      "out_of_office_message": null,
      "working_hours": [
        {
          "day_of_week": 0,
          "closed_all_day": false,
          "open_hour": 9,
          "open_minutes": 0,
          "close_hour": 17,
          "close_minutes": 0,
          "open_all_day": false
        },
        {
          "day_of_week": 1,
          "closed_all_day": false,
          "open_hour": 9,
          "open_minutes": 0,
          "close_hour": 17,
          "close_minutes": 0,
          "open_all_day": false
        }
      ],
      "timezone": "UTC",
      "callback_webhook_url": "https://app.chatwoot.com/webhooks/whatsapp/1234567890",
      "allow_messages_after_resolved": false,
      "lock_to_single_conversation": false,
      "sender_name_type": "friendly",
      "business_name": "My Business",
      "help_center": {
        "name": "Help Center",
        "slug": "help-center"
      },
      "phone_number": "1234567890",
      "provider": "whatsapp_cloud",
      "message_templates": [],
      "reauthorization_required": false
    }
  ]
}
```

**Authorization:** Pundit `index?` policy -- always true for authenticated users. Results are scoped via `policy_scope` to inboxes assigned to the current user.

---

### 2. GET /api/v1/accounts/:account_id/inboxes/:id
**Action:** `show`

**Description:** Retrieve a single inbox with full details.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Inbox ID |

**Parameters:** None

**Response Format:** JSON with inbox object (no wrapper, same fields as each element in the index `"payload"` array)

**Authorization:** Pundit `show?` policy -- user must be assigned to the inbox (or be an AgentBot)

---

### 3. POST /api/v1/accounts/:account_id/inboxes
**Action:** `create`

**Description:** Create a new inbox/channel for the account.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Parameters:**

#### Request Body:
```json
{
  "name": "WhatsApp Support",
  "greeting_enabled": true,
  "greeting_message": "Welcome!",
  "enable_auto_assignment": false,
  "enable_email_collect": false,
  "csat_survey_enabled": false,
  "timezone": "UTC",
  "allow_messages_after_resolved": true,
  "lock_to_single_conversation": false,
  "sender_name_type": "friendly",
  "business_name": "My Business",
  "channel": {
    "type": "whatsapp",
    "phone_number": "1234567890"
  }
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | Yes | Inbox name/label |
| greeting_enabled | boolean | No | Enable greeting message |
| greeting_message | string | No | Greeting message text |
| enable_auto_assignment | boolean | No | Auto-assign conversations |
| enable_email_collect | boolean | No | Collect customer emails |
| csat_survey_enabled | boolean | No | Enable CSAT surveys |
| timezone | string | No | Timezone (default: UTC) |
| allow_messages_after_resolved | boolean | No | Allow messages on resolved conversations |
| lock_to_single_conversation | boolean | No | Single conversation mode |
| working_hours_enabled | boolean | No | Enable working hours |
| sender_name_type | string | No | `friendly` or `professional` |
| business_name | string | No | Business name for sender |
| portal_id | integer | No | Associated help center portal ID |
| avatar | file | No | Inbox avatar image |
| channel | object | Yes | Channel configuration |
| channel.type | string | Yes | Channel type: `web_widget`, `api`, `email`, `line`, `telegram`, `whatsapp`, `sms` |
| channel.* | varies | No | Channel-specific configuration (see Channel-Specific Configuration section) |

**Allowed Channel Types:**
```
web_widget, api, email, line, telegram, whatsapp, sms
```

**Response Format:** JSON with created inbox (same structure as show endpoint)

**Example Response:**
```json
{
  "id": 10,
  "avatar_url": null,
  "channel_id": 5,
  "name": "WhatsApp Support",
  "channel_type": "Channel::Whatsapp",
  "greeting_enabled": true,
  "greeting_message": "Welcome!",
  "working_hours_enabled": false,
  "enable_email_collect": true,
  "csat_survey_enabled": false,
  "csat_config": {},
  "enable_auto_assignment": false,
  "auto_assignment_config": {},
  "out_of_office_message": null,
  "working_hours": [
    {
      "day_of_week": 0,
      "closed_all_day": true,
      "open_hour": null,
      "open_minutes": null,
      "close_hour": null,
      "close_minutes": null,
      "open_all_day": false
    }
  ],
  "timezone": "UTC",
  "callback_webhook_url": "https://app.chatwoot.com/webhooks/whatsapp/1234567890",
  "allow_messages_after_resolved": true,
  "lock_to_single_conversation": false,
  "sender_name_type": "friendly",
  "business_name": null,
  "phone_number": "1234567890",
  "provider": "whatsapp_cloud",
  "message_templates": [],
  "reauthorization_required": false
}
```

**Error Response (Inbox Limit Exceeded):**
```json
HTTP 402 Payment Required
{
  "error": "Account limit exceeded. Upgrade to a higher plan"
}
```

**Authorization:** Pundit `create?` policy -- user must be an administrator

---

### 4. PATCH /api/v1/accounts/:account_id/inboxes/:id
**Action:** `update`

**Description:** Update inbox settings and channel configuration.

**HTTP Verb:** `PATCH` or `PUT`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Inbox ID |

**Parameters:**

#### Request Body:
```json
{
  "name": "Updated WhatsApp Support",
  "greeting_message": "Hello! How can we help?",
  "enable_auto_assignment": true,
  "working_hours_enabled": true,
  "sender_name_type": "professional",
  "business_name": "Acme Corp",
  "csat_config": {
    "display_type": "emoji",
    "message": "How satisfied are you?",
    "button_text": "Submit",
    "language": "en",
    "survey_rules": {
      "operator": "contains",
      "values": []
    }
  },
  "channel": {
    "phone_number": "1234567890"
  },
  "working_hours": [
    {
      "day_of_week": 1,
      "closed_all_day": false,
      "open_hour": 8,
      "open_minutes": 0,
      "close_hour": 20,
      "close_minutes": 0,
      "open_all_day": false
    }
  ]
}
```

**Parameter Details:** Same inbox-level parameters as create endpoint, plus:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| csat_config | object | No | CSAT survey configuration |
| csat_config.display_type | string | No | Display: `emoji` (default) or other types |
| csat_config.message | string | No | Survey message |
| csat_config.button_text | string | No | Button label (default: "Please rate us") |
| csat_config.language | string | No | Survey language (default: "en") |
| csat_config.survey_rules | object | No | Survey trigger rules |
| csat_config.survey_rules.operator | string | No | Rule operator (default: "contains") |
| csat_config.survey_rules.values | array | No | Rule values |
| csat_config.template | object | No | Template configuration |
| working_hours | array | No | Array of working hour objects (see Working Hours section) |
| channel | object | No | Channel-specific editable attributes |

**Response Format:** JSON with updated inbox (same structure as show endpoint)

**Authorization:** Pundit `update?` policy -- user must be an administrator

---

### 5. DELETE /api/v1/accounts/:account_id/inboxes/:id
**Action:** `destroy`

**Description:** Delete an inbox and all associated conversations.

**HTTP Verb:** `DELETE`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Inbox ID |

**Parameters:** None

**Response Format:** JSON with status message

**Example Response:**
```json
{
  "message": "Your inbox deletion request will be processed in some time."
}
```

**Behavior:** Deletion is performed asynchronously via `DeleteObjectJob`

**Authorization:** Pundit `destroy?` policy -- user must be an administrator

---

### 6. DELETE /api/v1/accounts/:account_id/inboxes/:id/avatar
**Action:** `avatar`

**Description:** Remove/delete the inbox's avatar image.

**HTTP Verb:** `DELETE`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Inbox ID |

**Parameters:** None

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Authorization:** Pundit `avatar?` policy -- user must be an administrator

---

### 7. GET /api/v1/accounts/:account_id/inboxes/:id/assignable_agents
**Action:** `assignable_agents`

**Description:** Get list of agents that can be assigned to this inbox. Returns inbox members plus all account administrators.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Inbox ID |

**Parameters:** None

**Response Format:** JSON with `"payload"` wrapper containing agents array

**Example Response:**
```json
{
  "payload": [
    {
      "id": 2,
      "account_id": 1,
      "availability_status": "online",
      "auto_offline": true,
      "confirmed": true,
      "email": "jane@example.com",
      "provider": "email",
      "available_name": "Jane Doe",
      "name": "Jane Doe",
      "role": "agent",
      "thumbnail": "https://cdn.example.com/avatar.jpg"
    },
    {
      "id": 3,
      "account_id": 1,
      "availability_status": "offline",
      "auto_offline": true,
      "confirmed": true,
      "email": "bob@example.com",
      "provider": "email",
      "available_name": "Bob Smith",
      "name": "Bob Smith",
      "role": "administrator",
      "thumbnail": null
    }
  ]
}
```

**Note:** This endpoint is deprecated and will be removed in version 2.7.0

**Authorization:** Pundit `assignable_agents?` policy -- always true for authenticated users. The inbox is fetched via `fetch_inbox` which checks `show?` policy (user must be assigned to the inbox).

---

### 8. GET /api/v1/accounts/:account_id/inboxes/:id/campaigns
**Action:** `campaigns`

**Description:** Get campaigns associated with this inbox.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Inbox ID |

**Parameters:** None

**Response Format:** JSON bare array (no wrapper key)

**Example Response:**
```json
[
  {
    "id": 1,
    "title": "Welcome Campaign",
    "description": "Send welcome message",
    "account_id": 1,
    "inbox": {
      "id": 5,
      "channel_id": 1,
      "name": "Web Widget",
      "channel_type": "Channel::WebWidget"
    },
    "sender": {
      "id": 2,
      "name": "Jane Doe",
      "email": "jane@example.com",
      "thumbnail": "https://cdn.example.com/avatar.jpg"
    },
    "message": "Hello! How can we help you today?",
    "template_params": null,
    "campaign_status": "active",
    "enabled": true,
    "campaign_type": "ongoing",
    "trigger_rules": {
      "url": "https://example.com",
      "time_on_page": 10
    },
    "trigger_only_during_business_hours": false,
    "created_at": "2024-01-10T10:00:00.000Z",
    "updated_at": "2024-01-10T10:00:00.000Z"
  }
]
```

**Note:** The campaign `id` field is actually `display_id` (not the internal primary key). For `one_off` campaigns, the response also includes `scheduled_at` (unix timestamp) and `audience` fields. The `inbox` and `sender` objects in the campaign response use the full inbox and agent jbuilder partials respectively, not simplified versions. The example above is abbreviated for readability — the actual response includes all fields from the inbox partial (avatar_url, working_hours, timezone, etc.).

**Authorization:** Pundit `campaigns?` policy -- user must be an administrator

---

### 9. GET /api/v1/accounts/:account_id/inboxes/:id/agent_bot
**Action:** `agent_bot`

**Description:** Get the agent bot assigned to this inbox (if any).

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Inbox ID |

**Parameters:** None

**Response Format:** JSON wrapped in `"agent_bot"` key. If no bot is assigned, returns `{"agent_bot": {}}`.

**Example Response:**
```json
{
  "agent_bot": {
    "id": 1,
    "name": "Support Bot",
    "description": "Automated support",
    "thumbnail": "https://cdn.example.com/bot-avatar.jpg",
    "outgoing_url": "https://bot.example.com/webhook",
    "bot_type": "webhook",
    "bot_config": {},
    "account_id": 1,
    "system_bot": false
  }
}
```

**Note:** The `outgoing_url` field is omitted for system bots. The `access_token` field is included only when present.

**Authorization:** Pundit `agent_bot?` policy -- always true for authenticated users. The inbox is fetched via `fetch_inbox` which checks `show?` policy (user must be assigned to the inbox).

---

### 10. POST /api/v1/accounts/:account_id/inboxes/:id/set_agent_bot
**Action:** `set_agent_bot`

**Description:** Assign or unassign an agent bot to/from the inbox.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Inbox ID |

**Parameters:**

#### Request Body:
```json
{
  "agent_bot": 1
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| agent_bot | integer | No | Agent bot ID (omit to unassign) |

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Behavior:**
- If `agent_bot` is provided and valid: Creates or updates `AgentBotInbox` association
- If `agent_bot` is not provided: Deletes the `AgentBotInbox` association (unassigns bot)

**Authorization:** Pundit `set_agent_bot?` policy -- user must be an administrator

---

### 11. POST /api/v1/accounts/:account_id/inboxes/:id/sync_templates
**Action:** `sync_templates`

**Description:** Sync WhatsApp message templates from Meta Business API.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Inbox ID |

**Parameters:** None

**Response Format:** JSON with status message

**Example Response:**
```json
{
  "message": "Template sync initiated successfully"
}
```

**Restrictions:** Only available for WhatsApp channels (both native WhatsApp and Twilio WhatsApp)

**Error Response (Not WhatsApp):**
```json
HTTP 422 Unprocessable Entity
{
  "error": "Template sync is only available for WhatsApp channels"
}
```

**Behavior:** Enqueues `Channels::Whatsapp::TemplatesSyncJob` or `Channels::Twilio::TemplatesSyncJob` asynchronously depending on channel type

**Error Response (Sync Failure):**
```json
HTTP 500 Internal Server Error
{
  "error": "<exception message>"
}
```

**Authorization:** Pundit `sync_templates?` policy -- user must be an administrator

---

### 12. GET /api/v1/accounts/:account_id/inboxes/:id/health
**Action:** `health`

**Description:** Get health status of WhatsApp Cloud API inbox.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Inbox ID |

**Parameters:** None

**Response Format:** JSON with health status data from `Whatsapp::HealthService`

**Restrictions:** Only available for WhatsApp Cloud API channels (`Channel::Whatsapp` with `provider: "whatsapp_cloud"`)

**Error Response (Not WhatsApp Cloud):**
```json
HTTP 400 Bad Request
{
  "error": "Health data only available for WhatsApp Cloud API channels"
}
```

**Error Response (Service Error):**
```json
HTTP 422 Unprocessable Entity
{
  "error": "<error message>"
}
```

**Authorization:** Requires authentication. Pundit `show?` policy is checked via `fetch_inbox` (user must be assigned to the inbox). Additionally, `health?` policy requires the user to be an administrator.

---

## Inbox Response Fields

All inbox responses (index items, show, create, update) use the same `_inbox.json.jbuilder` partial. Fields are flattened to top level (channel attributes are NOT nested under a `"channel"` key).

### Common Fields (all inbox types)

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Inbox ID |
| avatar_url | string/null | URL of the inbox avatar |
| channel_id | integer | Associated channel record ID |
| name | string | Inbox name |
| channel_type | string | Full channel class name (e.g., `"Channel::Whatsapp"`) |
| greeting_enabled | boolean | Whether greeting message is enabled |
| greeting_message | string/null | Greeting message text |
| working_hours_enabled | boolean | Whether working hours are enabled |
| enable_email_collect | boolean | Whether email collection is enabled |
| csat_survey_enabled | boolean | Whether CSAT surveys are enabled |
| csat_config | object | CSAT survey configuration |
| enable_auto_assignment | boolean | Whether auto-assignment is enabled |
| auto_assignment_config | object | Auto-assignment configuration |
| out_of_office_message | string/null | Out-of-office message |
| working_hours | array | Weekly schedule (array of working hour objects, see below) |
| timezone | string | Inbox timezone |
| callback_webhook_url | string/null | Auto-generated webhook callback URL (channel-dependent) |
| allow_messages_after_resolved | boolean | Whether messages are allowed after resolution |
| lock_to_single_conversation | boolean | Whether single conversation mode is enabled |
| sender_name_type | string | `"friendly"` or `"professional"` |
| business_name | string/null | Business name |
| help_center | object/absent | Present only when a portal is linked; contains `name` and `slug` |

### Channel-Specific Flattened Fields

These fields appear at the top level depending on the channel type:

#### Web Widget (`Channel::WebWidget`)
| Field | Type | Description |
|-------|------|-------------|
| allowed_domains | string/null | Comma-separated allowed domains |
| widget_color | string/null | Widget color hex code |
| website_url | string/null | Website URL |
| hmac_mandatory | boolean/null | Whether HMAC is mandatory |
| welcome_title | string/null | Welcome title text |
| welcome_tagline | string/null | Welcome tagline text |
| web_widget_script | string/null | Embed script snippet |
| website_token | string/null | Website token |
| selected_feature_flags | array/null | Enabled feature flags |
| reply_time | string/null | Reply time setting |
| hmac_token | string/null | HMAC token (administrators only) |
| pre_chat_form_enabled | boolean | Pre-chat form toggle |
| pre_chat_form_options | object/null | Pre-chat form configuration |
| continuity_via_email | boolean | Email continuity toggle |

#### Email (`Channel::Email`)
| Field | Type | Description |
|-------|------|-------------|
| email | string | Channel email address |
| forwarding_enabled | boolean | Whether email forwarding is configured |
| forward_to_email | string | Forwarding email address (only when forwarding is enabled) |
| imap_login | string | IMAP login (administrators only) |
| imap_password | string | IMAP password (administrators only) |
| imap_address | string | IMAP server address (administrators only) |
| imap_port | integer | IMAP port (administrators only) |
| imap_enabled | boolean | IMAP toggle (administrators only) |
| imap_enable_ssl | boolean | IMAP SSL toggle (administrators only) |
| smtp_login | string | SMTP login (administrators only) |
| smtp_password | string | SMTP password (administrators only) |
| smtp_address | string | SMTP server address (administrators only) |
| smtp_port | integer | SMTP port (administrators only) |
| smtp_enabled | boolean | SMTP toggle (administrators only) |
| smtp_domain | string | SMTP domain (administrators only) |
| smtp_enable_ssl_tls | boolean | SMTP SSL/TLS toggle (administrators only) |
| smtp_enable_starttls_auto | boolean | SMTP STARTTLS toggle (administrators only) |
| smtp_openssl_verify_mode | string | OpenSSL verify mode (administrators only) |
| smtp_authentication | string | SMTP auth type (administrators only) |
| reauthorization_required | boolean | Whether re-auth is needed (Microsoft/Google, administrators only) |

#### WhatsApp (`Channel::Whatsapp`)
| Field | Type | Description |
|-------|------|-------------|
| phone_number | string | WhatsApp phone number |
| provider | string | Provider (`"whatsapp_cloud"`, etc.) |
| message_templates | array | Synced message templates |
| provider_config | object | Provider configuration (administrators only) |
| reauthorization_required | boolean | Whether re-auth is needed |

#### Twilio (`Channel::TwilioSms`)
| Field | Type | Description |
|-------|------|-------------|
| messaging_service_sid | string/null | Twilio messaging service SID |
| phone_number | string | Phone number |
| medium | string | Channel medium (`"sms"` or `"whatsapp"`) |
| content_templates | array/null | Content templates |
| auth_token | string | Twilio auth token (administrators only) |
| account_sid | string | Twilio account SID (administrators only) |

#### Telegram (`Channel::Telegram`)
| Field | Type | Description |
|-------|------|-------------|
| bot_name | string | Telegram bot name |

#### API (`Channel::Api`)
| Field | Type | Description |
|-------|------|-------------|
| hmac_token | string | HMAC token (administrators only) |
| webhook_url | string/null | Webhook URL |
| inbox_identifier | string | Channel identifier |
| additional_attributes | object/null | Additional attributes |

#### Facebook (`Channel::FacebookPage`)
| Field | Type | Description |
|-------|------|-------------|
| page_id | string | Facebook page ID |
| reauthorization_required | boolean | Whether re-auth is needed |

#### Instagram (`Channel::Instagram` or `Channel::FacebookPage` with Instagram ID)
| Field | Type | Description |
|-------|------|-------------|
| instagram_id | string | Instagram ID |
| reauthorization_required | boolean | Whether re-auth is needed |

---

## Inbox Types (Channel Types)

| Type | Class | Description |
|------|-------|-------------|
| web_widget | Channel::WebWidget | Web chat widget embedded on websites |
| api | Channel::Api | API-based channel for custom integrations |
| email | Channel::Email | Email channel with SMTP/IMAP |
| line | Channel::Line | LINE messaging platform |
| telegram | Channel::Telegram | Telegram bot channel |
| whatsapp | Channel::Whatsapp | WhatsApp Business API |
| sms | Channel::Sms | SMS channel |

---

## Sender Name Types

The `sender_name_type` field is an enum with two possible values:

- **`friendly`** (default, value 0) -- Friendly display name
- **`professional`** (value 1) -- Professional display name

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Health data only available for WhatsApp Cloud API channels"
}
```

### 401 Unauthorized
```json
{
  "error": "Unauthorized"
}
```

### 402 Payment Required
```json
{
  "error": "Account limit exceeded. Upgrade to a higher plan"
}
```
Returned when creating an inbox and the account has reached its inbox limit.

### 403 Forbidden
```json
{
  "error": "You are not authorized to do this action"
}
```

### 404 Not Found
```json
{
  "error": "Resource could not be found"
}
```

### 422 Unprocessable Entity
```json
{
  "error": "<error message>"
}
```
Returned for validation errors, email channel IMAP/SMTP validation failures, and health endpoint service errors.

---

## Authentication

All endpoints require a valid API key passed via header:

```
api_access_token: <token>
```

---

## Authorization & Permissions

Inboxes Controller uses Pundit for authorization. Policies are defined in `InboxPolicy`:

| Action | Policy Method | Requirement |
|--------|--------------|-------------|
| index | `index?` | Any authenticated user (results scoped to assigned inboxes) |
| show | `show?` | User must be assigned to the inbox (or be an AgentBot) |
| create | `create?` | Administrator |
| update | `update?` | Administrator |
| destroy | `destroy?` | Administrator |
| avatar | `avatar?` | Administrator |
| assignable_agents | `assignable_agents?` | Any authenticated user (inbox fetched via `show?`) |
| campaigns | `campaigns?` | Administrator |
| agent_bot | `agent_bot?` | Any authenticated user (inbox fetched via `show?`) |
| set_agent_bot | `set_agent_bot?` | Administrator |
| sync_templates | `sync_templates?` | Administrator |
| health | `health?` | Administrator (inbox fetched via `show?`) |

**Note:** The `show`, `assignable_agents`, `campaigns`, `agent_bot`, `set_agent_bot`, `sync_templates`, and `health` actions all go through `fetch_inbox` which calls `authorize @inbox, :show?`. The explicit `check_authorization` before_action is skipped for `show` and `health` since they rely on `fetch_inbox` authorization.

---

## Working Hours Configuration

Working hours are configured as an **array of objects**, one per day of the week. Each object uses `day_of_week` as an integer (0 = Sunday through 6 = Saturday).

**Response format** (from `weekly_schedule`):
```json
[
  {
    "day_of_week": 0,
    "closed_all_day": true,
    "open_hour": null,
    "open_minutes": null,
    "close_hour": null,
    "close_minutes": null,
    "open_all_day": false
  },
  {
    "day_of_week": 1,
    "closed_all_day": false,
    "open_hour": 9,
    "open_minutes": 0,
    "close_hour": 17,
    "close_minutes": 0,
    "open_all_day": false
  }
]
```

**Update format** (pass as `working_hours` array in request body):
```json
{
  "working_hours": [
    {
      "day_of_week": 1,
      "closed_all_day": false,
      "open_hour": 8,
      "open_minutes": 0,
      "close_hour": 20,
      "close_minutes": 0,
      "open_all_day": false
    }
  ]
}
```

**Working hour attributes:**

| Field | Type | Description |
|-------|------|-------------|
| day_of_week | integer | Day of week (0 = Sunday, 1 = Monday, ..., 6 = Saturday) |
| closed_all_day | boolean | Whether the inbox is closed all day |
| open_hour | integer | Opening hour (0-23), required unless `closed_all_day` |
| open_minutes | integer | Opening minutes (0-59), required unless `closed_all_day` |
| close_hour | integer | Closing hour (0-23), required unless `closed_all_day` |
| close_minutes | integer | Closing minutes (0-59), required unless `closed_all_day` |
| open_all_day | boolean | Whether the inbox is open all day (auto-sets hours to 0:00-23:59) |

---

## Channel-Specific Configuration

### Email Channel
```json
{
  "channel": {
    "type": "email",
    "email": "support@example.com",
    "smtp_port": 587,
    "smtp_address": "smtp.gmail.com",
    "smtp_domain": "gmail.com",
    "smtp_login": "user@gmail.com",
    "smtp_password": "app_password",
    "smtp_enabled": true,
    "smtp_enable_ssl_tls": false,
    "smtp_enable_starttls_auto": true,
    "smtp_openssl_verify_mode": "peer",
    "smtp_authentication": "login",
    "imap_port": 993,
    "imap_address": "imap.gmail.com",
    "imap_login": "user@gmail.com",
    "imap_password": "app_password",
    "imap_enabled": true,
    "imap_enable_ssl": true
  }
}
```

### WhatsApp Channel
```json
{
  "channel": {
    "type": "whatsapp",
    "phone_number": "+1234567890",
    "provider": "whatsapp_cloud"
  }
}
```

### Web Widget Channel
```json
{
  "channel": {
    "type": "web_widget",
    "website_url": "https://example.com",
    "allowed_domains": "example.com,www.example.com",
    "widget_color": "#1396A5",
    "welcome_title": "Welcome!",
    "welcome_tagline": "We make it easy to connect with us.",
    "reply_time": "in_a_few_minutes"
  }
}
```

---

## Notes & Behaviors

1. **Channel Validation**: When creating an inbox, the channel type must be one of the allowed types defined in the controller.

2. **Auto-Assignment**: When `enable_auto_assignment` is enabled, conversations in this inbox are automatically assigned to available agents.

3. **Working Hours**: When `working_hours_enabled` is true, the system respects these hours for notifications and availability.

4. **CSAT Surveys**: When enabled, customers are prompted to rate conversations using the configured CSAT template.

5. **Email Collect**: When enabled, the system attempts to collect customer email addresses during conversations.

6. **Template Sync**: WhatsApp template sync is asynchronous. Templates are fetched from Meta Business API and stored locally.

7. **Health Checks**: WhatsApp Cloud API health endpoint provides diagnostics of the connection status via `Whatsapp::HealthService`.

8. **Inbox Ordering**: Inboxes are ordered by name (case-insensitive `order_by_name`) in list views.

9. **Avatar Handling**: Inboxes can have custom avatar images. The avatar delete action removes the attachment.

10. **Async Deletes**: Inbox deletion is asynchronous via `DeleteObjectJob` to prevent race conditions.

11. **Multi-Channel**: A single Chatwoot account can have multiple inboxes across different channel types.

12. **Channel Editability**: Different channel types support different editable attributes. Refer to each channel's `EDITABLE_ATTRS` constant.

13. **Telegram Name**: When creating a Telegram inbox, the inbox name is automatically set to the bot name from the channel, ignoring the `name` parameter.

14. **Flattened Channel Attributes**: Channel-specific fields are rendered at the top level of the inbox JSON, not nested under a `"channel"` key. Some fields (like `hmac_token`, IMAP/SMTP credentials, `provider_config`, Twilio credentials) are only included for administrators.
