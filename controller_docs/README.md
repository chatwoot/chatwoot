# Chatwoot Controller API Documentation

This folder contains comprehensive API documentation for the core Chatwoot controllers. Each markdown file documents a complete API resource with all HTTP methods, parameters, request/response examples, error codes, and behavioral notes.

---

## 📚 Documentation Files

### 1. [Profile Controller](./profile.md)
**Path:** `/api/v1/profile`
**Key Endpoints:**
- `GET /api/v1/profile` - Get current user profile
- `PATCH /api/v1/profile` - Update profile & password
- `DELETE /api/v1/profile/avatar` - Remove avatar
- `POST /api/v1/profile/availability` - Update availability status
- `POST /api/v1/profile/auto_offline` - Toggle auto-offline
- `PUT /api/v1/profile/set_active_account` - Set active account
- `POST /api/v1/profile/reset_access_token` - Regenerate API token
- `POST /api/v1/profile/resend_confirmation` - Resend email confirmation

**Use Case:** Managing user profile settings, authentication tokens, and account preferences.

---

### 2. [Conversations Controller](./conversations.md)
**Path:** `/api/v1/accounts/:account_id/conversations`
**Key Endpoints:**
- `GET /conversations` - List conversations (with pagination, filtering, sorting)
- `GET /conversations/meta` - Get conversation count
- `GET /conversations/search` - Search conversations
- `POST /conversations/filter` - Advanced filtering
- `GET /conversations/:id` - View conversation details
- `GET /conversations/:id/attachments` - List conversation attachments
- `POST /conversations` - Create new conversation
- `PATCH /conversations/:id` - Update conversation properties
- `POST /conversations/:id/toggle_status` - Change status (open/resolved/pending)
- `POST /conversations/:id/toggle_priority` - Update priority
- `POST /conversations/:id/mute` / `unmute` - Suppress/restore notifications
- `POST /conversations/:id/transcript` - Email conversation transcript
- `POST /conversations/:id/custom_attributes` - Update custom fields
- `DELETE /conversations/:id` - Delete conversation
- `POST /conversations/:id/update_last_seen` - Mark as read
- `POST /conversations/:id/unread` - Mark as unread
- `POST /conversations/:id/toggle_typing_status` - Broadcast typing indicator

**Use Case:** Managing conversation lifecycle, status tracking, and agent-customer interactions.

---

### 3. [Messages Controller](./messages.md)
**Path:** `/api/v1/accounts/:account_id/conversations/:conversation_id/messages`
**Key Endpoints:**
- `GET /messages` - List messages in conversation
- `POST /messages` - Send new message
- `PATCH /messages/:id` - Update message status (API inbox only)
- `DELETE /messages/:id` - Delete/soft-delete message
- `POST /messages/:id/retry` - Retry failed message
- `POST /messages/:id/translate` - Translate message to target language

**Use Case:** Managing conversation messages, handling message content, and translation services.

---

### 4. [Contacts Controller](./contacts.md)
**Path:** `/api/v1/accounts/:account_id/contacts`
**Key Endpoints:**
- `GET /contacts` - List all contacts (with advanced sorting & filtering)
- `GET /contacts/active` - Get online contacts
- `GET /contacts/search` - Search contacts
- `POST /contacts/filter` - Advanced contact filtering
- `GET /contacts/:id` - View contact details
- `POST /contacts` - Create new contact
- `PATCH /contacts/:id` - Update contact information
- `DELETE /contacts/:id` - Delete contact
- `DELETE /contacts/:id/avatar` - Remove contact avatar
- `GET /contacts/:id/contactable_inboxes` - Get available channels
- `POST /contacts/:id/destroy_custom_attributes` - Remove custom fields
- `POST /contacts/import` - Bulk import from CSV
- `POST /contacts/export` - Bulk export to CSV

**Use Case:** Managing customer/contact records, profile information, and bulk operations.

---

### 5. [Inboxes Controller](./inboxes.md)
**Path:** `/api/v1/accounts/:account_id/inboxes`
**Key Endpoints:**
- `GET /inboxes` - List all inboxes
- `GET /inboxes/:id` - View inbox details
- `POST /inboxes` - Create new channel (web_widget, email, WhatsApp, API, etc.)
- `PATCH /inboxes/:id` - Update inbox settings
- `DELETE /inboxes/:id` - Delete inbox
- `DELETE /inboxes/:id/avatar` - Remove inbox avatar
- `GET /inboxes/:id/assignable_agents` - Get available agents (deprecated)
- `GET /inboxes/:id/campaigns` - List inbox campaigns
- `GET /inboxes/:id/agent_bot` - Get assigned chatbot
- `POST /inboxes/:id/set_agent_bot` - Assign/unassign chatbot
- `POST /inboxes/:id/sync_templates` - Sync WhatsApp templates
- `GET /inboxes/:id/health` - WhatsApp Cloud API health check

**Supported Channels:** web_widget, api, email, line, telegram, whatsapp, sms

**Use Case:** Managing communication channels, configuring multi-channel support, and channel-specific settings.

---

### 6. [Teams Controller](./teams.md)
**Path:** `/api/v1/accounts/:account_id/teams`
**Key Endpoints:**
- `GET /teams` - List all teams
- `GET /teams/:id` - View team details
- `POST /teams` - Create new team
- `PATCH /teams/:id` - Update team settings
- `DELETE /teams/:id` - Delete team
- `GET /teams/:id/team_members` - List team members
- `POST /teams/:id/team_members` - Add member to team
- `PATCH /teams/:id/team_members` - Update team membership
- `DELETE /teams/:id/team_members` - Remove members from team

**Use Case:** Organizing agents into teams/groups, assignment policies, and team-based workflows.

---

### 7. [Agents Controller](./agents.md)
**Path:** `/api/v1/accounts/:account_id/agents`
**Key Endpoints:**
- `GET /agents` - List all account agents
- `GET /agents/:id` - View agent details
- `POST /agents` - Create/invite new agent
- `PATCH /agents/:id` - Update agent information
- `DELETE /agents/:id` - Remove agent from account
- `POST /agents/bulk_create` - Bulk create agents from emails

**Use Case:** Managing support agents, roles, availability, and agent onboarding.

---

## 🔑 Key Features Documented

### For Each Endpoint:
✅ HTTP verb and full path
✅ URL parameters with descriptions
✅ Query/request parameters with types and defaults
✅ Real example requests and responses
✅ Error response examples with status codes
✅ Authorization requirements
✅ Validation rules
✅ Side effects and async behaviors
✅ Behavioral notes and gotchas

### Consistent Structure:
- **Overview** - Brief controller purpose
- **Endpoints** - Detailed endpoint documentation
- **Status/Type Values** - Enums and allowed values
- **Error Responses** - Standard HTTP error codes
- **Authentication** - Token format and headers
- **Authorization** - Pundit policy requirements
- **Rate Limiting** - Usage limits (if applicable)
- **Notes & Behaviors** - Important implementation details

---

## 🔐 Authentication

All API endpoints require authentication via:

```
Authorization: Bearer <access_token>
```

Or using Devise Token Auth headers:
```
access-token: <token>
client: <client_id>
expiry: <expiry>
uid: <uid>
```

---

## 📋 Common Response Formats

### Success (2xx)
```json
{
  "data": { /* resource(s) */ },
  "meta": { "count": 10, "current_page": 1 }
}
```

### Error (4xx/5xx)
```json
{
  "error": "Descriptive error message"
}
```

---

## 🎯 Quick Navigation

**By Function:**
- **User Management**: [Profile](./profile.md), [Agents](./agents.md)
- **Team Organization**: [Teams](./teams.md), [Contacts](./contacts.md)
- **Messaging**: [Conversations](./conversations.md), [Messages](./messages.md)
- **Channels**: [Inboxes](./inboxes.md)

**By HTTP Method:**
- **GET (Read)**: Index, Show, Search, Meta, Attachments
- **POST (Create)**: Create, Bulk Create, Actions
- **PATCH/PUT (Update)**: Update, Toggle, Set
- **DELETE (Remove)**: Destroy, Remove Avatar

**By Permission Level:**
- **Public**: Minimal (health checks)
- **User**: Profile endpoints
- **Agent**: Conversations, Messages, Teams
- **Admin**: Agents, Inboxes, Full CRUD

---

## 📝 Version Information

- **API Version**: v1 (all endpoints use `/api/v1/`)
- **Format**: JSON (application/json)
- **Last Updated**: February 23, 2026

---

## 🚀 Example Workflows

### 1. Create a Support Conversation
```
1. POST /inboxes - Create WhatsApp inbox
2. POST /contacts - Create customer contact
3. POST /conversations - Create conversation
4. POST /messages - Send initial message
5. POST /conversations/:id/toggle_status - Resolve
```

### 2. Onboard New Support Team
```
1. POST /teams - Create support team
2. POST /agents (multiple) - Add agents
3. POST /teams/:id/team_members - Add agents to team
4. PATCH /inboxes - Assign team to inbox
```

### 3. Customer Communication
```
1. GET /conversations/search - Find conversation
2. GET /messages - View message history
3. POST /messages - Send reply
4. POST /messages/:id/translate - Translate if needed
5. POST /conversations/:id/transcript - Email transcript
```

---

## 💡 Best Practices

1. **Pagination**: Always include `page` parameter for list endpoints
2. **Filtering**: Use `/filter` endpoints for complex queries
3. **Authorization**: Respect returned 403 errors; don't retry
4. **Rate Limiting**: Implement exponential backoff for retries
5. **Async Jobs**: Deletion/export operations are asynchronous
6. **Error Handling**: Always check `error` field in responses
7. **Custom Attributes**: Use for domain-specific data storage
8. **Team Organization**: Use teams for scalable assignment policies

---

## 📞 Support

For issues or questions about these APIs:
- Check the relevant controller markdown file
- Review the "Notes & Behaviors" section
- Refer to test files in `spec/requests/` for examples
