# Teams Controller API Documentation

**Controller Location:** `app/controllers/api/v1/accounts/teams_controller.rb`

**Base Path:** `/api/v1/accounts/:account_id/teams`

**Authentication:** Required (API key via `api_access_token` header)

**Authorization:** User must have appropriate access to the account (Pundit policies)

---

## Overview

The Teams Controller manages team/group creation and management within an account. Teams allow organizing agents into groups that can be assigned to conversations, inboxes, and serve as organizational units for workflow management.

---

## Endpoints

### 1. GET /api/v1/accounts/:account_id/teams
**Action:** `index`

**Description:** List all teams in an account.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Query Parameters:** None

**Response Format:** Bare JSON array of team objects

**Example Response:**
```json
[
  {
    "id": 1,
    "name": "support team",
    "description": "Our main support team",
    "allow_auto_assign": true,
    "account_id": 1,
    "is_member": true
  },
  {
    "id": 2,
    "name": "sales team",
    "description": "Sales and onboarding",
    "allow_auto_assign": false,
    "account_id": 1,
    "is_member": false
  }
]
```

**Authorization:** Any account user (Pundit `index?` returns `true` for all users)

---

### 2. GET /api/v1/accounts/:account_id/teams/:id
**Action:** `show`

**Description:** Retrieve a single team with full details.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Team ID |

**Parameters:** None

**Response Format:** JSON with team details

**Example Response:**
```json
{
  "id": 1,
  "name": "support team",
  "description": "Our main support team",
  "allow_auto_assign": true,
  "account_id": 1,
  "is_member": true
}
```

**Authorization:** Any account user (Pundit `show?` returns `true` for all users)

---

### 3. POST /api/v1/accounts/:account_id/teams
**Action:** `create`

**Description:** Create a new team.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |

**Parameters:**

#### Request Body:
```json
{
  "team": {
    "name": "Support Team",
    "description": "Our main support team",
    "allow_auto_assign": true
  }
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| team.name | string | Yes | Team name (must be unique in account; automatically lowercased via `before_validation`) |
| team.description | string | No | Team description |
| team.allow_auto_assign | boolean | No | Allow automatic assignment to this team (default: `true`) |

**Validation:**
- `name` must be present and unique per account
- `name` is automatically downcased before validation (e.g., "Support Team" becomes "support team")
- `description` is optional

**Response Format:** JSON with created team

**Example Response:**
```json
{
  "id": 3,
  "name": "support team",
  "description": "Our main support team",
  "allow_auto_assign": true,
  "account_id": 1,
  "is_member": true
}
```

**Error Response (Duplicate Name):**
```json
{
  "message": "Name has already been taken",
  "attributes": ["name"]
}
```
Status: `422 Unprocessable Entity`

**Authorization:** Administrator only (Pundit `create?` requires `@account_user.administrator?`)

---

### 4. PATCH /api/v1/accounts/:account_id/teams/:id
**Action:** `update`

**Description:** Update team information.

**HTTP Verb:** `PATCH` or `PUT`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Team ID |

**Parameters:**

#### Request Body:
```json
{
  "team": {
    "name": "Updated Team Name",
    "description": "Updated description",
    "allow_auto_assign": false
  }
}
```

**Parameter Details:** Same as create endpoint

**Response Format:** JSON with updated team

**Example Response:**
```json
{
  "id": 1,
  "name": "updated team name",
  "description": "Updated description",
  "allow_auto_assign": false,
  "account_id": 1,
  "is_member": true
}
```

**Authorization:** Administrator only (Pundit `update?` requires `@account_user.administrator?`)

---

### 5. DELETE /api/v1/accounts/:account_id/teams/:id
**Action:** `destroy`

**Description:** Delete a team.

**HTTP Verb:** `DELETE`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| id | integer | Yes | Team ID |

**Parameters:** None

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Behavior:**
- Deletes the team permanently
- Associated team members are destroyed asynchronously (`dependent: :destroy_async`)
- Conversations assigned to the team remain but team reference is nullified (`dependent: :nullify`)

**Authorization:** Administrator only (Pundit `destroy?` requires `@account_user.administrator?`)

---

## Team Member Management

Teams are associated with team members through nested routes:

### GET /api/v1/accounts/:account_id/teams/:id/team_members
**Description:** List all members of a team

### POST /api/v1/accounts/:account_id/teams/:id/team_members
**Description:** Add members to a team

### PATCH /api/v1/accounts/:account_id/teams/:id/team_members
**Description:** Update team members

### DELETE /api/v1/accounts/:account_id/teams/:id/team_members
**Description:** Remove members from a team

See the **Team Members Endpoints** section below for detailed documentation.

---

## Team Members Endpoints

### GET /api/v1/accounts/:account_id/teams/:team_id/team_members
**Action:** `index` (on team_members)

**Description:** List all agents in a team.

**HTTP Verb:** `GET`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| team_id | integer | Yes | Team ID |

**Response Format:** Bare JSON array of agent objects

**Example Response:**
```json
[
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
    "thumbnail": null
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
    "thumbnail": "https://example.com/avatars/bob.png"
  }
]
```

**Authorization:** Any account user (Pundit `index?` returns `true` for all users)

---

### POST /api/v1/accounts/:account_id/teams/:team_id/team_members
**Action:** `create` (on team_members)

**Description:** Add agents to a team.

**HTTP Verb:** `POST`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| team_id | integer | Yes | Team ID |

**Parameters:**

#### Request Body:
```json
{
  "user_ids": [2, 3, 4]
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_ids | array of integers | Yes | Array of user/agent IDs to add to the team |

**Behavior:**
- User IDs that already belong to the team are silently filtered out (no error raised for duplicates)
- Only users that are not yet members are added
- If any user ID does not belong to the account, the request is rejected

**Response Format:** JSON array of the newly added agent objects

**Example Response:**
```json
[
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
    "thumbnail": null
  }
]
```

**Error Response (Invalid User IDs):**
```json
{
  "error": "Invalid User IDs"
}
```
Status: `401 Unauthorized` -- returned when any provided user ID does not belong to the account.

**Authorization:** Administrator only (Pundit `create?` requires `@account_user.administrator?`)

---

### PATCH /api/v1/accounts/:account_id/teams/:team_id/team_members
**Action:** `update` (on team_members, collection)

**Description:** Update team members (bulk operation).

**HTTP Verb:** `PATCH`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| team_id | integer | Yes | Team ID |

**Parameters:**

#### Request Body:
```json
{
  "user_ids": [2, 3, 4]
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_ids | array of integers | Yes | Array of user IDs to set as the complete team membership |

**Behavior:**
- Replaces entire team membership with the provided user IDs
- Removes users not in the array
- Adds users in the array that were not already members
- Existing members that remain in the list are left untouched

**Response Format:** JSON array of all current team member agent objects (after the update)

**Example Response:**
```json
[
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
    "thumbnail": null
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
    "thumbnail": "https://example.com/avatars/bob.png"
  }
]
```

**Error Response (Invalid User IDs):**
```json
{
  "error": "Invalid User IDs"
}
```
Status: `401 Unauthorized` -- returned when any provided user ID does not belong to the account.

**Authorization:** Administrator only (Pundit `update?` requires `@account_user.administrator?`)

---

### DELETE /api/v1/accounts/:account_id/teams/:team_id/team_members
**Action:** `destroy` (on team_members, collection)

**Description:** Remove agents from a team.

**HTTP Verb:** `DELETE`

**URL Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID |
| team_id | integer | Yes | Team ID |

**Parameters:**

#### Request Body:
```json
{
  "user_ids": [2, 3]
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_ids | array of integers | Yes | Array of user IDs to remove from team |

**Response Format:** No content (returns `200 OK`)

**Response:**
```
200 OK
```

**Error Response (Invalid User IDs):**
```json
{
  "error": "Invalid User IDs"
}
```
Status: `401 Unauthorized` -- returned when any provided user ID does not belong to the account.

**Authorization:** Administrator only (Pundit `destroy?` requires `@account_user.administrator?`)

---

## Error Responses

### 401 Unauthorized
Returned when authentication fails or when the Pundit policy denies access:
```json
{
  "error": "You are not authorized to do this action"
}
```

Also returned by `validate_member_id_params` when invalid user IDs are provided:
```json
{
  "error": "Invalid User IDs"
}
```

### 404 Not Found
Returned when the team or account is not found (`ActiveRecord::RecordNotFound`):
```json
{
  "error": "Resource could not be found"
}
```

### 422 Unprocessable Entity
Returned when model validation fails (`ActiveRecord::RecordInvalid`):
```json
{
  "message": "Name has already been taken",
  "attributes": ["name"]
}
```

Returned when required parameters are missing (`ActionController::ParameterMissing`):
```json
{
  "error": "param is missing or the value is empty: team"
}
```

---

## Authentication

All endpoints require a valid API access token passed via the `api_access_token` header:

```
api_access_token: <token>
```

Alternatively, session-based authentication (Devise) is supported when the header is not present.

---

## Authorization & Permissions

Both the Teams Controller and Team Members Controller use Pundit for authorization with the following policies:

**TeamPolicy:**

| Action | Permission |
|--------|------------|
| `index?` | Any account user |
| `show?` | Any account user |
| `create?` | Administrator only |
| `update?` | Administrator only |
| `destroy?` | Administrator only |

**TeamMemberPolicy:**

| Action | Permission |
|--------|------------|
| `index?` | Any account user |
| `create?` | Administrator only |
| `update?` | Administrator only |
| `destroy?` | Administrator only |

---

## Rate Limiting

No specific rate limiting documented. Standard Rails rate limits apply.

---

## Notes & Behaviors

1. **Unique Names**: Team names must be unique within an account. Two different accounts can have teams with the same name.

2. **Name Downcasing**: Team names are automatically lowercased via a `before_validation` callback. For example, submitting "Support Team" stores and returns "support team".

3. **Auto-Assignment**: When `allow_auto_assign` is true (the default), conversations can be automatically assigned to members of this team based on assignment rules.

4. **Team Members**: Agents are associated with teams through the `TeamMember` model. An agent can be a member of multiple teams.

5. **Nested Routes**: Team members are accessed through nested team routes (teams/:team_id/team_members).

6. **Bulk Member Updates**: The PATCH endpoint replaces the entire team membership. Provide the complete list of user IDs you want as members.

7. **Duplicate Member Handling**: Adding a user who is already a team member does not raise an error. Duplicates are silently filtered out in the `create` and `update` actions.

8. **Deletion Cleanup**: When a team is deleted, team member associations are destroyed asynchronously (`destroy_async`), and conversations have their team reference nullified.

9. **Conversation Assignment**: Conversations can be assigned to teams, and then team members can work on those conversations.

10. **`is_member` Field**: All team responses include an `is_member` boolean indicating whether the currently authenticated user is a member of that team.

11. **Agent Response Shape**: Team member endpoints return agent objects with fields: `id`, `account_id`, `availability_status`, `auto_offline`, `confirmed`, `email`, `provider`, `available_name`, `name`, `role`, `thumbnail`, and optionally `custom_attributes` (if present) and `custom_role_id` (Enterprise only).
