# Conversations Controller API Documentation

**Controller Location:** `app/controllers/api/v1/accounts/conversations_controller.rb`

**Base Path:** `/api/v1/accounts/:account_id/conversations`

**Authentication:** Required (API key via `api_access_token` header)

**Authorization:** User must have appropriate access to the account and conversation (enforced via Pundit policies)

---

## Overview

The Conversations Controller manages conversation lifecycle, messaging, assignment, status tracking, and metadata retrieval. Conversations represent chat threads between agents and contacts across various channels (email, WhatsApp, SMS, web widget, etc.).

---

## Endpoints

### 1. GET /api/v1/accounts/:account_id/conversations
**Action:** `index`

**Description:** List all conversations for an account with pagination and filtering.

**HTTP Verb:** `GET`

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| page | integer | No | 1 | Page number for pagination (25 results per page, configurable via `CONVERSATION_RESULTS_PER_PAGE` env var) |
| status | string | No | `open` | Filter by status: `open`, `resolved`, `pending`, `snoozed`, `all` |
| assignee_type | string | No | - | Filter by assignee: `me`, `assigned`, `unassigned`, `all` |
| inbox_id | integer | No | - | Filter by inbox ID |
| team_id | integer | No | - | Filter by team ID |
| labels | string/array | No | - | Filter by label(s) |
| sort_by | string | No | `last_activity_at_desc` | Composite sort key. Options: `last_activity_at_asc`, `last_activity_at_desc`, `created_at_asc`, `created_at_desc`, `priority_asc`, `priority_desc`, `waiting_since_asc`, `waiting_since_desc` |
| q | string | No | - | Search conversations by message content (ignores status filter) |
| conversation_type | string | No | - | Special view filter: `mention`, `participating`, `unattended` |
| source_id | string | No | - | Filter by contact_inbox source_id |
| updated_within | integer | No | - | Filter conversations updated within last N seconds (disables pagination) |

**Response Format:** JSON with `data` wrapper containing `meta` (counts) and `payload` (conversations array)

**Example Response:**
```json
{
  "data": {
    "meta": {
      "mine_count": 3,
      "assigned_count": 18,
      "unassigned_count": 7,
      "all_count": 25
    },
    "payload": [
      {
        "id": 123,
        "account_id": 1,
        "uuid": "b1c2d3e4-f5a6-7890-abcd-ef1234567890",
        "inbox_id": 5,
        "status": "open",
        "priority": "high",
        "muted": false,
        "snoozed_until": null,
        "can_reply": true,
        "unread_count": 2,
        "created_at": 1705312200,
        "updated_at": 1705412400.123,
        "timestamp": 1705412400,
        "first_reply_created_at": 1705312500,
        "last_activity_at": 1705412400,
        "waiting_since": 1705312200,
        "agent_last_seen_at": 1705411500,
        "assignee_last_seen_at": 1705412400,
        "contact_last_seen_at": 1705410000,
        "sla_policy_id": null,
        "labels": ["billing", "vip"],
        "additional_attributes": {},
        "custom_attributes": {
          "issue_type": "billing"
        },
        "meta": {
          "sender": {
            "id": 45,
            "name": "John Customer",
            "email": "john@example.com",
            "phone_number": "+1-555-0100",
            "thumbnail": "https://cdn.example.com/avatar.png",
            "availability_status": "online",
            "additional_attributes": {},
            "custom_attributes": {},
            "identifier": null,
            "blocked": false
          },
          "channel": "Channel::WebWidget",
          "assignee": {
            "id": 2,
            "name": "Jane Doe",
            "email": "jane@example.com",
            "thumbnail": "https://cdn.example.com/agent.png",
            "availability_status": "online",
            "auto_offline": true,
            "confirmed": true,
            "available_name": "Jane",
            "role": "agent",
            "provider": "email",
            "account_id": 1
          },
          "assignee_type": "User",
          "team": {
            "id": 1,
            "name": "Support",
            "description": "Support team",
            "allow_auto_assign": true,
            "account_id": 1,
            "is_member": true
          },
          "hmac_verified": true
        },
        "messages": [
          {
            "id": 500,
            "content": "I need help with billing",
            "content_type": "text",
            "message_type": 0,
            "created_at": 1705412400
          }
        ],
        "last_non_activity_message": {
          "id": 500,
          "content": "I need help with billing",
          "content_type": "text",
          "message_type": 0,
          "created_at": 1705412400
        }
      }
    ]
  }
}
```

**Notes:**
- `id` is the `display_id` (account-scoped auto-incrementing integer). There is no separate `display_id` field in the response.
- Timestamps (`created_at`, `agent_last_seen_at`, `contact_last_seen_at`, `timestamp`, etc.) are Unix timestamps (seconds). `updated_at` is a Unix timestamp with fractional seconds (float).
- `labels` is an array of tag name strings, not integer IDs.
- `priority` is nullable (defaults to `null`, not `"medium"`).
- `meta.sender` uses `thumbnail` (not `avatar_url`) and `availability_status` (not `availability`).
- `meta.assignee` uses `thumbnail` (not `avatar_url`) and `availability_status` (not `availability`).

**Authorization:** Pundit policy `show?` on each conversation; `ConversationFinder` scopes results to the user's assigned inboxes via `Conversations::PermissionFilterService`.

---

### 2. GET /api/v1/accounts/:account_id/conversations/meta
**Action:** `meta`

**Description:** Get metadata/count of conversations without fetching full conversation data.

**HTTP Verb:** `GET`

**Parameters:** Same as index endpoint

**Response Format:** JSON with count metadata only

**Example Response:**
```json
{
  "meta": {
    "mine_count": 3,
    "assigned_count": 18,
    "unassigned_count": 7,
    "all_count": 25
  }
}
```

**Authorization:** Same as index endpoint.

---

### 3. GET /api/v1/accounts/:account_id/conversations/search
**Action:** `search`

**Description:** Search conversations by message content with pagination. Uses a simpler conversation partial than the index endpoint.

**HTTP Verb:** `GET`

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| q | string | Yes | Search query string (searches message content via ILIKE) |
| page | integer | No | Page number for pagination (default: 1) |

**Response Format:** JSON with `meta` and `payload` at the top level (no `data` wrapper). Meta does **not** include `assigned_count`.

**Example Response:**
```json
{
  "meta": {
    "mine_count": 1,
    "unassigned_count": 1,
    "all_count": 3
  },
  "payload": [
    {
      "id": 123,
      "uuid": "b1c2d3e4-f5a6-7890-abcd-ef1234567890",
      "created_at": 1705312200,
      "account_id": 1,
      "contact": {
        "id": 45,
        "name": "John Customer"
      },
      "inbox": {
        "id": 5,
        "name": "Web Widget",
        "channel_type": "Channel::WebWidget"
      },
      "messages": [
        {
          "id": 500,
          "content": "I need help with billing",
          "sender_name": "John Customer",
          "message_type": 0,
          "created_at": 1705412400
        }
      ]
    }
  ]
}
```

**Notes:**
- The search response uses a different, simpler partial (`_conversation` model partial) than the index endpoint. It includes inline `contact` and `inbox` objects with minimal fields, and full message arrays.
- There is no `assigned_count` in the search response meta.

**Authorization:** Same scoping as index endpoint.

---

### 4. POST /api/v1/accounts/:account_id/conversations/filter
**Action:** `filter`

**Description:** Advanced conversation filtering using custom filters with operators.

**HTTP Verb:** `POST`

**Parameters:**

#### Request Body:
```json
{
  "payload": [
    {
      "attribute_key": "status",
      "filter_operator": "equal_to",
      "values": ["open", "pending"],
      "query_operator": "AND"
    },
    {
      "attribute_key": "priority",
      "filter_operator": "equal_to",
      "values": ["high", "urgent"],
      "query_operator": null
    }
  ]
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| payload | array | Yes | Array of filter conditions |
| payload[].attribute_key | string | Yes | Field to filter: `status`, `priority`, `assignee_id`, `created_at`, `labels`, `inbox_id`, etc. |
| payload[].filter_operator | string | Yes | Filter operator: `equal_to`, `not_equal_to`, `contains`, `does_not_contain`, `is_greater_than`, `is_less_than`, `is_present`, `is_not_present`, `days_before` |
| payload[].values | array | Yes | Array of values to filter by (may be empty for `is_present`/`is_not_present`) |
| payload[].query_operator | string | No | Logical connector to the next condition: `AND`, `OR`, or `null` for the last condition |

**Response Format:** JSON with `meta` and `payload` at the top level (no `data` wrapper)

**Example Response:**
```json
{
  "meta": {
    "mine_count": 2,
    "unassigned_count": 1,
    "all_count": 5
  },
  "payload": [
    {
      "id": 123,
      "account_id": 1,
      "uuid": "b1c2d3e4-f5a6-7890-abcd-ef1234567890",
      "inbox_id": 5,
      "status": "open",
      "priority": "high",
      "labels": ["billing"],
      "meta": {
        "sender": { "id": 45, "name": "John Customer", "thumbnail": "..." },
        "channel": "Channel::WebWidget",
        "assignee": { "id": 2, "name": "Jane Doe", "thumbnail": "..." },
        "assignee_type": "User"
      }
    }
  ]
}
```

**Error Response (Invalid Filter):**
```json
{
  "error": "Invalid filter attribute: unknown_field"
}
```

**Notes:**
- Filter field names use `attribute_key` (not `attribute`), `filter_operator` (not `operator`), and `query_operator` for the logical connector.
- The filter response uses the same full conversation partial as the index endpoint but without the `data` wrapper.

**Authorization:** Same scoping as index endpoint.

---

### 5. GET /api/v1/accounts/:account_id/conversations/:id
**Action:** `show`

**Description:** Retrieve a single conversation with full details.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Conversation `display_id` (account-scoped integer, not the database primary key) |

**Parameters:** None

**Response Format:** JSON with full conversation object (same shape as a single item in the index `payload` array)

**Example Response:**
```json
{
  "id": 123,
  "account_id": 1,
  "uuid": "b1c2d3e4-f5a6-7890-abcd-ef1234567890",
  "inbox_id": 5,
  "status": "open",
  "priority": "high",
  "muted": false,
  "snoozed_until": null,
  "can_reply": true,
  "unread_count": 2,
  "created_at": 1705312200,
  "updated_at": 1705412400.123,
  "timestamp": 1705412400,
  "first_reply_created_at": 1705312500,
  "last_activity_at": 1705412400,
  "waiting_since": 1705312200,
  "agent_last_seen_at": 1705411500,
  "assignee_last_seen_at": 1705412400,
  "contact_last_seen_at": 1705410000,
  "sla_policy_id": null,
  "labels": ["billing", "vip"],
  "additional_attributes": {},
  "custom_attributes": {
    "issue_type": "billing"
  },
  "meta": {
    "sender": {
      "id": 45,
      "name": "John Customer",
      "email": "john@example.com",
      "phone_number": "+1-555-0100",
      "thumbnail": "https://cdn.example.com/avatar.png",
      "availability_status": "online"
    },
    "channel": "Channel::WebWidget",
    "assignee": {
      "id": 2,
      "name": "Jane Doe",
      "email": "jane@example.com",
      "thumbnail": "https://cdn.example.com/agent.png",
      "availability_status": "online"
    },
    "assignee_type": "User",
    "hmac_verified": true
  },
  "messages": [
    {
      "id": 500,
      "content": "I need help with billing"
    }
  ],
  "last_non_activity_message": {
    "id": 500,
    "content": "I need help with billing"
  }
}
```

**Authorization:** Pundit `show?` policy is enforced on the conversation.

---

### 6. GET /api/v1/accounts/:account_id/conversations/:id/attachments
**Action:** `attachments`

**Description:** List all attachments in a conversation with pagination.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Conversation `display_id` |

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| page | integer | No | 1 | Page number (100 results per page) |

**Response Format:** JSON with `meta` and `payload`

**Example Response:**
```json
{
  "meta": {
    "total_count": 3
  },
  "payload": [
    {
      "message_id": 10,
      "thumb_url": "https://cdn.example.com/thumb.png",
      "data_url": "https://cdn.example.com/attachment.png",
      "file_size": 204800,
      "file_type": "image",
      "extension": "png",
      "width": 1920,
      "height": 1080,
      "created_at": 1705372800,
      "sender": {
        "id": 2,
        "name": "Jane Doe",
        "type": "user"
      }
    }
  ]
}
```

**Notes:**
- `meta.total_count` is the total number of attachments in the conversation (not just the current page).
- `created_at` is a Unix timestamp (seconds) from the parent message.
- `sender` is the `push_event_data` of the message sender (omitted entirely if the message has no sender, not `null`).
- Fields: `message_id`, `thumb_url`, `data_url`, `file_size`, `file_type`, `extension`, `width`, `height`, `created_at`, `sender`.

**Authorization:** Pundit `show?` policy is enforced on the conversation.

---

### 7. POST /api/v1/accounts/:account_id/conversations
**Action:** `create`

**Description:** Create a new conversation with an optional initial message.

**HTTP Verb:** `POST`

**Parameters:**

#### Request Body:
```json
{
  "inbox_id": 5,
  "contact_id": 45,
  "source_id": "whatsapp:1234567890",
  "status": "open",
  "assignee_id": 2,
  "team_id": 1,
  "snoozed_until": 1705744800,
  "additional_attributes": {
    "referer": "https://example.com"
  },
  "custom_attributes": {
    "issue_type": "billing"
  },
  "message": {
    "content": "Hello, how can we help?",
    "content_type": "text"
  }
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| inbox_id | integer | Yes | Inbox ID for conversation |
| contact_id | integer | Yes | Contact ID (customer) |
| source_id | string | No | Unique identifier for the contact in the channel |
| status | string | No | Initial status: `open`, `resolved`, `pending`, `snoozed` (defaults to inbox-determined logic) |
| assignee_id | integer | No | Agent ID to assign the conversation to |
| team_id | integer | No | Team ID to assign the conversation to |
| snoozed_until | number | No | Unix timestamp in seconds for snooze expiry (parsed via `DateTime.strptime(value, '%s')`) |
| additional_attributes | object | No | Additional attributes object |
| custom_attributes | object | No | Custom attributes key-value pairs |
| message | object | No | Initial message object |
| message.content | string | Yes (if message) | Message content/body |
| message.content_type | string | No | Type: `text`, `input_select`, `cards`, `form_select` |
| message.attachments | array | No | Array of attachment IDs |
| message.template_params | object | No | WhatsApp template parameters (`name`, `category`, `language`, `processed_params`) |

**Response Format:** JSON with full conversation object (same partial as show endpoint)

**Example Response:**
```json
{
  "id": 500,
  "account_id": 1,
  "uuid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "inbox_id": 5,
  "status": "open",
  "priority": null,
  "muted": false,
  "snoozed_until": null,
  "can_reply": true,
  "unread_count": 0,
  "created_at": 1705412400,
  "updated_at": 1705412400.0,
  "labels": [],
  "additional_attributes": {},
  "custom_attributes": {},
  "meta": {
    "sender": {
      "id": 45,
      "name": "John Customer",
      "thumbnail": "https://cdn.example.com/avatar.png"
    },
    "channel": "Channel::WebWidget",
    "hmac_verified": false
  },
  "messages": [
    {
      "id": 1000,
      "content": "Hello, how can we help?",
      "content_type": "text",
      "created_at": 1705412400
    }
  ]
}
```

**Notes:**
- `priority` defaults to `null`, not `"medium"`.
- `id` in the response is the `display_id` (a plain integer like `500`), not a string like `"ID-500"`.
- Creation is wrapped in a database transaction (conversation + optional initial message).

**Authorization:** Pundit `show?` policy is enforced on the inbox.

---

### 8. PATCH /api/v1/accounts/:account_id/conversations/:id
**Action:** `update`

**Description:** Update conversation attributes (currently supports priority).

**HTTP Verb:** `PATCH` or `PUT`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Conversation `display_id` |

**Parameters:**

#### Request Body:
```json
{
  "priority": "high"
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| priority | string | No | Priority level: `urgent`, `high`, `medium`, `low` |

**Response Format:** JSON with full conversation object (same partial as show endpoint)

**Authorization:** Pundit `show?` policy is enforced on the conversation.

**Note (Enterprise):** Enterprise edition also permits `sla_policy_id` as an update parameter.

---

### 9. POST /api/v1/accounts/:account_id/conversations/:id/custom_attributes
**Action:** `custom_attributes`

**Description:** Update custom attributes for a conversation.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Conversation `display_id` |

**Parameters:**

#### Request Body:
```json
{
  "custom_attributes": {
    "issue_type": "billing",
    "priority_level": "critical",
    "custom_field_name": "value"
  }
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| custom_attributes | object | Yes | Key-value pairs of custom attributes |

**Response Format:** JSON with only the custom_attributes object (not the full conversation)

**Example Response:**
```json
{
  "custom_attributes": {
    "issue_type": "billing",
    "priority_level": "critical",
    "custom_field_name": "value"
  }
}
```

**Authorization:** Pundit `show?` policy is enforced on the conversation.

---

### 10. DELETE /api/v1/accounts/:account_id/conversations/:id
**Action:** `destroy`

**Description:** Delete a conversation and all its messages (asynchronous job).

**HTTP Verb:** `DELETE`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Conversation `display_id` |

**Parameters:** None

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Authorization:** Explicit Pundit `destroy?` policy check.

**Note:** Deletion is performed asynchronously via `DeleteObjectJob`.

---

### 11. POST /api/v1/accounts/:account_id/conversations/:id/mute
**Action:** `mute`

**Description:** Mute a conversation to suppress notifications.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Conversation `display_id` |

**Parameters:** None

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Authorization:** Pundit `show?` policy is enforced on the conversation.

---

### 12. POST /api/v1/accounts/:account_id/conversations/:id/unmute
**Action:** `unmute`

**Description:** Unmute a conversation to restore notifications.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Conversation `display_id` |

**Parameters:** None

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Authorization:** Pundit `show?` policy is enforced on the conversation.

---

### 13. POST /api/v1/accounts/:account_id/conversations/:id/toggle_status
**Action:** `toggle_status`

**Description:** Change conversation status. If `status` param is omitted, toggles between `open` and `resolved`. If the current user is a bot transitioning from `pending` to `open`, a bot handoff event is triggered instead.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Conversation `display_id` |

**Parameters:**

#### Request Body:
```json
{
  "status": "snoozed",
  "snoozed_until": 1705744800
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| status | string | No | New status: `open`, `resolved`, `pending`, `snoozed`. Omit to toggle between `open` / `resolved` |
| snoozed_until | number | Conditional | Unix timestamp in seconds (required if status is `snoozed`); parsed via `DateRangeHelper` using `DateTime.strptime(value, '%s')` |

**Response Format:** JSON with `meta` (empty object) and `payload` containing status result

**Example Response:**
```json
{
  "meta": {},
  "payload": {
    "success": true,
    "conversation_id": 123,
    "current_status": "snoozed",
    "snoozed_until": "2024-01-20 10:00:00 UTC"
  }
}
```

**Notes:**
- `conversation_id` is the `display_id`.
- `snoozed_until` in the response is the raw model value (a datetime/timestamp), not ISO 8601. When `null`, it is returned as `null`.
- When toggling to `open` and the current user is an agent, the agent is auto-assigned to the conversation.

**Authorization:** Pundit `show?` policy is enforced on the conversation.

---

### 14. POST /api/v1/accounts/:account_id/conversations/:id/toggle_priority
**Action:** `toggle_priority`

**Description:** Update conversation priority level.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Conversation `display_id` |

**Parameters:**

#### Request Body:
```json
{
  "priority": "high"
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| priority | string | No | Priority: `urgent`, `high`, `medium`, `low`. Pass `null`/empty to clear priority. |

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Authorization:** Pundit `show?` policy is enforced on the conversation.

---

### 15. POST /api/v1/accounts/:account_id/conversations/:id/toggle_typing_status
**Action:** `toggle_typing_status`

**Description:** Broadcast typing status to other participants in the conversation.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Conversation `display_id` |

**Parameters:**

#### Request Body:
```json
{
  "typing_status": "on",
  "is_private": false
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| typing_status | string | No | `on` or `off` |
| is_private | boolean | No | When `true`, the typing event is dispatched as a private (internal) event |

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Authorization:** Pundit `show?` policy is enforced on the conversation.

---

### 16. POST /api/v1/accounts/:account_id/conversations/:id/update_last_seen
**Action:** `update_last_seen`

**Description:** Mark conversation as read by updating the last_seen timestamp (throttled to prevent excessive DB writes).

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Conversation `display_id` |

**Parameters:** None

**Response Format:** JSON with full conversation object (same partial as show endpoint)

**Behavior:**
- Updates immediately if conversation has unread messages
- Otherwise throttles to once per hour to reduce DB load
- Updates `agent_last_seen_at` always; additionally updates `assignee_last_seen_at` if the current user is the assignee

**Authorization:** Pundit `show?` policy is enforced on the conversation.

---

### 17. POST /api/v1/accounts/:account_id/conversations/:id/unread
**Action:** `unread`

**Description:** Mark conversation as unread by setting last_seen to just before the last incoming message.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Conversation `display_id` |

**Parameters:** None

**Response Format:** JSON with full conversation object (same partial as show endpoint)

**Authorization:** Pundit `show?` policy is enforced on the conversation.

---

### 18. POST /api/v1/accounts/:account_id/conversations/:id/transcript
**Action:** `transcript`

**Description:** Send conversation transcript via email.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Conversation `display_id` |

**Parameters:**

#### Request Body:
```json
{
  "email": "recipient@example.com"
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| email | string | Yes | Email address to send transcript to |

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Error Responses:**

```json
{
  "error": "email param missing"
}
```

```
402 Payment Required (Email transcript is not available on your plan)
```

```
429 Too Many Requests
```

**Authorization:** Pundit `show?` policy is enforced on the conversation.

**Note:** Email transcript feature may not be available on all plans. Subject to rate limiting per account.

---

## Enterprise-Only Endpoints

The following endpoints are added by the Enterprise edition via `prepend_mod_with`:

### GET /api/v1/accounts/:account_id/conversations/:id/inbox_assistant
**Action:** `inbox_assistant`

**Description:** Retrieve the Captain assistant associated with the conversation's inbox.

**Response:**
```json
{
  "assistant": {
    "id": 1,
    "name": "Support Bot"
  }
}
```
Returns `{ "assistant": null }` if no assistant is configured.

### GET /api/v1/accounts/:account_id/conversations/:id/reporting_events
**Action:** `reporting_events`

**Description:** List reporting events for a conversation, ordered by creation time ascending.

---

## Status Values

- **open**: Conversation is active
- **resolved**: Conversation is closed/resolved
- **pending**: Conversation is waiting (e.g., bot-handled or awaiting customer response)
- **snoozed**: Conversation is temporarily hidden until `snoozed_until` time

**OpenAPI note:** The existing OpenAPI/Swagger spec (`swagger/definitions/resource/conversation.yml`) lists the `status` enum as `['open', 'resolved', 'pending']` and is missing the `snoozed` value. The actual model enum is `{ open: 0, resolved: 1, pending: 2, snoozed: 3 }`.

---

## Priority Values

- **urgent**: Highest priority
- **high**: High priority
- **medium**: Medium priority
- **low**: Low priority
- **null**: No priority set (this is the default)

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
  "error": "You don't have access to this conversation"
}
```

### 404 Not Found
```json
{
  "error": "Conversation not found"
}
```

### 422 Unprocessable Entity
```json
{
  "error": "Invalid status or parameter"
}
```

---

## Authentication

All endpoints require a valid API key passed via:

```
api_access_token: <token>
```

This is sent as an HTTP header. Do not use `Authorization: Bearer ...` for these endpoints.

---

## Authorization & Permissions

The Conversations Controller uses Pundit for authorization. The primary policy method invoked is `show?` on the `ConversationPolicy`, which checks whether the user has access to the conversation's account and inbox. The `destroy` action explicitly calls `destroy?`. There are no separate named permissions like `view_conversations` or `update_conversations` -- access control is determined by the Pundit policy classes.

Additionally, `ConversationFinder` applies `Conversations::PermissionFilterService` to scope list queries to conversations the user is permitted to see based on their inbox assignments and account role.

---

## Notes & Behaviors

1. **Conversation Display ID**: The `:id` URL parameter maps to `display_id`, which is an account-scoped auto-incrementing integer (e.g., `1`, `2`, `42`). It is **not** the database primary key and is unique only within an account. In JSON responses, the `id` field contains this `display_id` value (`json.id conversation.display_id`).

2. **Assignee Auto-Assignment**: When toggling status to `open`, if the current user is an agent, they are auto-assigned to the conversation.

3. **Throttled Updates**: The `update_last_seen` endpoint throttles updates to once per hour when no unread messages exist to reduce database load.

4. **Transcript Rate Limiting**: Email transcripts are subject to account-level rate limiting.

5. **Transactional Creation**: Creating a conversation and initial message happens in a database transaction.

6. **Source ID**: For external channels (WhatsApp, SMS, etc.), the `source_id` uniquely identifies the contact in that channel.

7. **Custom Attributes**: Custom attributes on conversations allow storing domain-specific metadata. The dedicated `custom_attributes` endpoint returns only `{ "custom_attributes": {...} }`, not the full conversation.

8. **Channel Types**: Conversations can originate from: web_widget, email, WhatsApp, SMS, Telegram, Line, API, Instagram, Twitter, etc.

9. **Labels**: Labels are returned as an array of tag name strings (e.g., `["billing", "vip"]`), not integer IDs.

10. **Timestamps**: Most timestamp fields in responses are Unix timestamps in seconds (integers). `updated_at` is a float (seconds with fractional precision). `snoozed_until` is the raw model value (can be a datetime or `null`).
