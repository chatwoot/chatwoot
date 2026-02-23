# Contacts Controller API Documentation

**Controller Location:** `app/controllers/api/v1/accounts/contacts_controller.rb`

**Base Path:** `/api/v1/accounts/:account_id/contacts`

**Authentication:** Required (API key via `api_access_token` header)

**Authorization:** User must have appropriate access to the account (Pundit policies)

---

## Overview

The Contacts Controller manages customer/contact records including CRUD operations, searching, filtering, bulk import/export, online status, and custom attributes. Contacts represent individual customers or users in the system.

---

## Endpoints

### 1. GET /api/v1/accounts/:account_id/contacts
**Action:** `index`

**Description:** List all contacts in an account with pagination and sorting.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| page | integer | No | 1 | Page number for pagination (15 results per page) |
| sort | string | No | - | Sort field with optional `-` prefix for descending. Supported values: `email`, `name`, `phone_number`, `last_activity_at`, `created_at`, `company`, `city`, `country` (e.g. `name`, `-name`) |
| labels | string | No | - | Comma-separated tag **names** (strings) to filter by |
| include_contact_inboxes | string | No | `true` | Include contact_inboxes relation: `true` or `false` |

**Response Format:** JSON with `payload` array and `meta` object

**Example Response:**
```json
{
  "meta": {
    "count": 50,
    "current_page": 1
  },
  "payload": [
    {
      "id": 45,
      "name": "John Customer",
      "email": "john@example.com",
      "phone_number": "+1-555-0100",
      "identifier": "external-id-123",
      "thumbnail": "https://cdn.example.com/avatar.jpg",
      "blocked": false,
      "availability_status": "online",
      "last_activity_at": 1705412400,
      "created_at": 1704880800,
      "custom_attributes": {
        "company": "ACME Inc",
        "plan": "enterprise"
      },
      "additional_attributes": {
        "city": "New York",
        "country": "United States",
        "website": "https://example.com"
      },
      "contact_inboxes": [
        {
          "source_id": "whatsapp:1234567890",
          "inbox": {
            "id": 5,
            "avatar_url": null,
            "channel_id": 10,
            "name": "WhatsApp Inbox",
            "channel_type": "Channel::Whatsapp",
            "provider": null
          }
        }
      ]
    }
  ]
}
```

**Authorization:** Any authenticated account user (Pundit: `index?` returns `true`)

---

### 2. GET /api/v1/accounts/:account_id/contacts/active
**Action:** `active`

**Description:** List currently online/active contacts.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Query Parameters:** Same as index endpoint (page, sort, include_contact_inboxes)

**Response Format:** JSON with `payload` array and `meta` object (same structure as index)

**Example Response:**
```json
{
  "meta": {
    "count": 5,
    "current_page": 1
  },
  "payload": [
    {
      "id": 45,
      "name": "John Customer",
      "email": "john@example.com",
      "phone_number": "+1-555-0100",
      "identifier": "external-id-123",
      "thumbnail": "https://cdn.example.com/avatar.jpg",
      "blocked": false,
      "availability_status": "online",
      "last_activity_at": 1705412700,
      "created_at": 1704880800,
      "custom_attributes": {},
      "additional_attributes": {},
      "contact_inboxes": []
    }
  ]
}
```

**Authorization:** Any authenticated account user (Pundit: `active?` returns `true`)

---

### 3. GET /api/v1/accounts/:account_id/contacts/search
**Action:** `search`

**Description:** Search contacts by name, email, phone number, or identifier. Name, email, and phone searches are case-insensitive (`ILIKE`); identifier search is case-sensitive (`LIKE`).

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| q | string | Yes | Search query string |
| page | integer | No | Page number (default: 1) |
| sort | string | No | Sort field with optional `-` prefix for descending |
| include_contact_inboxes | string | No | Include contact_inboxes: `true` or `false` (default: `true`) |

**Response Format:** JSON with `payload` array and `meta` object including `has_more`

**Example Response:**
```json
{
  "meta": {
    "count": 1,
    "current_page": 1,
    "has_more": false
  },
  "payload": [
    {
      "id": 45,
      "name": "John Customer",
      "email": "john@example.com",
      "phone_number": "+1-555-0100",
      "identifier": "external-id-123",
      "thumbnail": "https://cdn.example.com/avatar.jpg",
      "blocked": false,
      "availability_status": "online",
      "last_activity_at": 1705412400,
      "created_at": 1704880800,
      "custom_attributes": {},
      "additional_attributes": {}
    }
  ]
}
```

**Error Response (Missing query):**
```json
{
  "error": "Specify search string with parameter q"
}
```

**Authorization:** Any authenticated account user (Pundit: `search?` returns `true`)

---

### 4. POST /api/v1/accounts/:account_id/contacts/filter
**Action:** `filter`

**Description:** Advanced contact filtering using custom filter criteria.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| page | integer | No | Page number (default: 1) |
| include_contact_inboxes | string | No | Include contact_inboxes: `true` or `false` (default: `true`) |

**Parameters:**

#### Request Body:
```json
{
  "payload": [
    {
      "attribute_key": "email",
      "filter_operator": "contains",
      "values": ["example.com"],
      "query_operator": "AND"
    },
    {
      "attribute_key": "created_at",
      "filter_operator": "is_greater_than",
      "values": ["2024-01-01"],
      "query_operator": null
    }
  ]
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| payload | array | Yes | Array of filter conditions |
| payload[].attribute_key | string | Yes | Field to filter (see filter attributes table below) |
| payload[].filter_operator | string | Yes | Operator (see filter operators table below) |
| payload[].values | array | Yes | Array of values to filter by |
| payload[].query_operator | string | Conditional | Logical join with next condition: `AND` or `OR`. Required for all conditions except the last one (which should be `null`) |

**Filter Attributes:**

| attribute_key | attribute_type | data_type | Allowed Operators |
|---------------|---------------|-----------|-------------------|
| `name` | standard | text_case_insensitive | `equal_to`, `not_equal_to`, `contains`, `does_not_contain` |
| `phone_number` | standard | text | `equal_to`, `not_equal_to`, `contains`, `does_not_contain`, `starts_with` |
| `email` | standard | text_case_insensitive | `equal_to`, `not_equal_to`, `contains`, `does_not_contain` |
| `identifier` | standard | text_case_insensitive | `equal_to`, `not_equal_to` |
| `country_code` | additional_attributes | text_case_insensitive | `equal_to`, `not_equal_to` |
| `city` | additional_attributes | text_case_insensitive | `equal_to`, `not_equal_to`, `contains`, `does_not_contain` |
| `company` | additional_attributes | text_case_insensitive | `equal_to`, `not_equal_to`, `contains`, `does_not_contain` |
| `labels` | standard | labels | `equal_to`, `not_equal_to`, `is_present`, `is_not_present` |
| `created_at` | standard | date | `is_greater_than`, `is_less_than`, `days_before` |
| `last_activity_at` | standard | date | `is_greater_than`, `is_less_than`, `days_before` |
| `blocked` | standard | boolean | `equal_to`, `not_equal_to` |

Custom attribute definitions are also supported as `attribute_key` values (matched against `CustomAttributeDefinition` records for the account with `attribute_model: "contact_attribute"`).

**Response Format:** JSON with `payload` array and `meta` object

**Example Response:**
```json
{
  "meta": {
    "count": 2,
    "current_page": 1
  },
  "payload": [
    {
      "id": 45,
      "name": "John Customer",
      "email": "john@example.com",
      "phone_number": "+1-555-0100",
      "identifier": "external-id-123",
      "thumbnail": "https://cdn.example.com/avatar.jpg",
      "blocked": false,
      "availability_status": "online",
      "last_activity_at": 1705412400,
      "created_at": 1704880800,
      "custom_attributes": {},
      "additional_attributes": {}
    }
  ]
}
```

**Error Response (Invalid filter):**
```json
{
  "error": "Could not create resource"
}
```

**Authorization:** Any authenticated account user (Pundit: `filter?` returns `true`)

---

### 5. GET /api/v1/accounts/:account_id/contacts/:id
**Action:** `show`

**Description:** Retrieve a single contact with full details.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Contact ID |

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| include_contact_inboxes | string | No | Include contact_inboxes: `true` or `false` (default: `true`) |

**Response Format:** JSON with contact details wrapped in `payload`

**Example Response:**
```json
{
  "payload": {
    "id": 45,
    "name": "John Customer",
    "email": "john@example.com",
    "phone_number": "+1-555-0100",
    "identifier": "external-id-123",
    "thumbnail": "https://cdn.example.com/avatar.jpg",
    "blocked": false,
    "availability_status": "online",
    "last_activity_at": 1705412400,
    "created_at": 1704880800,
    "custom_attributes": {
      "company": "ACME Inc",
      "plan": "enterprise",
      "lifetime_value": 5000
    },
    "additional_attributes": {
      "city": "New York",
      "country": "United States",
      "website": "https://example.com"
    },
    "contact_inboxes": [
      {
        "source_id": "whatsapp:1234567890",
        "inbox": {
          "id": 5,
          "avatar_url": null,
          "channel_id": 10,
          "name": "WhatsApp Inbox",
          "channel_type": "Channel::Whatsapp",
          "provider": null
        }
      }
    ]
  }
}
```

**Authorization:** Any authenticated account user (Pundit: `show?` returns `true`)

---

### 6. POST /api/v1/accounts/:account_id/contacts
**Action:** `create`

**Description:** Create a new contact.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Parameters:**

#### Request Body:
```json
{
  "name": "John Customer",
  "email": "john@example.com",
  "phone_number": "+1-555-0100",
  "identifier": "external-id-123",
  "avatar_url": "https://example.com/avatar.jpg",
  "blocked": false,
  "avatar": "<File Object>",
  "inbox_id": 5,
  "source_id": "whatsapp:1234567890",
  "custom_attributes": {
    "company": "ACME Inc",
    "plan": "enterprise"
  },
  "additional_attributes": {
    "city": "New York",
    "country": "United States"
  }
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | No | Contact's full name |
| email | string | No | Contact's email address |
| phone_number | string | No | Contact's phone number |
| identifier | string | No | External identifier (unique per account) |
| avatar_url | string | No | URL to avatar image (downloaded asynchronously via `Avatar::AvatarFromUrlJob`) |
| avatar | file | No | Direct avatar file upload |
| blocked | boolean | No | Block contact from sending messages |
| inbox_id | integer | No | Associate with inbox (creates a ContactInbox) |
| source_id | string | No | Channel-specific source ID (used with inbox_id) |
| custom_attributes | object | No | Custom key-value pairs |
| additional_attributes | object | No | Additional metadata |

**Response Format:** JSON with nested `payload` containing `contact` and `contact_inbox` objects

**Example Response:**
```json
{
  "payload": {
    "contact": {
      "id": 46,
      "name": "John Customer",
      "email": "john@example.com",
      "phone_number": "+1-555-0100",
      "identifier": "external-id-123",
      "thumbnail": null,
      "blocked": false,
      "availability_status": null,
      "last_activity_at": null,
      "created_at": 1705484400,
      "custom_attributes": {
        "company": "ACME Inc"
      },
      "additional_attributes": {
        "city": "New York"
      },
      "contact_inboxes": [
        {
          "source_id": "whatsapp:1234567890",
          "inbox": {
            "id": 5,
            "avatar_url": null,
            "channel_id": 10,
            "name": "WhatsApp Inbox",
            "channel_type": "Channel::Whatsapp",
            "provider": null
          }
        }
      ]
    },
    "contact_inbox": {
      "inbox": {
        "id": 5,
        "name": "WhatsApp Inbox"
      },
      "source_id": "whatsapp:1234567890"
    }
  }
}
```

**Note:** If `inbox_id` is not provided, `contact_inbox` will have `null` values. The `contact_inbox` at the top level renders the full inbox ActiveRecord object, while the nested `contact_inboxes` array inside `contact` uses the `_contact_inbox` partial with the `_inbox_slim` sub-partial.

**Authorization:** Any authenticated account user (Pundit: `create?` returns `true`)

---

### 7. PATCH /api/v1/accounts/:account_id/contacts/:id
**Action:** `update`

**Description:** Update an existing contact's information.

**HTTP Verb:** `PATCH` or `PUT`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Contact ID |

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| include_contact_inboxes | string | No | Include contact_inboxes in response: `true` or `false` (default: `true`) |

**Parameters:**

#### Request Body:
```json
{
  "name": "Updated Name",
  "email": "newemail@example.com",
  "phone_number": "+1-555-0200",
  "avatar_url": "https://example.com/new-avatar.jpg",
  "blocked": false,
  "custom_attributes": {
    "company": "Updated Company",
    "plan": "premium"
  },
  "additional_attributes": {
    "city": "Los Angeles"
  }
}
```

**Parameter Details:** Same permitted params as create endpoint (name, identifier, email, phone_number, avatar, blocked, avatar_url, additional_attributes, custom_attributes). Custom attributes and additional attributes are **merged** with existing values (not replaced).

**Response Format:** JSON with updated contact wrapped in `payload`

**Example Response:**
```json
{
  "payload": {
    "id": 46,
    "name": "Updated Name",
    "email": "newemail@example.com",
    "phone_number": "+1-555-0200",
    "identifier": "external-id-123",
    "thumbnail": "https://cdn.example.com/avatar.jpg",
    "blocked": false,
    "availability_status": "online",
    "last_activity_at": 1705412400,
    "created_at": 1704880800,
    "custom_attributes": {
      "company": "Updated Company",
      "plan": "premium"
    },
    "additional_attributes": {
      "city": "Los Angeles"
    },
    "contact_inboxes": []
  }
}
```

**Authorization:** Any authenticated account user (Pundit: `update?` returns `true`)

---

### 8. DELETE /api/v1/accounts/:account_id/contacts/:id
**Action:** `destroy`

**Description:** Delete a contact (only if not currently online).

**HTTP Verb:** `DELETE`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Contact ID |

**Parameters:** None

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Error Response (Contact Online):**
```json
{
  "message": "The contact <name> is currently online. Please try again later."
}
```

**Authorization:** Administrator only (Pundit: `destroy?` requires `@account_user.administrator?`)

---

### 9. DELETE /api/v1/accounts/:account_id/contacts/:id/avatar
**Action:** `avatar`

**Description:** Remove/delete a contact's avatar.

**HTTP Verb:** `DELETE`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Contact ID |

**Parameters:** None

**Response Format:** JSON with updated contact wrapped in `payload` (without contact_inboxes)

**Example Response:**
```json
{
  "payload": {
    "id": 46,
    "name": "John Customer",
    "email": "john@example.com",
    "phone_number": "+1-555-0100",
    "identifier": "external-id-123",
    "thumbnail": null,
    "blocked": false,
    "availability_status": "online",
    "last_activity_at": 1705412400,
    "created_at": 1704880800,
    "custom_attributes": {},
    "additional_attributes": {}
  }
}
```

**Authorization:** Any authenticated account user (Pundit: `avatar?` returns `true`)

---

### 10. GET /api/v1/accounts/:account_id/contacts/:id/contactable_inboxes
**Action:** `contactable_inboxes`

**Description:** Get all inboxes where this contact can be contacted.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Contact ID |

**Parameters:** None

**Response Format:** JSON with `payload` array; each item has a nested `inbox` object and `source_id`

**Example Response:**
```json
{
  "payload": [
    {
      "inbox": {
        "id": 5,
        "avatar_url": null,
        "channel_id": 10,
        "name": "WhatsApp Inbox",
        "channel_type": "Channel::Whatsapp",
        "provider": null
      },
      "source_id": "1234567890"
    },
    {
      "inbox": {
        "id": 6,
        "avatar_url": null,
        "channel_id": 11,
        "name": "Email Inbox",
        "channel_type": "Channel::Email",
        "provider": null
      },
      "source_id": "john@example.com"
    }
  ]
}
```

**Authorization:** Any authenticated account user (Pundit: `contactable_inboxes?` returns `true`). Results are further filtered by the user's inbox `show?` policy -- only inboxes the user can access are returned.

---

### 11. POST /api/v1/accounts/:account_id/contacts/:id/destroy_custom_attributes
**Action:** `destroy_custom_attributes`

**Description:** Remove specific custom attributes from a contact.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Contact ID |

**Parameters:**

#### Request Body:
```json
{
  "custom_attributes": ["company", "plan"]
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| custom_attributes | array | Yes | Array of custom attribute keys to remove |

**Response Format:** JSON with updated contact wrapped in `payload` (with contact_inboxes included)

**Example Response:**
```json
{
  "payload": {
    "id": 46,
    "name": "John Customer",
    "email": "john@example.com",
    "phone_number": "+1-555-0100",
    "identifier": "external-id-123",
    "thumbnail": "https://cdn.example.com/avatar.jpg",
    "blocked": false,
    "availability_status": "online",
    "last_activity_at": 1705412400,
    "created_at": 1704880800,
    "custom_attributes": {
      "lifetime_value": 5000
    },
    "additional_attributes": {},
    "contact_inboxes": []
  }
}
```

**Authorization:** Any authenticated account user (Pundit: `destroy_custom_attributes?` returns `true`)

---

### 12. POST /api/v1/accounts/:account_id/contacts/import
**Action:** `import`

**Description:** Bulk import contacts from CSV file.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Parameters:**

#### Request Body (Form Data):
```
Content-Type: multipart/form-data

import_file: <CSV File>
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| import_file | file | Yes | CSV file with contacts data |

**CSV Format:**
```
name,email,phone_number,identifier
John Customer,john@example.com,+1-555-0100,ext-123
Jane Contact,jane@example.com,+1-555-0200,ext-124
```

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Error Response (Missing file):**
```json
{
  "error": "Contact import failed"
}
```

**Background Processing:** Creates a `DataImport` record, which triggers `DataImportJob` (with a 1-minute delay) to process the file asynchronously.

**Authorization:** Administrator only (Pundit: `import?` requires `@account_user.administrator?`)

---

### 13. POST /api/v1/accounts/:account_id/contacts/export
**Action:** `export`

**Description:** Export contacts to CSV file (asynchronous).

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Parameters:**

#### Request Body:
```json
{
  "column_names": ["name", "email", "phone_number", "created_at"],
  "payload": {},
  "label": "export_name"
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| column_names | array | No | Columns to export (defaults to all) |
| payload | object | No | Filter criteria object |
| label | string | No | Export label/name |

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Background Job:** Triggers `Account::ContactsExportJob` to generate CSV asynchronously.

**Export Delivery:** Download link sent to user's email.

**Authorization:** Administrator only (Pundit: `export?` requires `@account_user.administrator?`)

---

### 14. POST /api/v1/accounts/:account_id/actions/contact_merge
**Action:** `contact_merges#create`

**Description:** Merge two contacts into one. The mergee contact's conversations, contact_inboxes, and attributes are transferred to the base contact.

**HTTP Verb:** `POST`

**Controller:** `Api::V1::Accounts::Actions::ContactMergesController`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Parameters:**

#### Request Body:
```json
{
  "base_contact_id": 45,
  "mergee_contact_id": 46
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| base_contact_id | integer | Yes | The contact to merge into (survives) |
| mergee_contact_id | integer | Yes | The contact to merge from (absorbed) |

**Response Format:** JSON with the base contact rendered via the standard `_contact` partial

**Example Response:**
```json
{
  "id": 45,
  "name": "John Customer",
  "email": "john@example.com",
  "phone_number": "+1-555-0100",
  "identifier": "external-id-123",
  "thumbnail": "https://cdn.example.com/avatar.jpg",
  "blocked": false,
  "availability_status": "online",
  "last_activity_at": 1705412400,
  "created_at": 1704880800,
  "custom_attributes": {},
  "additional_attributes": {}
}
```

**Behavior:** Uses `ContactMergeAction` to transfer the mergee contact's conversations, contact_inboxes, and attributes to the base contact.

**Authorization:** Inherits from `Api::V1::Accounts::BaseController` (authenticated user)

---

### 15. GET /api/v1/accounts/:account_id/contacts/:contact_id/conversations
**Action:** `contacts/conversations#index`

**Description:** List all conversations for a specific contact.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| contact_id | integer | Yes | Contact ID |

**Note:** This endpoint is handled by a separate controller (`Api::V1::Accounts::Contacts::ConversationsController`).

---

### 15. POST /api/v1/accounts/:account_id/contacts/:contact_id/contact_inboxes
**Action:** `contacts/contact_inboxes#create`

**Description:** Create a new contact inbox association for a contact.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| contact_id | integer | Yes | Contact ID |

**Note:** This endpoint is handled by a separate controller (`Api::V1::Accounts::Contacts::ContactInboxesController`).

---

### 16. GET /api/v1/accounts/:account_id/contacts/:contact_id/labels
**Action:** `contacts/labels#index`

**Description:** List all labels for a specific contact.

**HTTP Verb:** `GET`

### 17. POST /api/v1/accounts/:account_id/contacts/:contact_id/labels
**Action:** `contacts/labels#create`

**Description:** Add labels to a specific contact.

**HTTP Verb:** `POST`

**Note:** These endpoints are handled by a separate controller (`Api::V1::Accounts::Contacts::LabelsController`).

---

### 18. CRUD /api/v1/accounts/:account_id/contacts/:contact_id/notes
**Action:** `contacts/notes#index`, `contacts/notes#show`, `contacts/notes#create`, `contacts/notes#update`, `contacts/notes#destroy`

**Description:** Full CRUD operations for notes associated with a contact.

**Note:** This endpoint is handled by a separate controller (`Api::V1::Accounts::Contacts::NotesController`).

---

## Authentication

All endpoints require a valid API access token passed via the `api_access_token` header:

```
api_access_token: <token>
```

---

## Authorization & Permissions

The Contacts Controller uses Pundit for authorization via `ContactPolicy`. Actual permission mapping:

| Action | Policy | Restriction |
|--------|--------|-------------|
| `index` | `index?` | Any account user |
| `active` | `active?` | Any account user |
| `search` | `search?` | Any account user |
| `filter` | `filter?` | Any account user |
| `show` | `show?` | Any account user |
| `create` | `create?` | Any account user |
| `update` | `update?` | Any account user |
| `destroy` | `destroy?` | Administrator only |
| `avatar` | `avatar?` | Any account user |
| `contactable_inboxes` | `contactable_inboxes?` | Any account user |
| `destroy_custom_attributes` | `destroy_custom_attributes?` | Any account user |
| `import` | `import?` | Administrator only |
| `export` | `export?` | Administrator only |

---

## Sorting Options

The controller uses the `Sift` gem for sorting. Pass a single `sort` query parameter with the field name. Prefix with `-` for descending order (e.g. `sort=-name`).

Supported sort fields:

| Field | Type | Scope |
|-------|------|-------|
| email | String | Direct |
| name | String | `order_on_name` scope |
| phone_number | String | Direct |
| last_activity_at | DateTime | `order_on_last_activity_at` scope |
| created_at | DateTime | `order_on_created_at` scope |
| company | String | `order_on_company_name` scope |
| city | String | `order_on_city` scope |
| country | String | `order_on_country_name` scope |

---

## Notes & Behaviors

1. **Contact Inboxes**: Contacts can be associated with multiple inboxes/channels. Each association is stored as a `ContactInbox` record. The `contact_inboxes` array in responses contains objects with a nested `inbox` object (using `_inbox_slim` partial) and a `source_id` field.

2. **include_contact_inboxes**: Defaults to `true`. Supported on `index`, `active`, `search`, `filter`, `show`, and `update` endpoints. When `false`, the `contact_inboxes` key is omitted from contact objects.

3. **Identifier Field**: The `identifier` field is used to link external systems (CRM, databases) to Chatwoot contacts. Must be unique per account.

4. **Avatar Processing**: When setting `avatar_url`, the image is downloaded asynchronously via `Avatar::AvatarFromUrlJob`.

5. **Custom Attributes**: Flexible key-value storage for domain-specific fields. On update, custom attributes are **merged** with existing values (not replaced).

6. **Additional Attributes**: Standard fields like city, country, website stored separately from custom attributes. On update, additional attributes are also **merged**.

7. **Online Status**: A contact is considered online if they have an active presence tracked by `OnlineStatusTracker`.

8. **Blocked Contacts**: When a contact is blocked, they cannot send new messages to the account.

9. **Import/Export**: These are asynchronous jobs. Import creates a `DataImport` record which triggers `DataImportJob`. Export triggers `Account::ContactsExportJob`. Users are notified via email when export completes.

10. **Delete Protection**: Contacts currently online cannot be deleted to prevent race conditions.

11. **CRM v2 Feature**: Contact resolution logic respects the `crm_v2` feature flag when enabled.

12. **Label Filtering**: In the index endpoint, contacts can be filtered by tag names (strings) via the `labels` parameter. Uses `tagged_with` with `any: true`.

13. **Pagination**: Default is 15 contacts per page (`RESULTS_PER_PAGE = 15`).

14. **Timestamps**: `created_at` and `last_activity_at` are rendered as Unix epoch integers (`.to_i`), not ISO 8601 strings. These fields are conditionally rendered — they are omitted entirely from the response when `nil` (e.g., `last_activity_at` for a new contact with no conversations).

15. **`thumbnail` field**: The contact's avatar URL is rendered as `thumbnail` in JSON responses (mapped from `resource.avatar_url` in the model).

16. **Search `has_more`**: The search endpoint fetches one extra record beyond the page size to determine `has_more`. This flag only appears in the search response meta, not in index/active/filter responses.
