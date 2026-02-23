# Profile Controller API Documentation

**Controller Location:** `app/controllers/api/v1/profiles_controller.rb`

**Base Path:** `/api/v1/profile`

**Authentication:** Required (API key via `api_access_token` header)

---

## Overview

The Profile Controller manages user profile operations including personal information, password management, account availability settings, and authentication tokens. All endpoints operate on the currently authenticated user's profile.

---

## Authentication

All endpoints require a valid API access token passed via the `api_access_token` header:

```
api_access_token: <token>
```

---

## Permissions

All profile endpoints operate on the currently authenticated user (`current_user`). Any authenticated user can access their own profile -- there is no additional Pundit authorization check.

---

## Endpoints

### 1. GET /api/v1/profile
**Action:** `show`

**Description:** Retrieve the current user's profile information.

**HTTP Verb:** `GET`

**Parameters:** None

**Response Format:** JSON object containing user profile data (rendered via `_user.json.jbuilder`)

**Example Response:**
```json
{
  "id": 1,
  "access_token": "abc123token",
  "account_id": 1,
  "available_name": "John Doe",
  "avatar_url": "https://example.com/avatar.png",
  "confirmed": true,
  "display_name": "John",
  "message_signature": "Best regards,\nJohn",
  "email": "agent@example.com",
  "hmac_identifier": "hmac_id_value",
  "inviter_id": null,
  "name": "John Doe",
  "provider": "email",
  "pubsub_token": "pubsub_token_value",
  "custom_attributes": {
    "phone_number": "+1-555-0123"
  },
  "role": "agent",
  "ui_settings": {},
  "uid": "agent@example.com",
  "type": "user",
  "accounts": [
    {
      "id": 1,
      "name": "Acme Inc",
      "status": "active",
      "active_at": "2026-02-23T10:00:00.000Z",
      "role": "agent",
      "permissions": ["conversation_manage"],
      "availability": "online",
      "availability_status": "online",
      "auto_offline": true
    }
  ]
}
```

**Notes:**
- `hmac_identifier` is only included when the `CHATWOOT_INBOX_HMAC_KEY` global config is present.
- `custom_attributes` is only included when the user has custom attributes set.
- `account_id` reflects the active account user's account ID.
- `inviter_id` reflects the active account user's inviter ID.
- `role` reflects the active account user's role.

**Authorization:** Any authenticated user

---

### 2. PATCH/PUT /api/v1/profile
**Action:** `update`

**Description:** Update the current user's profile information including name, email, avatar, settings, and optionally password.

**HTTP Verb:** `PATCH` or `PUT`

**Parameters:**

#### Request Body Structure:
```json
{
  "profile": {
    "email": "newemail@example.com",
    "name": "New Name",
    "display_name": "Display Name",
    "avatar": "<File Object>",
    "message_signature": "Email signature text",
    "account_id": 1,
    "phone_number": "+1-555-0123",
    "ui_settings": {
      "custom_key": "custom_value"
    },
    "current_password": "current_password_here",
    "password": "new_password_here",
    "password_confirmation": "new_password_here"
  }
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| email | string | No | User's email address |
| name | string | No | User's full name |
| display_name | string | No | Name to display in UI |
| avatar | file | No | Avatar image file |
| message_signature | string | No | Email message signature |
| account_id | integer | No | Associated account ID |
| phone_number | string | No | Contact phone number (stored in `custom_attributes`) |
| ui_settings | object | No | Custom UI settings object (replaces existing; use PATCH with full object) |
| current_password | string | Conditional | Required if updating password |
| password | string | Conditional | New password (requires current_password) |
| password_confirmation | string | Conditional | Password confirmation (must match password) |

**Validation:**
- If `password` is provided, `current_password` must be valid
- `password_confirmation` must match `password` exactly
- Password update is processed first and separately from other profile fields
- `custom_attributes` are merged (not replaced) with existing values

**Response Format:** Full user profile JSON (same structure as GET `/api/v1/profile`)

**Authorization:** Any authenticated user

---

### 3. DELETE /api/v1/profile/avatar
**Action:** `avatar`

**Description:** Remove/delete the current user's avatar image. The user is reloaded after deletion to reflect the updated state.

**HTTP Verb:** `DELETE`

**Parameters:** None

**Response Format:** Full user profile JSON (same structure as GET `/api/v1/profile`)

**Authorization:** Any authenticated user

---

### 4. POST /api/v1/profile/auto_offline
**Action:** `auto_offline`

**Description:** Update the auto-offline setting for a specific account.

**HTTP Verb:** `POST`

**Parameters:**

#### Request Body:
```json
{
  "profile": {
    "account_id": 1,
    "auto_offline": true
  }
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID to update |
| auto_offline | boolean | No | Enable/disable auto-offline (defaults to `false`) |

**Response Format:** Full user profile JSON (same structure as GET `/api/v1/profile`)

**Authorization:** Any authenticated user. The user must have an `account_user` record for the given `account_id` (raises `RecordNotFound` otherwise via `find_by!`).

---

### 5. POST /api/v1/profile/availability
**Action:** `availability`

**Description:** Update the availability status for a specific account (online/offline/busy).

**HTTP Verb:** `POST`

**Parameters:**

#### Request Body:
```json
{
  "profile": {
    "account_id": 1,
    "availability": "online"
  }
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID to update |
| availability | string | Yes | Availability status: `online`, `offline`, or `busy` |

**Response Format:** Full user profile JSON (same structure as GET `/api/v1/profile`)

**Authorization:** Any authenticated user. The user must have an `account_user` record for the given `account_id` (raises `RecordNotFound` otherwise via `find_by!`).

---

### 6. PUT /api/v1/profile/set_active_account
**Action:** `set_active_account`

**Description:** Set the active/current account for the user and update the `active_at` timestamp.

**HTTP Verb:** `PUT`

**Parameters:**

#### Request Body:
```json
{
  "profile": {
    "account_id": 1
  }
}
```

**Parameter Details:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| account_id | integer | Yes | Account ID to set as active |

**Response Format:** No content body (returns `200 OK` with `head :ok`)

**Authorization:** Any authenticated user. Unlike `auto_offline` and `availability` (which use `find_by!`), `set_active_account` uses `find_by`. If the `account_id` does not match any of the user's accounts, this results in a `NoMethodError` (500) rather than a `RecordNotFound` (404).

---

### 7. POST /api/v1/profile/resend_confirmation
**Action:** `resend_confirmation`

**Description:** Resend the email confirmation to the user. Only sends an email if the user is not yet confirmed.

**HTTP Verb:** `POST`

**Parameters:** None

**Response Format:** No content body (returns `200 OK` with `head :ok`)

**Authorization:** Any authenticated user

**Note:** This endpoint always returns `200 OK` regardless of whether the user is already confirmed.

---

### 8. POST /api/v1/profile/reset_access_token
**Action:** `reset_access_token`

**Description:** Regenerate the user's API access token. The user is reloaded after regeneration to reflect the new token.

**HTTP Verb:** `POST`

**Parameters:** None

**Response Format:** Full user profile JSON (same structure as GET `/api/v1/profile`), including the new `access_token` value.

**Authorization:** Any authenticated user

**Security Note:** This invalidates the previous access token immediately. Subsequent requests must use the new token.

---

## MFA Endpoints

**Controller Location:** `app/controllers/api/v1/profile/mfa_controller.rb`

**Base Path:** `/api/v1/profile/mfa`

**Authentication:** Required (API key via `api_access_token` header)

**Feature Gate:** All MFA endpoints require the MFA feature to be enabled (`Chatwoot.mfa_enabled?`). If not enabled, all endpoints return `403 Forbidden` with:
```json
{
  "error": "MFA feature is not available. Please configure encryption keys."
}
```

---

### 9. GET /api/v1/profile/mfa
**Action:** `show`

**Description:** Check the current MFA status for the authenticated user.

**HTTP Verb:** `GET`

**Parameters:** None

**Response Format:**
```json
{
  "feature_available": true,
  "enabled": false,
  "backup_codes_generated": true
}
```

**Field Details:**

| Field | Type | Description |
|-------|------|-------------|
| feature_available | boolean | Whether MFA is enabled at the instance level |
| enabled | boolean | Whether the user has MFA enabled |
| backup_codes_generated | boolean | Whether backup codes have been generated (only present when MFA feature is available) |

**Authorization:** Any authenticated user

---

### 10. POST /api/v1/profile/mfa
**Action:** `create`

**Description:** Begin MFA setup by generating a TOTP secret and provisioning URI. This initiates the enrollment process but does not activate MFA until verified.

**HTTP Verb:** `POST`

**Parameters:** None

**Before Filters:**
- MFA must not already be enabled (returns 422 with `"MFA is already enabled"` if it is)

**Response Format:**
```json
{
  "provisioning_url": "otpauth://totp/Chatwoot:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Chatwoot",
  "secret": "JBSWY3DPEHPK3PXP"
}
```

**Field Details:**

| Field | Type | Description |
|-------|------|-------------|
| provisioning_url | string | OTP Auth URI for scanning with an authenticator app |
| secret | string | The TOTP secret key |

**Authorization:** Any authenticated user

---

### 11. POST /api/v1/profile/mfa/verify
**Action:** `verify`

**Description:** Verify a TOTP code to complete MFA activation. On success, returns backup codes that should be stored securely.

**HTTP Verb:** `POST`

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| otp_code | string | Yes | The TOTP code from the authenticator app |

**Before Filters:**
- MFA must not already be enabled (returns 422 with `"MFA is already enabled"` if it is)
- OTP code must be valid (returns 422 with `"Invalid verification code"` if it is not)

**Response Format:**
```json
{
  "enabled": true,
  "backup_codes": ["code1", "code2", "code3"]
}
```

**Field Details:**

| Field | Type | Description |
|-------|------|-------------|
| enabled | boolean | MFA enabled status (should be `true` after successful verification) |
| backup_codes | array | One-time-use backup codes (only returned on initial verification) |

**Authorization:** Any authenticated user

---

### 12. DELETE /api/v1/profile/mfa
**Action:** `destroy`

**Description:** Disable MFA for the authenticated user. Requires both a valid OTP code and the user's password for security.

**HTTP Verb:** `DELETE`

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| otp_code | string | Yes | A valid TOTP code from the authenticator app |
| password | string | Yes | The user's current password |

**Before Filters:**
- MFA must be currently enabled (returns 422 with `"MFA is not enabled"` if it is not)
- OTP code must be valid (returns 422 with `"Invalid verification code"` if it is not)
- Password must be valid (returns 422 with `"Invalid credentials or verification code"` if it is not)

**Response Format:**
```json
{
  "enabled": false
}
```

**Authorization:** Any authenticated user

---

### 13. POST /api/v1/profile/mfa/backup_codes
**Action:** `backup_codes`

**Description:** Regenerate MFA backup codes. Requires a valid OTP code. This replaces any previously generated backup codes.

**HTTP Verb:** `POST`

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| otp_code | string | Yes | A valid TOTP code from the authenticator app |

**Before Filters:**
- MFA must be currently enabled (returns 422 with `"MFA is not enabled"` if it is not)
- OTP code must be valid (returns 422 with `"Invalid verification code"` if it is not)

**Response Format:**
```json
{
  "backup_codes": ["code1", "code2", "code3"]
}
```

**Authorization:** Any authenticated user

---

## Error Responses

### 401 Unauthorized
Returned when no valid authentication token is provided.
```json
{
  "error": "Unauthorized"
}
```

### 403 Forbidden
Returned when MFA feature is not available at the instance level.
```json
{
  "error": "MFA feature is not available. Please configure encryption keys."
}
```

### 404 Not Found
Returned when a referenced record does not exist (e.g., `account_id` not found in `account_users`).
```json
{
  "error": "Resource could not be found"
}
```

### 422 Unprocessable Entity (Custom Error)
Returned by `render_could_not_create_error` for validation failures such as invalid password or MFA errors.
```json
{
  "error": "Invalid current password"
}
```

### 422 Unprocessable Entity (RecordInvalid)
Returned by the global `rescue_from ActiveRecord::RecordInvalid` handler when a model save fails validation.
```json
{
  "message": "Email has already been taken",
  "attributes": ["email"]
}
```

---

## Data Validation

### Password Requirements
- Password must meet Rails default validation requirements
- Must include `password` and `password_confirmation` fields
- Current password must be valid

### Email Format
- Must be valid email format
- Must be unique in the system

### Availability Values
- `online` - User is available
- `offline` - User is not available
- `busy` - User is busy

---

## Notes & Behaviors

1. **Avatar Deletion**: The DELETE `/profile/avatar` endpoint removes the attached avatar file and reloads the user (`@user.reload`) before rendering the response.

2. **Custom Attributes**: The `phone_number` field is stored in `custom_attributes` and is merged with existing custom attributes (not replaced).

3. **UI Settings**: The `ui_settings` field is a flexible JSON object that can store any custom UI-related settings.

4. **Account Context**: Operations like `auto_offline` and `availability` are account-scoped, meaning a user can have different settings across multiple accounts. They use `find_by!` which raises `RecordNotFound` if the user does not belong to the specified account.

5. **Access Token Regeneration**: Regenerating the access token invalidates previous tokens immediately. The user is reloaded before rendering to include the new token.

6. **Email Confirmation**: The resend confirmation endpoint only sends an email if the user hasn't confirmed their email yet, but always returns `200 OK`.

7. **MFA Enrollment Flow**: The MFA workflow is: (1) `POST /mfa` to generate a secret, (2) configure an authenticator app with the provisioning URL, (3) `POST /mfa/verify` with an OTP code to activate MFA and receive backup codes.

8. **Response Consistency**: All profile endpoints (show, update, avatar, auto_offline, availability, reset_access_token) return the full user profile via the `_user.json.jbuilder` partial. The `set_active_account` and `resend_confirmation` endpoints return `head :ok` with no body.
