# Agents Controller API Documentation

**Controller Location:** `app/controllers/api/v1/accounts/agents_controller.rb`

**Base Path:** `/api/v1/accounts/:account_id/agents`

**Authentication:** Required (API key via `api_access_token` header)

**Authorization:** User must have appropriate access to the account. Uses Pundit with `UserPolicy` for authorization checks.

---

## Overview

The Agents Controller manages agent (team member) CRUD operations, availability settings, role assignments, and bulk creation. Agents are users assigned to accounts who can respond to conversations.

---

## Endpoints

### 1. GET /api/v1/accounts/:account_id/agents
**Action:** `index`

**Description:** List all agents in an account.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Query Parameters:** None

**Response Format:** Bare JSON array of agent objects

**Example Response:**
```json
[
  {
    "id": 2,
    "account_id": 1,
    "availability_status": "online",
    "auto_offline": false,
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
    "custom_attributes": { "department": "support" },
    "name": "Bob Smith",
    "role": "administrator",
    "thumbnail": null,
    "custom_role_id": 5
  }
]
```

**Note:** `custom_attributes` is only included when present (non-empty). `custom_role_id` is only included on Enterprise editions.

**Authorization:** Any authenticated account user (`UserPolicy#index?` returns `true` for all users)

---

### 2. POST /api/v1/accounts/:account_id/agents
**Action:** `create`

**Description:** Create and invite a new agent to the account.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Parameters:**

#### Request Body:
```json
{
  "agent": {
    "email": "newagent@example.com",
    "name": "New Agent",
    "role": "agent",
    "availability": "online",
    "auto_offline": false
  }
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| agent.email | string | Yes | Agent's email address (must be valid and unique) |
| agent.name | string | No | Agent's full name |
| agent.role | string | No | Agent role: `agent` or `administrator` (default: `agent`) |
| agent.availability | string | No | Initial availability: `online`, `offline`, `busy` (default: `offline`) |
| agent.auto_offline | boolean | No | Enable auto-offline after inactivity (default: false) |

**Validation:**
- `email` must be valid and unique globally
- If user with this email exists, they are added to this account
- If user doesn't exist, they are created and invited via email
- Account must have available agent capacity (license limit)

**Response Format:** JSON with created agent

**Example Response:**
```json
{
  "id": 4,
  "account_id": 1,
  "availability_status": "online",
  "auto_offline": false,
  "confirmed": false,
  "email": "newagent@example.com",
  "provider": "email",
  "available_name": "New Agent",
  "name": "New Agent",
  "role": "agent",
  "thumbnail": null
}
```

**Error Response (Limit Exceeded — 402 Payment Required):**
```json
{
  "error": "Account limit exceeded. Please purchase more licenses"
}
```

**Error Response (Duplicate Email — 422 Unprocessable Entity):**
```json
{
  "error": "Email has already been taken"
}
```

**Side Effects:**
- If new user: Creates user record and sends confirmation email
- Creates `AccountUser` association with specified role
- Uses `AgentBuilder` service for creation

**Authorization:** User must be an administrator (`UserPolicy#create?` requires `administrator?`)

---

### 3. PATCH /api/v1/accounts/:account_id/agents/:id
**Action:** `update`

**Description:** Update an agent's information within the account.

**HTTP Verb:** `PATCH` or `PUT`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Agent/User ID |

**Parameters:**

#### Request Body:
```json
{
  "agent": {
    "name": "Updated Name",
    "role": "administrator",
    "availability": "offline",
    "auto_offline": true
  }
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| agent.name | string | No | Update agent's name (applied to User record) |
| agent.role | string | No | Update role: `agent` or `administrator` (applied to AccountUser record) |
| agent.availability | string | No | Update availability: `online`, `offline`, `busy` (applied to AccountUser record) |
| agent.auto_offline | boolean | No | Update auto-offline setting (applied to AccountUser record) |

**Response Format:** JSON with updated agent

**Example Response:**
```json
{
  "id": 2,
  "account_id": 1,
  "availability_status": "offline",
  "auto_offline": true,
  "confirmed": true,
  "email": "jane@example.com",
  "provider": "email",
  "available_name": "Updated Name",
  "name": "Updated Name",
  "role": "administrator",
  "thumbnail": "https://cdn.example.com/avatar.jpg"
}
```

**Authorization:** User must be an administrator (`UserPolicy#update?` requires `administrator?`)

---

### 4. DELETE /api/v1/accounts/:account_id/agents/:id
**Action:** `destroy`

**Description:** Remove an agent from the account.

**HTTP Verb:** `DELETE`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Agent/User ID |

**Parameters:** None

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Behavior:**
- Removes the agent from the account (deletes `AccountUser` record)
- If agent has no other accounts, deletes the User record entirely
- Deletes via `DeleteObjectJob` asynchronously

**Authorization:** User must be an administrator (`UserPolicy#destroy?` requires `administrator?`)

---

### 5. POST /api/v1/accounts/:account_id/agents/bulk_create
**Action:** `bulk_create`

**Description:** Bulk create multiple agents from a list of email addresses.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Parameters:**

#### Request Body:
```json
{
  "emails": [
    "agent1@example.com",
    "agent2@example.com",
    "agent3@example.com"
  ]
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| emails | array | Yes | Array of email addresses to create agents from |

**Validation:**
- Each email must be valid
- Account must have license capacity for all emails (checked before processing)

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Behavior:**
- Creates agents with default settings (email prefix as name, role=agent)
- Sends invitation emails to each new agent
- Continues on error (logs and skips individual failures)
- Clears `onboarding_step` custom attribute after completion
- Used primarily during account onboarding

**Error Response (Limit Exceeded — 402 Payment Required):**
```json
{
  "error": "Account limit exceeded. Please purchase more licenses"
}
```

**Side Effects:**
- Creates User record for each new email (if doesn't exist)
- Creates AccountUser association with role=agent
- Sends confirmation/invitation emails
- Marks onboarding as complete

**Authorization:** User must be an administrator (`UserPolicy#bulk_create?` requires `administrator?`)

---

## Agent Roles

- **agent** - Regular support agent (default)
- **administrator** - Full account access

---

## Agent Availability

- **online** - Available to receive conversations
- **offline** - Not available
- **busy** - Available but busy (can still receive)

---

## Agent Response Fields

Fields rendered by the `_agent.json.jbuilder` partial:

| Field | Type | Description |
|-------|------|-------------|
| id | integer | User ID |
| account_id | integer | Current account ID |
| availability_status | string | Current availability (`online`, `offline`, `busy`) |
| auto_offline | boolean | Whether auto-offline is enabled |
| confirmed | boolean | Whether the user has confirmed their email |
| email | string | Agent's email address |
| provider | string | Authentication provider (e.g. `email`) |
| available_name | string | Display name (may differ from `name`) |
| custom_attributes | object | Custom attributes (only present when non-empty) |
| name | string | Agent's full name |
| role | string | Role in the current account (`agent` or `administrator`) |
| thumbnail | string | URL to the agent's avatar image |
| custom_role_id | integer | Custom role ID (Enterprise edition only) |

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
  "error": "You don't have permission to manage agents"
}
```

### 402 Payment Required
```json
{
  "error": "Account limit exceeded. Please purchase more licenses"
}
```

### 404 Not Found
```json
{
  "error": "Agent not found"
}
```

### 422 Unprocessable Entity
```json
{
  "error": "Email has already been taken"
}
```

---

## Authentication

All endpoints require a valid API key passed via header:

```
api_access_token: <token>
```

---

## Authorization & Permissions

Agents Controller uses Pundit with `UserPolicy` for authorization. The policy methods map directly to controller actions:

- `index?` — Returns `true` for all authenticated account users
- `create?` — Requires `administrator?` role
- `update?` — Requires `administrator?` role
- `destroy?` — Requires `administrator?` role
- `bulk_create?` — Requires `administrator?` role

**Authorization Context:** The controller calls `check_authorization` with the `User` model class (`super(User)`), so Pundit resolves to `UserPolicy`.

---

## Rate Limiting

No specific rate limiting documented. Standard Rails rate limits apply. However, account license limits are enforced for `create` and `bulk_create`.

---

## Notes & Behaviors

1. **License Limits**: Each account has a maximum number of agents based on plan. Creation fails with 402 Payment Required if the limit is reached.

2. **AgentBuilder Service**: Agent creation uses `AgentBuilder` service which handles:
   - User creation if needed
   - AccountUser association
   - Invitation emails
   - Default settings

3. **Bulk Create Onboarding**: Bulk create is primarily for account setup. It:
   - Ignores individual failures
   - Clears onboarding_step marker
   - Logs skipped emails

4. **Account-Scoped Settings**: Each agent can have different:
   - Roles per account (admin in one, agent in another)
   - Availability per account
   - Auto-offline settings per account

5. **Deletion Behavior**: When removing an agent:
   - If agent has other accounts, just removes from this account
   - If agent has no other accounts, user record is deleted entirely via `DeleteObjectJob`

6. **Email as Identity**: Emails are globally unique. Adding same email to multiple accounts adds them as an agent to each.

7. **Name Defaults**: In bulk_create, if name is not provided, email prefix is used as name.

8. **Update Split**: The update action applies `name` to the User record and `role`, `availability`, `auto_offline` to the AccountUser record (`current_account_user`).

9. **Agent Status**: A user's `confirmed` status indicates if they've activated their account via email confirmation link.

10. **List Ordering**: Agents are sorted by full name in the index endpoint.

11. **Avatar Attachment**: Agents inherit avatar from User model which supports file attachments. The URL is exposed as `thumbnail` in the API response.

12. **Enterprise Fields**: `custom_role_id` is only included in responses when running the Enterprise edition (`ChatwootApp.enterprise?`).
