# Messages Controller API Documentation

**Controller Location:** `app/controllers/api/v1/accounts/conversations/messages_controller.rb`

**Base Path:** `/api/v1/accounts/:account_id/conversations/:conversation_id/messages`

**Authentication:** Required (API key via `api_access_token` header)

**Authorization:** User must have access to the account. Conversation-level authorization uses `ConversationPolicy#show?` (Pundit). There is no separate `MessagePolicy`; all actions inherit conversation-level access.

---

## Overview

The Messages Controller manages conversation messages including creation, retrieval, updating status, deletion, translation, and retry logic. Messages can contain text, attachments, and various content types. The controller handles both agent and widget messages.

---

## Endpoints

### 1. GET /api/v1/accounts/:account_id/conversations/:conversation_id/messages
**Action:** `index`

**Description:** List messages in a conversation with cursor-based pagination.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| conversation_id | integer | Yes | Conversation `display_id` |

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| before | integer | No | - | Return up to 20 messages with ID < this value (cursor-based, descending by created_at, reversed to ascending in response) |
| after | integer | No | - | Return up to 100 messages with ID > this value (ascending by created_at) |
| before + after | integer | No | - | Used together: return up to 1000 messages with `after_id <= ID < before_id` |
| filter_internal_messages | boolean | No | - | When set, excludes private notes and activity messages |

**Pagination Behaviour:**
- No params: returns **latest 20 messages** (ordered ascending by `created_at`)
- `before` only: returns **20 messages before** the given message ID (results delivered in ascending order; internally fetched descending then reversed)
- `after` only: returns **100 messages after** the given message ID
- `before` + `after`: returns **up to 1000 messages between** those IDs

**Response Format:** JSON with `payload` array and `meta` object

**Example Response:**
```json
{
  "meta": {
    "labels": ["bug", "priority"],
    "additional_attributes": {},
    "contact": {
      "additional_attributes": {},
      "custom_attributes": {},
      "email": "customer@example.com",
      "id": 45,
      "identifier": null,
      "name": "Jane Doe",
      "phone_number": "+1234567890",
      "thumbnail": "https://cdn.example.com/avatars/contact.png",
      "blocked": false,
      "type": "contact"
    },
    "assignee": {
      "id": 2,
      "name": "Agent Smith",
      "available_name": "Agent Smith",
      "avatar_url": "https://cdn.example.com/avatars/agent.png",
      "type": "user",
      "availability_status": "online",
      "thumbnail": "https://cdn.example.com/avatars/agent.png"
    },
    "agent_last_seen_at": "2024-01-15T10:30:00.000Z",
    "assignee_last_seen_at": "2024-01-15T10:30:00.000Z"
  },
```

Note: `assignee` is only present in `meta` when the conversation has an assigned agent. It is omitted entirely (not `null`) when unassigned.

```json
  "payload": [
    {
      "id": 1000,
      "content": "Hello! How can I help you?",
      "inbox_id": 5,
      "conversation_id": 100,
      "message_type": 1,
      "content_type": "text",
      "status": "sent",
      "content_attributes": {},
      "created_at": 1705312200,
      "private": false,
      "source_id": null,
      "sender": {
        "id": 2,
        "name": "Agent Smith",
        "available_name": "Agent Smith",
        "avatar_url": "https://cdn.example.com/avatars/agent.png",
        "type": "user",
        "availability_status": "online",
        "thumbnail": "https://cdn.example.com/avatars/agent.png"
      }
    },
    {
      "id": 1001,
      "content": "I need help with my account",
      "inbox_id": 5,
      "conversation_id": 100,
      "message_type": 0,
      "content_type": "text",
      "status": "sent",
      "content_attributes": {},
      "created_at": 1705312500,
      "private": false,
      "source_id": null,
      "echo_id": "client-uuid-123",
      "sender": {
        "additional_attributes": {},
        "custom_attributes": {},
        "email": "customer@example.com",
        "id": 45,
        "identifier": null,
        "name": "Jane Doe",
        "phone_number": "+1234567890",
        "thumbnail": "https://cdn.example.com/avatars/contact.png",
        "blocked": false,
        "type": "contact"
      },
      "attachments": [
        {
          "id": 500,
          "message_id": 1001,
          "file_type": "image",
          "account_id": 1,
          "extension": "png",
          "data_url": "https://cdn.example.com/file.png",
          "thumb_url": "https://cdn.example.com/file_thumb.png",
          "file_size": 204800,
          "width": 1024,
          "height": 768
        }
      ]
    }
  ]
}
```

**Notes:**
- `echo_id` is included in the response only when present on the message.
- `attachments` is included only when the message has attachments.
- `sender` is a nested object from the sender's `push_event_data`; its shape depends on the sender type (User or Contact).

**Authorization:** User must have access to the conversation (`ConversationPolicy#show?`)

---

### 2. POST /api/v1/accounts/:account_id/conversations/:conversation_id/messages
**Action:** `create`

**Description:** Create a new message in a conversation.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| conversation_id | integer | Yes | Conversation `display_id` |

**Parameters:**

#### Request Body:
```json
{
  "content": "This is my response",
  "content_type": "text",
  "private": false,
  "message_type": "outgoing",
  "attachments": ["<signed_blob_id>"],
  "content_attributes": {
    "in_reply_to": 999,
    "items": []
  },
  "echo_id": "client-generated-uuid",
  "source_id": "external-source-id",
  "external_created_at": "2024-01-15T10:30:00.000Z",
  "cc_emails": "cc@example.com,another@example.com",
  "bcc_emails": "bcc@example.com",
  "to_emails": "to@example.com",
  "email_html_content": "<p>Custom HTML</p>",
  "template_params": {"name": "welcome_template", "category": "marketing", "language": "en"},
  "campaign_id": 42,
  "sender_id": 10,
  "sender_type": "AgentBot"
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| content | string | No | Message content/body. Not required when attachments are present (attachment-only messages are valid) |
| content_type | string | No | One of the content type enum values (see Content Types section). Defaults to `text` |
| private | boolean | No | `true` = private note (internal only, not sent to customer). Default `false` |
| message_type | string | No | `outgoing` (default) or `incoming`. **`incoming` is only allowed for API inboxes** |
| attachments | array | No | Array of Active Storage signed blob IDs or uploaded files (max 15) |
| content_attributes | object | No | Metadata object. Common keys: `in_reply_to` (message ID to quote), `items` (for interactive types) |
| echo_id | string | No | Client-generated ID echoed back via ActionCable and in the response |
| source_id | string | No | External source identifier |
| external_created_at | string | No | ISO 8601 datetime for external message timestamps |
| cc_emails | string | No | Comma-separated CC addresses (Email inbox only) |
| bcc_emails | string | No | Comma-separated BCC addresses (Email inbox only) |
| to_emails | string | No | Comma-separated TO addresses (Email inbox only) |
| email_html_content | string | No | Custom HTML body (Email inbox only; overrides auto-generated HTML) |
| template_params | object | No | Template parameters object (stored in `additional_attributes`). Must include `name`; optional keys: `category`, `language`, `namespace`, `processed_params` |
| campaign_id | integer | No | Links message to a campaign (stored in `additional_attributes`) |
| sender_id | integer | No | AgentBot sender ID (used when `sender_type` is `AgentBot`) |
| sender_type | string | No | `AgentBot` to send as a bot sender |

**Response Format:** Full message object (same structure as individual messages in the index response)

**Example Response:**
```json
{
  "id": 1002,
  "content": "This is my response",
  "inbox_id": 5,
  "conversation_id": 100,
  "message_type": 1,
  "content_type": "text",
  "status": "sent",
  "content_attributes": {},
  "created_at": 1705315200,
  "private": false,
  "source_id": null,
  "sender": {
    "id": 2,
    "name": "Agent Smith",
    "available_name": "Agent Smith",
    "avatar_url": "https://cdn.example.com/avatars/agent.png",
    "type": "user",
    "availability_status": "online",
    "thumbnail": "https://cdn.example.com/avatars/agent.png"
  }
}
```

**Error Response:**
```json
{
  "error": "<exception message>"
}
```

**Authorization:** User must have access to the conversation (`ConversationPolicy#show?`). AgentBot tokens are permitted for this action only (see Bot Access Restriction below).

---

### 3. PATCH /api/v1/accounts/:account_id/conversations/:conversation_id/messages/:id
**Action:** `update`

**Description:** Update message status (used primarily for API inbox status updates).

**HTTP Verb:** `PATCH` or `PUT`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| conversation_id | integer | Yes | Conversation `display_id` |
| id | integer | Yes | Message ID |

**Parameters:**

#### Request Body:
```json
{
  "status": "delivered",
  "external_error": "optional error message"
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| status | string | Yes | New status: `sent`, `delivered`, `read`, `failed` |
| external_error | string | No | Error message (only stored when status is `failed`; cleared otherwise) |

**Status Transition Guard:** The transition from `read` to `delivered` is not allowed. The status must be a valid enum value (`sent`, `delivered`, `read`, `failed`).

**Response Format:** Full message object

**Example Response:**
```json
{
  "id": 1000,
  "content": "Hello! How can I help you?",
  "inbox_id": 5,
  "conversation_id": 100,
  "message_type": 1,
  "content_type": "text",
  "status": "delivered",
  "content_attributes": {},
  "created_at": 1705312200,
  "private": false,
  "source_id": null,
  "sender": {
    "id": 2,
    "name": "Agent Smith",
    "available_name": "Agent Smith",
    "avatar_url": "https://cdn.example.com/avatars/agent.png",
    "type": "user",
    "availability_status": "online",
    "thumbnail": "https://cdn.example.com/avatars/agent.png"
  }
}
```

**Restrictions:**
- Only available for API inbox channels (`before_action :ensure_api_inbox`)
- Returns 403 Forbidden for non-API inboxes

**Error Response:**
```json
{
  "error": "Message status update is only allowed for API inboxes"
}
```

**Authorization:** User must have access to the conversation (`ConversationPolicy#show?`)

---

### 4. DELETE /api/v1/accounts/:account_id/conversations/:conversation_id/messages/:id
**Action:** `destroy`

**Description:** Soft-delete a message by replacing its content and removing attachments.

**HTTP Verb:** `DELETE`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| conversation_id | integer | Yes | Conversation `display_id` |
| id | integer | Yes | Message ID |

**Parameters:** None

**Response Format:** Full message object (reflecting the soft-deleted state)

**Example Response:**
```json
{
  "id": 1000,
  "content": "This message was deleted",
  "inbox_id": 5,
  "conversation_id": 100,
  "message_type": 1,
  "content_type": "text",
  "status": "sent",
  "content_attributes": {
    "deleted": true
  },
  "created_at": 1705312200,
  "private": false,
  "source_id": null,
  "sender": {
    "id": 2,
    "name": "Agent Smith",
    "available_name": "Agent Smith",
    "avatar_url": "https://cdn.example.com/avatars/agent.png",
    "type": "user",
    "availability_status": "online",
    "thumbnail": "https://cdn.example.com/avatars/agent.png"
  }
}
```

**Behavior:**
- Message is soft-deleted (content replaced with i18n deletion placeholder, `content_type` set to `text`)
- `content_attributes` is set to `{ "deleted": true }`
- All attachments are destroyed
- Transaction ensures consistency

**Authorization:** User must have access to the conversation (`ConversationPolicy#show?`)

---

### 5. POST /api/v1/accounts/:account_id/conversations/:conversation_id/messages/:id/retry
**Action:** `retry`

**Description:** Retry sending a failed message.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| conversation_id | integer | Yes | Conversation `display_id` |
| id | integer | Yes | Message ID |

**Parameters:** None

**Response Format:** Full message object

**Example Response:**
```json
{
  "id": 1000,
  "content": "Message content",
  "inbox_id": 5,
  "conversation_id": 100,
  "message_type": 1,
  "content_type": "text",
  "status": "sent",
  "content_attributes": {},
  "created_at": 1705312200,
  "private": false,
  "source_id": null,
  "sender": {
    "id": 2,
    "name": "Agent Smith",
    "available_name": "Agent Smith",
    "avatar_url": "https://cdn.example.com/avatars/agent.png",
    "type": "user",
    "availability_status": "online",
    "thumbnail": "https://cdn.example.com/avatars/agent.png"
  }
}
```

**Behavior:**
- Uses `Messages::StatusUpdateService` to change message status to `sent`
- Clears `content_attributes` (resets to `{}`)
- Enqueues `SendReplyJob` to attempt delivery
- Returns early (no-op) if message is blank

**Error Response:**
```json
{
  "error": "<exception message>"
}
```

**Authorization:** User must have access to the conversation (`ConversationPolicy#show?`)

---

### 6. POST /api/v1/accounts/:account_id/conversations/:conversation_id/messages/:id/translate
**Action:** `translate`

**Description:** Translate a message to a target language using Google Translate API.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| conversation_id | integer | Yes | Conversation `display_id` |
| id | integer | Yes | Message ID |

**Parameters:**

#### Request Body:
```json
{
  "target_language": "es"
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| target_language | string | Yes | Language code (e.g., `en`, `es`, `fr`, `de`, `it`, `pt`, `ja`, `zh`) |

**Response Format:** JSON with translation result

**Example Response:**
```json
{
  "content": "Esto es un mensaje traducido"
}
```

**Behavior:**
- Returns `200 OK` with no body if translation already cached for the target language
- Calls Google Translate API for new translations
- Caches translations on the message's `translations` content attribute
- Supports multiple translations per message (merged into existing translations)

**Cached Translation Response:**
```
200 OK (No body)
```

**Authorization:** User must have access to the conversation (`ConversationPolicy#show?`)

**Note:** Translation feature requires Google Translate integration to be configured.

---

## Message Response Fields

All single-message responses (create, update, destroy, retry) and each element in the index `payload` array share the same structure, rendered via the `_message.json.jbuilder` partial:

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Message ID |
| content | string | Message text content |
| inbox_id | integer | Inbox ID |
| echo_id | string | Client-generated echo ID (only present when set) |
| conversation_id | integer | Conversation `display_id` |
| message_type | integer | `0` = incoming, `1` = outgoing, `2` = activity, `3` = template |
| content_type | string | Content type enum string (see Content Types) |
| status | string | Delivery status enum string (see Message Status Values) |
| content_attributes | object | Flexible metadata object |
| created_at | integer | Unix timestamp (seconds since epoch) |
| private | boolean | Whether this is a private/internal note |
| source_id | string | External source identifier |
| sender | object | Nested sender object from `push_event_data` (see below) |
| attachments | array | Array of attachment objects (only present when attachments exist) |

### Sender Object

The `sender` field is a nested object. Its shape depends on the sender type:

**User (agent) sender:**
| Field | Type | Description |
|-------|------|-------------|
| id | integer | User ID |
| name | string | Display name |
| available_name | string | Available display name |
| avatar_url | string | Avatar URL |
| type | string | Always `"user"` |
| availability_status | string | Agent availability status |
| thumbnail | string | Avatar thumbnail URL |

**Contact sender:**
| Field | Type | Description |
|-------|------|-------------|
| id | integer | Contact ID |
| name | string | Contact name |
| email | string | Contact email |
| phone_number | string | Contact phone number |
| identifier | string | External identifier |
| thumbnail | string | Avatar thumbnail URL |
| additional_attributes | object | Additional attributes |
| custom_attributes | object | Custom attributes |
| blocked | boolean | Whether contact is blocked |
| type | string | Always `"contact"` |

### Attachment Object

Each attachment in the `attachments` array contains base fields plus type-specific metadata:

**Base fields (always present):**
| Field | Type | Description |
|-------|------|-------------|
| id | integer | Attachment ID |
| message_id | integer | Parent message ID |
| file_type | string | File type enum: `image`, `audio`, `video`, `file`, `location`, `fallback`, `share`, `story_mention`, `contact`, `ig_reel`, `ig_post`, `ig_story`, `embed` |
| account_id | integer | Account ID |

**File metadata (for image, video, file types):**
| Field | Type | Description |
|-------|------|-------------|
| extension | string | File extension |
| data_url | string | URL to the file |
| thumb_url | string | Thumbnail URL (images only) |
| file_size | integer | File size in bytes |
| width | integer | Image/video width in pixels |
| height | integer | Image/video height in pixels |

---

## Message Status Values

| Status | Integer Value | Description |
|--------|--------------|-------------|
| sent | 0 | Message sent successfully |
| delivered | 1 | Message delivered to recipient |
| read | 2 | Message read by recipient |
| failed | 3 | Message failed to send |

**Status transition guard:** Transitioning from `read` to `delivered` is not allowed.

---

## Message Types

| Type | Integer Value | Description |
|------|--------------|-------------|
| incoming | 0 | Message from contact/customer |
| outgoing | 1 | Message from agent |
| activity | 2 | System activity message |
| template | 3 | Pre-defined template message |

Note: In API responses, `message_type` is serialized as its integer value (e.g., `0`, `1`, `2`, `3`), not as a string.

---

## Content Types

| Content Type | Integer Value | Description |
|-------------|--------------|-------------|
| text | 0 | Plain text message (default) |
| input_text | 1 | Text input message |
| input_textarea | 2 | Textarea input message |
| input_email | 3 | Email input form |
| input_select | 4 | Selection input message |
| cards | 5 | Card/carousel message |
| form | 6 | Form message |
| article | 7 | Article/help-center content |
| incoming_email | 8 | Incoming email message |
| input_csat | 9 | CSAT survey input |
| integrations | 10 | Integration message |
| sticker | 11 | Sticker message |
| voice_call | 12 | Voice call message |

Note: In API responses, `content_type` is serialized as the string name (e.g., `"text"`, `"input_select"`).

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid parameter"
}
```

### 401 Unauthorized
```json
{
  "error": "Unauthorized"
}
```

### 403 Forbidden
```json
{
  "error": "You don't have permission to perform this action"
}
```

### 404 Not Found
```json
{
  "error": "Message not found"
}
```

### 422 Unprocessable Entity
```json
{
  "error": "Could not create message: <details>"
}
```

---

## Authentication

All endpoints require a valid API access token passed via the `api_access_token` header:

```
api_access_token: <token>
```

Alternatively, session-based Devise Token Auth headers are supported:
```
access-token: <token>
client: <client_id>
expiry: <expiry>
uid: <uid>
```

---

## Authorization & Permissions

The Messages Controller does not have its own Pundit policy. Authorization is handled at the conversation level:

- The `BaseController` calls `authorize @conversation, :show?` using `ConversationPolicy` before every action.
- Any user with `show?` access to the conversation can list, create, update, delete, retry, and translate messages.
- The `update` action has an additional guard (`ensure_api_inbox`) that restricts status updates to API inbox channels only.

### Bot Access Restriction

AgentBot tokens (authenticated via `api_access_token`) are restricted to the `create` action only. All other message actions (`index`, `update`, `destroy`, `retry`, `translate`) will return **401 Unauthorized** for bot tokens.

The bot-accessible endpoints are defined in `AccessTokenAuthHelper::BOT_ACCESSIBLE_ENDPOINTS`.

---

## Rate Limiting

No specific per-endpoint rate limiting. However, the `Message` model enforces a per-conversation flood limit: messages are rejected if the conversation exceeds the configured `conversation_message_per_minute_limit` within a 1-minute window.

---

## Notes & Behaviors

1. **API Inbox Only for Status Updates**: The `update` endpoint for changing message status only works with API inboxes. Other channel types (WhatsApp, Email, etc.) manage status updates through their respective channel integrations.

2. **Soft Deletion**: Deleting a message does not remove it from the database. Instead, it:
   - Replaces content with an i18n deletion placeholder
   - Sets `content_type` to `text`
   - Sets `content_attributes` to `{ "deleted": true }`
   - Destroys all attachments
   - Wraps the operation in a transaction

3. **Translation Caching**: Messages can have multiple translations stored in `content_attributes.translations`. If a translation already exists for the target language, no new API call is made and a `200 OK` with no body is returned.

4. **Retry Logic**: Retrying a message:
   - Changes status to `sent` via `Messages::StatusUpdateService`
   - Clears `content_attributes` (resets to `{}`)
   - Enqueues `SendReplyJob` for actual delivery

5. **Message Builder**: Message creation uses `Messages::MessageBuilder` which handles:
   - Setting sender (agent, contact, or AgentBot based on `message_type` and params)
   - Processing attachments (signed blob IDs or uploaded files)
   - Processing email fields (cc/bcc/to, HTML content) for Email inboxes
   - Liquid template rendering for outgoing/template email messages
   - Storing `template_params` and `campaign_id` in `additional_attributes`

6. **Content Not Required**: The `content` field is not required for message creation. Attachment-only messages (with no text content) are valid.

7. **Incoming Message Restriction**: Messages with `message_type: "incoming"` can only be created on API inbox channels. Attempting to create an incoming message on other channel types raises an error.

8. **Private Messages**: Private messages (internal notes) are not sent to customers and appear only in the agent interface.

9. **Content Attributes**: The `content_attributes` field is flexible and can store:
    - `deleted: true` -- Indicates soft-deleted message
    - `in_reply_to` -- Message ID being replied to
    - `items` -- Interactive content items
    - `external_created_at` -- External creation timestamp
    - `external_error` -- External API error details
    - `email` -- Email-specific attributes (html_content, text_content)
    - `translations` -- Cached translations keyed by language code
