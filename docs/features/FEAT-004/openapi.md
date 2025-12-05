# WhatsApp API Guide for AI Agents

This guide helps AI agents understand and interact with the WhatsApp Web API MultiDevice (v6.12.0).

## Table of Contents
- [Authentication](#authentication)
- [Phone Number Format](#phone-number-format)
- [API Response Format](#api-response-format)
- [Core Workflows](#core-workflows)
- [Endpoint Categories](#endpoint-categories)
- [Common Patterns](#common-patterns)
- [Error Handling](#error-handling)

## Authentication

**Type**: HTTP Basic Authentication

All API requests require basic authentication credentials in the header:

```
Authorization: Basic base64(username:password)
```

Configure credentials via environment variables:
- `BASIC_AUTH_USERNAME`
- `BASIC_AUTH_PASSWORD`

## Phone Number Format

WhatsApp uses JID (Jabber ID) format for phone numbers:

- **Individual**: `{country_code}{phone_number}@s.whatsapp.net`
  - Example: `6289685028129@s.whatsapp.net`
- **Group**: `{group_id}@g.us`
  - Example: `120363025982934543@g.us`
- **Newsletter**: `{newsletter_id}@newsletter`
  - Example: `120363024512399999@newsletter`

**Note**: When using pairing code login, provide phone number WITHOUT @ suffix:
- Example: `628912344551`

## API Response Format

All responses follow this structure:

```json
{
  "code": "SUCCESS",
  "message": "Description of result",
  "results": { /* Response data */ }
}
```

### Common Response Codes
- `SUCCESS`: Operation completed successfully
- `400`: Bad Request - validation error
- `401`: Unauthorized - authentication failed
- `404`: Not Found - resource doesn't exist
- `500`: Internal Server Error - server-side error

## Core Workflows

### 1. Initial Setup & Login

**Option A: QR Code Login**
```
GET /app/login
→ Returns QR code image URL and duration
→ User scans QR code with WhatsApp mobile app
```

**Option B: Pairing Code Login**
```
GET /app/login-with-code?phone=628912344551
→ Returns pairing code (e.g., "ABCD-1234")
→ User enters code in WhatsApp mobile app
```

### 2. Check Connection Status
```
GET /app/devices
→ Returns list of connected devices
```

### 3. Reconnect if Needed
```
GET /app/reconnect
→ Attempts to reconnect to WhatsApp servers
```

### 4. Logout & Cleanup
```
GET /app/logout
→ Removes database and logs out
```

## Endpoint Categories

### 📱 App Management (`/app/*`)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/app/login` | GET | Get QR code for login |
| `/app/login-with-code` | GET | Get pairing code for login |
| `/app/logout` | GET | Logout and remove database |
| `/app/reconnect` | GET | Reconnect to WhatsApp |
| `/app/devices` | GET | List connected devices |

### 👤 User Operations (`/user/*`)

| Endpoint | Method | Purpose | Key Parameters |
|----------|--------|---------|----------------|
| `/user/info` | GET | Get user information | `phone` |
| `/user/avatar` | GET | Get user avatar | `phone`, `is_preview`, `is_community` |
| `/user/avatar` | POST | Change own avatar | `avatar` (file) |
| `/user/pushname` | POST | Change display name | `push_name` |
| `/user/my/privacy` | GET | Get privacy settings | - |
| `/user/my/groups` | GET | List user's groups | - |
| `/user/my/newsletters` | GET | List user's newsletters | - |
| `/user/my/contacts` | GET | List user's contacts | - |
| `/user/check` | GET | Check if user is on WhatsApp | `phone` |
| `/user/business-profile` | GET | Get business profile | `phone` |

### 📤 Send Messages (`/send/*`)

| Endpoint | Method | Content Type | Required Fields |
|----------|--------|--------------|-----------------|
| `/send/message` | POST | application/json | `phone`, `message` |
| `/send/image` | POST | multipart/form-data | `phone`, `image` or `image_url` |
| `/send/audio` | POST | multipart/form-data | `phone`, `audio` or `audio_url` |
| `/send/file` | POST | multipart/form-data | `phone`, `file` |
| `/send/sticker` | POST | multipart/form-data | `phone`, `sticker` or `sticker_url` |
| `/send/video` | POST | multipart/form-data | `phone`, `video` or `video_url` |
| `/send/contact` | POST | application/json | `phone`, `contact_name`, `contact_phone` |
| `/send/link` | POST | application/json | `phone`, `link` |
| `/send/location` | POST | application/json | `phone`, `latitude`, `longitude` |
| `/send/poll` | POST | application/json | `phone`, `question`, `options`, `max_answer` |
| `/send/presence` | POST | application/json | `type` (available/unavailable) |
| `/send/chat-presence` | POST | application/json | `phone`, `action` (start/stop) |

**Common Optional Fields for Send Endpoints:**
- `reply_message_id`: Reply to a specific message
- `duration`: Disappearing message duration in seconds
- `is_forwarded`: Mark as forwarded message
- `caption`: Add caption to media
- `view_once`: Enable view-once for media
- `compress`: Compress media files

### 💬 Message Operations (`/message/{message_id}/*`)

| Endpoint | Method | Purpose | Required Fields |
|----------|--------|---------|-----------------|
| `/message/{message_id}/revoke` | POST | Delete message for everyone | `phone` |
| `/message/{message_id}/delete` | POST | Delete message for self | `phone` |
| `/message/{message_id}/reaction` | POST | React to message | `phone`, `emoji` |
| `/message/{message_id}/update` | POST | Edit message (within 15 min) | `phone`, `message` |
| `/message/{message_id}/read` | POST | Mark message as read | `phone` |
| `/message/{message_id}/star` | POST | Star message | `phone` |
| `/message/{message_id}/unstar` | POST | Unstar message | `phone` |

### 💭 Chat Operations (`/chats` & `/chat/{chat_jid}/*`)

| Endpoint | Method | Purpose | Query Parameters |
|----------|--------|---------|------------------|
| `/chats` | GET | List all chats | `limit`, `offset`, `search`, `has_media` |
| `/chat/{chat_jid}/messages` | GET | Get chat messages | `limit`, `offset`, `start_time`, `end_time`, `media_only`, `is_from_me`, `search` |
| `/chat/{chat_jid}/label` | POST | Label/unlabel chat | Body: `label_id`, `label_name`, `labeled` |
| `/chat/{chat_jid}/pin` | POST | Pin/unpin chat | Body: `pinned` |

### 👥 Group Operations (`/group/*`)

| Endpoint | Method | Purpose | Key Fields |
|----------|--------|---------|------------|
| `/group/info` | GET | Get group information | `group_id` |
| `/group` | POST | Create group | `title`, `participants[]` |
| `/group/participants` | GET | List participants | `group_id` |
| `/group/participants` | POST | Add participants | `group_id`, `participants[]` |
| `/group/participants/export` | GET | Export participants CSV | `group_id` |
| `/group/participants/remove` | POST | Remove participants | `group_id`, `participants[]` |
| `/group/participants/promote` | POST | Promote to admin | `group_id`, `participants[]` |
| `/group/participants/demote` | POST | Demote to member | `group_id`, `participants[]` |
| `/group/join-with-link` | POST | Join via invite link | `link` |
| `/group/info-from-link` | GET | Get group info from link | `link` |
| `/group/participant-requests` | GET | List join requests | `group_id` |
| `/group/participant-requests/approve` | POST | Approve join request | `group_id`, `participants[]` |
| `/group/participant-requests/reject` | POST | Reject join request | `group_id`, `participants[]` |
| `/group/leave` | POST | Leave group | `group_id` |
| `/group/photo` | POST | Set group photo | `group_id`, `photo` (file) |
| `/group/name` | POST | Set group name | `group_id`, `name` (max 25 chars) |
| `/group/locked` | POST | Lock/unlock group | `group_id`, `locked` |
| `/group/announce` | POST | Set announce mode | `group_id`, `announce` |
| `/group/topic` | POST | Set group topic | `group_id`, `topic` |
| `/group/invite-link` | GET | Get/reset invite link | `group_id`, `reset` |

### 📰 Newsletter Operations (`/newsletter/*`)

| Endpoint | Method | Purpose | Required Fields |
|----------|--------|---------|-----------------|
| `/newsletter/unfollow` | POST | Unfollow newsletter | `newsletter_id` |

## Common Patterns

### Sending a Text Message
```json
POST /send/message
{
  "phone": "6289685028129@s.whatsapp.net",
  "message": "Hello, how are you?"
}
```

### Sending a Reply
```json
POST /send/message
{
  "phone": "6289685028129@s.whatsapp.net",
  "message": "This is a reply",
  "reply_message_id": "3EB089B9D6ADD58153C561"
}
```

### Sending Disappearing Message
```json
POST /send/message
{
  "phone": "6289685028129@s.whatsapp.net",
  "message": "This will disappear",
  "duration": 3600
}
```

### Sending Image with Caption
```
POST /send/image
Content-Type: multipart/form-data

phone=6289685028129@s.whatsapp.net
caption=Check this out!
image=<binary file data>
compress=false
```

### Sending Image from URL
```
POST /send/image
Content-Type: multipart/form-data

phone=6289685028129@s.whatsapp.net
caption=Check this out!
image_url=https://example.com/image.jpg
```

### Creating a Poll
```json
POST /send/poll
{
  "phone": "6289685024421@s.whatsapp.net",
  "question": "What's your favorite color?",
  "options": ["Red", "Blue", "Green", "Yellow"],
  "max_answer": 2
}
```

### Typing Indicator
```json
// Start typing
POST /send/chat-presence
{
  "phone": "6289685024051@s.whatsapp.net",
  "action": "start"
}

// Stop typing
POST /send/chat-presence
{
  "phone": "6289685024051@s.whatsapp.net",
  "action": "stop"
}
```

### Pagination Pattern
```
GET /chats?limit=25&offset=0
GET /chats?limit=25&offset=25  // Next page
GET /chats?limit=25&offset=50  // Page 3
```

### Searching Messages
```
GET /chat/{chat_jid}/messages?search=invoice&media_only=false
```

### Filtering Messages by Date
```
GET /chat/{chat_jid}/messages?start_time=2024-01-01T00:00:00Z&end_time=2024-01-31T23:59:59Z
```

## Error Handling

### Check User Exists Before Messaging
```json
GET /user/check?phone=628912344551

Response:
{
  "code": "SUCCESS",
  "message": "Success check user",
  "results": {
    "is_on_whatsapp": true
  }
}
```

### Validate Phone Number Format
- Always include country code
- Use @ suffix for send operations: `@s.whatsapp.net`
- Don't use @ suffix for check/login operations

### Handle Message ID Responses
All send operations return a `message_id` which can be used for:
- Revoking messages
- Reacting to messages
- Editing messages (within 15 minutes)
- Replying to messages

```json
Response from send:
{
  "code": "SUCCESS",
  "message": "Success",
  "results": {
    "message_id": "3EB0B430B6F8F1D0E053AC120E0A9E5C",
    "status": "message sent successfully"
  }
}
```

## Best Practices

1. **Always check connection status** before operations:
   - Use `/app/devices` to verify connection
   - Use `/app/reconnect` if disconnected

2. **Verify user exists** before sending:
   - Use `/user/check?phone=...` to validate recipient

3. **Use appropriate content types**:
   - JSON for text/structured data
   - multipart/form-data for file uploads

4. **Handle media efficiently**:
   - Use `compress=true` for large images/videos
   - Provide `image_url`/`video_url` instead of uploading when possible

5. **Respect rate limits**:
   - WhatsApp may throttle excessive API usage
   - Implement retry logic with exponential backoff

6. **Clean up resources**:
   - Use `/app/logout` when done
   - Remove temporary files after upload

7. **Message editing constraints**:
   - Messages can only be edited within 15 minutes
   - Use `/message/{message_id}/update` endpoint

8. **Group operations require admin rights**:
   - Setting name, photo, topic requires admin
   - Promoting/demoting requires super admin

## Quick Reference

### Base URL
```
http://localhost:3000
```

### Essential Endpoints for Getting Started
1. Login: `GET /app/login-with-code?phone={phone}`
2. Check status: `GET /app/devices`
3. Send message: `POST /send/message`
4. Get contacts: `GET /user/my/contacts`
5. List chats: `GET /chats`

### Message ID Operations
After sending a message, save the `message_id` to:
- `/message/{message_id}/revoke` - Delete for everyone
- `/message/{message_id}/reaction` - Add emoji reaction
- `/message/{message_id}/update` - Edit message text
- `/message/{message_id}/read` - Mark as read

---

**Version**: 6.12.0
**Protocol**: OpenAPI 3.0.0
**Base URL**: http://localhost:3000 (configurable via `APP_PORT` env var)
