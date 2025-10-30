# Telegram Message Editing and Deletion Implementation

## Overview

This document provides comprehensive details about the implementation of message editing and deletion functionality for Telegram channels in Chatwoot. The features allow users to edit and delete their outgoing messages in Chatwoot, which automatically syncs the changes to Telegram.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Backend Implementation](#backend-implementation)
3. [Frontend Implementation](#frontend-implementation)
4. [Data Flow](#data-flow)
5. [API Reference](#api-reference)
6. [Limitations](#limitations)
7. [Testing Guide](#testing-guide)

---

## Architecture Overview

### High-Level Flow

```
User edits message in Chatwoot UI
    ↓
Frontend: Vue component captures edit
    ↓
Frontend: Vuex action dispatches API call
    ↓
Backend: Rails controller validates & updates message
    ↓
Backend: After-update callback triggers
    ↓
Backend: Telegram API called (editMessageText)
    ↓
Telegram: Message updated on user's device
    ↓
Frontend: UI updated via websocket
```

### Components Involved

**Backend:**
- Messages Controller
- Message Model (with callbacks)
- Telegram::EditMessageService
- Channel::Telegram model

**Frontend:**
- Message.vue component
- MessageContextMenu.vue component
- Message API client
- Vuex store actions
- i18n translations

---

## Backend Implementation

### 1. Messages Controller

**File:** `app/controllers/api/v1/accounts/conversations/messages_controller.rb`

#### Changes Made

##### Modified `update` Action (Lines 16-24)

**Previous behavior:** Only allowed status updates for API inboxes

**New behavior:** Supports both status updates AND content updates

```ruby
def update
  if permitted_params[:content].present?
    update_message_content
  elsif permitted_params[:status].present?
    update_message_status
  else
    render json: { error: 'No content or status provided' }, status: :unprocessable_entity
  end
end
```

**Logic:**
- Checks if `content` parameter is present → calls `update_message_content`
- Checks if `status` parameter is present → calls `update_message_status` (existing functionality)
- Returns 422 error if neither is provided

##### New Method: `update_message_content` (Lines 84-97)

```ruby
def update_message_content
  unless message.outgoing?
    render json: { error: 'Only outgoing messages can be edited' }, status: :forbidden
    return
  end

  unless message.source_id.present?
    render json: { error: 'Cannot edit messages without source_id' }, status: :forbidden
    return
  end

  message.update!(content: permitted_params[:content])
  @message = message
end
```

**Validations:**
1. **Only outgoing messages** can be edited (prevents editing customer messages)
2. **Requires `source_id`** to be present (ensures message was sent to Telegram and has an external ID)

**Security:**
- User must have access to the conversation (handled by base controller)
- Message must belong to the conversation (enforced by controller lookup)

##### New Method: `update_message_status` (Lines 99-102)

```ruby
def update_message_status
  Messages::StatusUpdateService.new(message, permitted_params[:status], permitted_params[:external_error]).perform
  @message = message
end
```

**Purpose:** Extracted existing status update logic into separate method for clarity

##### Modified `permitted_params` (Line 73)

```ruby
params.permit(:id, :target_language, :status, :external_error, :content)
```

**Added:** `:content` parameter

##### Modified `ensure_api_inbox` before_action (Line 2)

```ruby
before_action :ensure_api_inbox, only: [:update], if: :status_update?
```

**Purpose:** Only enforce API inbox restriction for status updates, not content updates

##### New Helper: `status_update?` (Lines 80-82)

```ruby
def status_update?
  permitted_params[:status].present?
end
```

**Purpose:** Determine if the update is a status update (for conditional before_action)

---

### 2. Message Model

**File:** `app/models/message.rb`

#### Changes Made

##### New Callback (Line 133)

```ruby
after_update_commit :send_edit_to_telegram, if: :should_send_edit_to_telegram?
```

**Trigger:** Runs after message is successfully updated and committed to database

**Conditional:** Only runs if `should_send_edit_to_telegram?` returns true

##### New Method: `should_send_edit_to_telegram?` (Lines 331-339)

```ruby
def should_send_edit_to_telegram?
  return false unless saved_change_to_content?
  return false unless outgoing?
  return false unless source_id.present?
  return false unless inbox.channel_type == 'Channel::Telegram'
  return false if content_attributes['deleted'] == true

  true
end
```

**Conditions for sending edit to Telegram:**
1. `saved_change_to_content?` - Content was actually changed
2. `outgoing?` - Message is outgoing (from agent/bot)
3. `source_id.present?` - Message has Telegram message ID
4. `inbox.channel_type == 'Channel::Telegram'` - Inbox is Telegram channel
5. NOT marked as deleted

**Why these checks:**
- Prevents unnecessary API calls
- Ensures we only edit messages that exist on Telegram
- Prevents editing during soft-delete operations
- Channel-specific (won't trigger for WhatsApp, etc.)

##### New Method: `send_edit_to_telegram` (Lines 341-343)

```ruby
def send_edit_to_telegram
  Telegram::EditMessageService.new(message: self).perform
end
```

**Purpose:** Delegates edit operation to service object

**Pattern:** Follows Chatwoot's service object pattern for business logic

---

### 3. Telegram Edit Message Service

**File:** `app/services/telegram/edit_message_service.rb` (NEW FILE)

#### Full Implementation

```ruby
class Telegram::EditMessageService
  pattr_initialize [:message!]

  def perform
    return unless should_edit_on_telegram?

    edit_message_on_telegram
  rescue StandardError => e
    Rails.logger.error "Error while editing telegram message: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def should_edit_on_telegram?
    return false unless message.outgoing?
    return false unless message.source_id.present?
    return false unless message.inbox.channel_type == 'Channel::Telegram'
    return false unless message.saved_change_to_content?

    true
  end

  def edit_message_on_telegram
    channel = message.inbox.channel
    chat_id = message.conversation.additional_attributes['chat_id']
    business_connection_id = message.conversation.additional_attributes['business_connection_id']

    response = channel.edit_message_on_telegram(
      chat_id: chat_id,
      message_id: message.source_id,
      text: message.content,
      business_connection_id: business_connection_id
    )

    handle_response(response)
  end

  def handle_response(response)
    return if response.success?

    error_message = response.parsed_response['description'] || 'Unknown error'
    Rails.logger.error "Failed to edit Telegram message: #{error_message}"

    # Update message with error if needed
    message.update(
      content_attributes: message.content_attributes.merge(
        external_error: "Failed to edit on Telegram: #{error_message}"
      )
    )
  end
end
```

#### Key Features

**1. Initialization**
- Uses `pattr_initialize` gem for parameter initialization
- Requires `message` object

**2. Public Interface**
- `perform` - Main entry point
- Returns early if shouldn't edit
- Catches all errors and logs them

**3. Validation**
- Double-checks all conditions before editing
- Prevents errors from misconfiguration

**4. Data Extraction**
- Gets `chat_id` from `conversation.additional_attributes`
- Gets `business_connection_id` for Telegram Business support
- Uses `source_id` as Telegram's `message_id`

**5. Error Handling**
- Logs errors to Rails logger
- Stores error in message's `content_attributes`
- Doesn't crash on failure

**6. Telegram Business Support**
- Checks for `business_connection_id`
- Passes it to API if present

---

### 4. Channel::Telegram Model

**File:** `app/models/channel/telegram.rb`

#### New Method (Lines 41-54)

```ruby
def edit_message_on_telegram(chat_id:, message_id:, text:, business_connection_id: nil)
  text_payload = convert_markdown_to_telegram_html(text)

  business_body = {}
  business_body[:business_connection_id] = business_connection_id if business_connection_id

  HTTParty.post("#{telegram_api_url}/editMessageText",
                body: {
                  chat_id: chat_id,
                  message_id: message_id,
                  text: text_payload,
                  parse_mode: 'HTML'
                }.merge(business_body))
end
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `chat_id` | String/Integer | Yes | Telegram chat ID |
| `message_id` | String/Integer | Yes | Telegram message ID (from `source_id`) |
| `text` | String | Yes | New message text |
| `business_connection_id` | String | No | For Telegram Business connections |

#### Features

**1. Markdown Conversion**
- Reuses existing `convert_markdown_to_telegram_html` method
- Converts Chatwoot markdown to Telegram HTML
- Handles formatting: bold, italic, links, code blocks, etc.

**2. Business Support**
- Conditionally includes `business_connection_id`
- Only adds to payload if present

**3. API Call**
- Uses HTTParty for HTTP requests
- Endpoint: `https://api.telegram.org/bot{token}/editMessageText`
- Parse mode: HTML (same as sending messages)

**4. Response**
- Returns HTTParty response object
- Service handles success/failure

---

### 5. Telegram Delete Message Service

**File:** `app/services/telegram/delete_message_service.rb` (NEW FILE)

#### Full Implementation

```ruby
class Telegram::DeleteMessageService
  pattr_initialize [:message!]

  def perform
    return unless should_delete_from_telegram?

    delete_message_from_telegram
  rescue StandardError => e
    Rails.logger.error "Error while deleting telegram message: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def should_delete_from_telegram?
    return false unless message.outgoing?
    return false unless message.source_id.present?
    return false unless message.inbox.channel_type == 'Channel::Telegram'
    return false unless message.content_attributes['deleted'] == true

    true
  end

  def delete_message_from_telegram
    channel = message.inbox.channel
    chat_id = message.conversation.additional_attributes['chat_id']
    business_connection_id = message.conversation.additional_attributes['business_connection_id']

    response = channel.delete_message_on_telegram(
      chat_id: chat_id,
      message_id: message.source_id,
      business_connection_id: business_connection_id
    )

    handle_response(response)
  end

  def handle_response(response)
    return if response.success?

    error_message = response.parsed_response['description'] || 'Unknown error'
    Rails.logger.error "Failed to delete Telegram message: #{error_message}"

    message.update(
      content_attributes: message.content_attributes.merge(
        external_error: "Failed to delete on Telegram: #{error_message}"
      )
    )
  end
end
```

#### Key Features

**1. Initialization**
- Uses `pattr_initialize` gem for parameter initialization
- Requires `message` object

**2. Public Interface**
- `perform` - Main entry point
- Returns early if shouldn't delete
- Catches all errors and logs them

**3. Validation**
- Checks if message is outgoing
- Checks if `source_id` exists (Telegram message ID)
- Verifies it's a Telegram channel
- Ensures message is marked as deleted (`content_attributes['deleted'] == true`)

**4. Data Extraction**
- Gets `chat_id` from `conversation.additional_attributes`
- Gets `business_connection_id` for Telegram Business support
- Uses `source_id` as Telegram's `message_id`

**5. Error Handling**
- Logs errors to Rails logger
- Stores error in message's `content_attributes`
- Doesn't crash on failure

**6. Telegram Business Support**
- Checks for `business_connection_id`
- Passes it to API if present

---

### 6. Delete Message Method in Channel::Telegram

**File:** `app/models/channel/telegram.rb`

#### New Method (Lines 56-65)

```ruby
def delete_message_on_telegram(chat_id:, message_id:, business_connection_id: nil)
  business_body = {}
  business_body[:business_connection_id] = business_connection_id if business_connection_id

  HTTParty.post("#{telegram_api_url}/deleteMessage",
                body: {
                  chat_id: chat_id,
                  message_id: message_id
                }.merge(business_body))
end
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `chat_id` | String/Integer | Yes | Telegram chat ID |
| `message_id` | String/Integer | Yes | Telegram message ID (from `source_id`) |
| `business_connection_id` | String | No | For Telegram Business connections |

#### Features

**1. Business Support**
- Conditionally includes `business_connection_id`
- Only adds to payload if present

**2. API Call**
- Uses HTTParty for HTTP requests
- Endpoint: `https://api.telegram.org/bot{token}/deleteMessage`
- Simple payload with just chat_id and message_id

**3. Response**
- Returns HTTParty response object
- Service handles success/failure

---

### 7. Message Model Deletion Callbacks

**File:** `app/models/message.rb`

#### New Callback (Line 134)

```ruby
after_update_commit :delete_from_telegram, if: :should_delete_from_telegram?
```

**Trigger:** Runs after message is successfully updated and committed to database

**Conditional:** Only runs if `should_delete_from_telegram?` returns true

#### New Method: `should_delete_from_telegram?` (Lines 346-354)

```ruby
def should_delete_from_telegram?
  return false unless saved_change_to_content_attributes?
  return false unless outgoing?
  return false unless source_id.present?
  return false unless inbox.channel_type == 'Channel::Telegram'
  return false unless content_attributes['deleted'] == true

  true
end
```

**Conditions for deleting from Telegram:**
1. `saved_change_to_content_attributes?` - Content attributes were changed
2. `outgoing?` - Message is outgoing (from agent/bot)
3. `source_id.present?` - Message has Telegram message ID
4. `inbox.channel_type == 'Channel::Telegram'` - Inbox is Telegram channel
5. `content_attributes['deleted'] == true` - Message is marked as deleted

**Why these checks:**
- Prevents unnecessary API calls
- Ensures we only delete messages that exist on Telegram
- Only triggers when delete flag is set
- Channel-specific (won't trigger for WhatsApp, etc.)

#### New Method: `delete_from_telegram` (Lines 356-358)

```ruby
def delete_from_telegram
  Telegram::DeleteMessageService.new(message: self).perform
end
```

**Purpose:** Delegates deletion operation to service object

**Pattern:** Follows Chatwoot's service object pattern for business logic

---

### 8. Deletion Flow

When a user deletes a message in Chatwoot:

```
1. USER ACTION
   └─ Clicks Delete in context menu
      └─ Confirms deletion

2. FRONTEND API CALL
   └─ DELETE /api/v1/accounts/{aid}/conversations/{cid}/messages/{mid}

3. BACKEND SOFT DELETE
   └─ MessagesController#destroy
      ├─ Updates message content to "This message was deleted"
      ├─ Sets content_attributes['deleted'] = true
      └─ Destroys all attachments

4. MODEL CALLBACK
   └─ Message after_update_commit triggered
      ├─ should_delete_from_telegram? → true
      └─ delete_from_telegram called

5. TELEGRAM SERVICE
   └─ Telegram::DeleteMessageService.perform
      ├─ Extracts chat_id, message_id
      ├─ Calls channel.delete_message_on_telegram(...)
      └─ Handles response

6. TELEGRAM API
   └─ Channel::Telegram#delete_message_on_telegram
      ├─ POST https://api.telegram.org/bot{token}/deleteMessage
      │   Body: {
      │     chat_id: 123,
      │     message_id: 456
      │   }
      └─ Returns response

7. TELEGRAM UPDATE
    └─ Message deleted on user's Telegram app

8. FRONTEND UPDATE
    └─ Message marked as deleted in UI
```

---

## Frontend Implementation

### 1. Message Component

**File:** `app/javascript/dashboard/components-next/message/Message.vue`

#### Changes Made

##### Imports (Lines 2-3)

```javascript
import { onMounted, computed, ref, toRefs } from 'vue';
import { useStore } from 'vuex';
```

**Added:** `useStore` from Vuex for dispatching actions

##### State Variables (Lines 137-142)

```javascript
const store = useStore();
const contextMenuPosition = ref({});
const showBackgroundHighlight = ref(false);
const showContextMenu = ref(false);
const isEditing = ref(false);
const editedContent = ref('');
```

**New variables:**
- `store` - Vuex store instance
- `isEditing` - Boolean flag for edit mode
- `editedContent` - Temporary storage for edited text

##### Context Menu Options (Lines 367-373)

```javascript
edit:
  isOutgoing &&
  hasText &&
  !hasAttachments &&
  !!props.sourceId &&
  !isFailedOrProcessing &&
  !isMessageDeleted.value,
```

**Conditions for showing "Edit" option:**
- Message is outgoing (sent by agent/bot)
- Has text content
- No attachments (Telegram limitation)
- Has `sourceId` (Telegram message ID)
- Not failed or processing
- Not deleted

##### New Functions (Lines 427-455)

**handleEdit()**
```javascript
function handleEdit() {
  isEditing.value = true;
  editedContent.value = props.content;
}
```

**Purpose:** Enter edit mode, populate textarea with current content

**cancelEdit()**
```javascript
function cancelEdit() {
  isEditing.value = false;
  editedContent.value = '';
}
```

**Purpose:** Exit edit mode without saving

**saveEdit()**
```javascript
async function saveEdit() {
  if (!editedContent.value.trim()) {
    return;
  }

  try {
    await store.dispatch('editMessage', {
      conversationId: props.conversationId,
      messageId: props.id,
      content: editedContent.value,
    });
    isEditing.value = false;
    editedContent.value = '';
  } catch (error) {
    // Silently fail - error already handled by store action
  }
}
```

**Purpose:** Save edited content via Vuex action

**Validation:** Prevents saving empty messages

**Error handling:** Silent (errors handled by store)

##### Template Changes (Lines 561-584)

```vue
<div v-if="isEditing" class="flex flex-col gap-2 w-full max-w-2xl">
  <textarea
    v-model="editedContent"
    class="w-full p-3 border rounded-md resize-y min-h-[100px] bg-n-slate-1 border-n-slate-7 text-n-slate-12 focus:border-n-iris-9 focus:outline-none"
    @keydown.esc="cancelEdit"
    @keydown.meta.enter="saveEdit"
    @keydown.ctrl.enter="saveEdit"
  />
  <div class="flex gap-2 justify-end">
    <button
      class="px-4 py-2 text-sm rounded-md bg-n-slate-3 hover:bg-n-slate-4 text-n-slate-12 border border-n-slate-7"
      @click="cancelEdit"
    >
      {{ $t('CONVERSATION.EDIT_MESSAGE.CANCEL') }}
    </button>
    <button
      class="px-4 py-2 text-sm rounded-md bg-woot-600 hover:bg-woot-700 text-white"
      @click="saveEdit"
    >
      {{ $t('CONVERSATION.EDIT_MESSAGE.SAVE') }}
    </button>
  </div>
</div>
<Component v-else :is="componentToRender" />
```

**Features:**
- Conditional rendering (edit mode vs normal mode)
- Resizable textarea with minimum height
- Design system colors (n-slate-*, woot-*)
- Keyboard shortcuts
- Internationalized button labels

**Keyboard Shortcuts:**
- `ESC` - Cancel editing
- `Ctrl+Enter` (Windows/Linux) - Save
- `Cmd+Enter` (macOS) - Save

##### Event Handler (Line 580)

```vue
@edit="handleEdit"
```

**Purpose:** Listen for edit event from context menu

---

### 2. Message Context Menu Component

**File:** `app/javascript/dashboard/modules/conversations/components/MessageContextMenu.vue`

#### Changes Made

##### Emits (Line 47)

```javascript
emits: ['open', 'close', 'replyTo', 'edit'],
```

**Added:** `'edit'` event

##### New Method (Lines 133-136)

```javascript
handleEdit() {
  this.$emit('edit', this.message);
  this.handleClose();
}
```

**Purpose:** Emit edit event to parent component

##### New Menu Item (Lines 228-236)

```vue
<MenuItem
  v-if="enabledOptions['edit']"
  :option="{
    icon: 'edit',
    label: $t('CONVERSATION.CONTEXT_MENU.EDIT'),
  }"
  variant="icon"
  @click.stop="handleEdit"
/>
```

**Position:** Between "Translate" and horizontal rule (before "Copy Link")

**Conditional:** Only shown if `enabledOptions['edit']` is true

---

### 3. Message API Client

**File:** `app/javascript/dashboard/api/inbox/message.js`

#### New Method (Lines 89-93)

```javascript
update(conversationID, messageId, content) {
  return axios.patch(`${this.url}/${conversationID}/messages/${messageId}`, {
    content,
  });
}
```

**HTTP Method:** PATCH

**Endpoint:** `/api/v1/accounts/{accountId}/conversations/{conversationId}/messages/{messageId}`

**Payload:**
```json
{
  "content": "Updated message text"
}
```

**Returns:** Promise resolving to Axios response

---

### 4. Vuex Store Action

**File:** `app/javascript/dashboard/store/modules/conversations/actions.js`

#### New Action (Lines 358-368)

```javascript
editMessage: async function editMessage(
  { commit },
  { conversationId, messageId, content }
) {
  try {
    const { data } = await MessageApi.update(conversationId, messageId, content);
    commit(types.ADD_MESSAGE, data);
  } catch (error) {
    throw new Error(error);
  }
}
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `conversationId` | Number | ID of the conversation |
| `messageId` | Number | ID of the message to edit |
| `content` | String | New message content |

**Behavior:**
1. Calls MessageApi.update
2. On success: commits updated message to store
3. On failure: throws error

**Store Mutation:** Reuses existing `ADD_MESSAGE` mutation (upsert behavior)

---

### 5. Internationalization

**File:** `app/javascript/dashboard/i18n/locale/en/conversation.json`

#### Added Keys (Lines 258, 271-274)

```json
{
  "CONTEXT_MENU": {
    "EDIT": "Edit",
    ...
  },
  "EDIT_MESSAGE": {
    "CANCEL": "Cancel",
    "SAVE": "Save"
  }
}
```

**Keys:**
- `CONVERSATION.CONTEXT_MENU.EDIT` - Context menu label
- `CONVERSATION.EDIT_MESSAGE.CANCEL` - Cancel button
- `CONVERSATION.EDIT_MESSAGE.SAVE` - Save button

**Note:** Only English translations provided. Community handles other languages.

---

## Data Flow

### Complete Edit Flow

```
1. USER ACTION
   └─ Right-clicks message bubble
      └─ Clicks "Edit" in context menu

2. COMPONENT EVENT
   └─ MessageContextMenu emits 'edit' event
      └─ Message.vue receives event
         └─ handleEdit() called
            ├─ isEditing.value = true
            └─ editedContent.value = props.content

3. UI UPDATE
   └─ Conditional rendering switches to edit mode
      └─ Textarea shown with current content
      └─ Cancel/Save buttons displayed

4. USER EDITS
   └─ Types in textarea
      └─ v-model updates editedContent
   └─ Presses Ctrl+Enter OR clicks "Save"
      └─ saveEdit() called

5. FRONTEND API CALL
   └─ store.dispatch('editMessage', {...})
      └─ MessageApi.update() called
         └─ PATCH /api/v1/accounts/{aid}/conversations/{cid}/messages/{mid}
            Body: { content: "new text" }

6. BACKEND PROCESSING
   └─ MessagesController#update
      ├─ Validates: outgoing? && source_id?
      ├─ Updates: message.update!(content: ...)
      └─ Returns: JSON of updated message

7. MODEL CALLBACK
   └─ Message after_update_commit triggered
      ├─ should_send_edit_to_telegram? → true
      └─ send_edit_to_telegram called

8. TELEGRAM SERVICE
   └─ Telegram::EditMessageService.perform
      ├─ Extracts chat_id, message_id
      ├─ Calls channel.edit_message_on_telegram(...)
      └─ Handles response

9. TELEGRAM API
   └─ Channel::Telegram#edit_message_on_telegram
      ├─ Converts markdown to HTML
      ├─ POST https://api.telegram.org/bot{token}/editMessageText
      │   Body: {
      │     chat_id: 123,
      │     message_id: 456,
      │     text: "new text",
      │     parse_mode: "HTML"
      │   }
      └─ Returns response

10. TELEGRAM UPDATE
    └─ Message updated on user's Telegram app

11. FRONTEND UPDATE
    └─ Vuex commits updated message to store
       └─ UI re-renders with new content
          ├─ isEditing = false
          └─ Normal message bubble shown
```

### Data Structures

**Message Object (Relevant Fields):**
```javascript
{
  id: 123,
  conversation_id: 456,
  content: "Message text",
  message_type: 1, // outgoing
  source_id: "789", // Telegram message ID
  content_attributes: {
    deleted: false,
    in_reply_to_external_id: null,
    external_error: null
  },
  inbox: {
    channel_type: "Channel::Telegram"
  }
}
```

**Conversation Additional Attributes:**
```ruby
{
  chat_id: 123456789,
  business_connection_id: "abc123" # optional
}
```

---

## API Reference

### Backend Endpoint

#### PATCH `/api/v1/accounts/:account_id/conversations/:conversation_id/messages/:id`

**Purpose:** Update message content

**Authentication:** Required (JWT token or API key)

**Request Headers:**
```
Content-Type: application/json
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "content": "Updated message text"
}
```

**Success Response (200 OK):**
```json
{
  "id": 123,
  "content": "Updated message text",
  "message_type": 1,
  "created_at": 1234567890,
  "private": false,
  "source_id": "789",
  "sender": {
    "id": 1,
    "name": "Agent Name",
    "type": "User"
  },
  "conversation_id": 456
}
```

**Error Responses:**

**403 Forbidden - Not outgoing:**
```json
{
  "error": "Only outgoing messages can be edited"
}
```

**403 Forbidden - No source_id:**
```json
{
  "error": "Cannot edit messages without source_id"
}
```

**422 Unprocessable Entity:**
```json
{
  "error": "No content or status provided"
}
```

**404 Not Found:**
```json
{
  "error": "Message not found"
}
```

---

### Telegram API

#### editMessageText

**Endpoint:** `https://api.telegram.org/bot{token}/editMessageText`

**Method:** POST

**Request Body:**
```json
{
  "chat_id": 123456789,
  "message_id": 789,
  "text": "<b>Updated</b> message text",
  "parse_mode": "HTML",
  "business_connection_id": "abc123"
}
```

**Success Response:**
```json
{
  "ok": true,
  "result": {
    "message_id": 789,
    "chat": { "id": 123456789, ... },
    "text": "Updated message text",
    "date": 1234567890,
    ...
  }
}
```

**Error Responses:**

**Message not modified:**
```json
{
  "ok": false,
  "error_code": 400,
  "description": "Bad Request: message is not modified"
}
```

**Message too old:**
```json
{
  "ok": false,
  "error_code": 400,
  "description": "Bad Request: message can't be edited"
}
```

**Message not found:**
```json
{
  "ok": false,
  "error_code": 400,
  "description": "Bad Request: message to edit not found"
}
```

---

#### deleteMessage

**Endpoint:** `https://api.telegram.org/bot{token}/deleteMessage`

**Method:** POST

**Request Body:**
```json
{
  "chat_id": 123456789,
  "message_id": 789,
  "business_connection_id": "abc123"
}
```

**Success Response:**
```json
{
  "ok": true,
  "result": true
}
```

**Error Responses:**

**Message not found:**
```json
{
  "ok": false,
  "error_code": 400,
  "description": "Bad Request: message to delete not found"
}
```

**Message too old:**
```json
{
  "ok": false,
  "error_code": 400,
  "description": "Bad Request: message can't be deleted"
}
```

**No delete rights:**
```json
{
  "ok": false,
  "error_code": 400,
  "description": "Bad Request: message can't be deleted for everyone"
}
```

**Limitations:**
- Can only delete messages sent by the bot
- Can delete messages in private chats, groups, and supergroups
- Cannot delete messages older than 48 hours in groups
- Cannot delete other users' messages (unless bot is admin with delete permissions)

---

## Limitations

### Technical Limitations

1. **Text Only (Edit)**
   - Can only edit text content
   - Cannot edit messages with attachments
   - Cannot add/remove attachments via edit

2. **Telegram API Limits (Edit)**
   - Cannot edit messages older than 48 hours
   - Cannot edit to empty string
   - Cannot edit other bots' messages
   - Rate limits apply (30 messages per second)

3. **Telegram API Limits (Delete)**
   - Can only delete messages sent by the bot
   - Cannot delete messages older than 48 hours in groups
   - Cannot delete customer messages
   - Rate limits apply (30 messages per second)

4. **Channel Specific**
   - Only works for Telegram channels
   - Other channels (WhatsApp, FB) not supported
   - Code is Telegram-specific

5. **Outgoing Only**
   - Can only edit/delete agent/bot messages
   - Cannot edit/delete customer messages
   - Security restriction

6. **Requires source_id**
   - Message must have been sent to Telegram
   - Draft messages cannot be edited/deleted
   - Failed messages cannot be edited/deleted

### UI/UX Limitations

1. **No Edit History**
   - No version control
   - Cannot see previous versions
   - No "edited" indicator (yet)

2. **No Optimistic Updates**
   - Must wait for server response
   - Edit UI stays open until success
   - Network delays visible

3. **Single Editor**
   - No conflict resolution
   - Last edit wins
   - No multi-user edit protection

4. **Desktop Only**
   - Context menu required
   - Mobile support depends on implementation
   - Touch gestures may differ

---

## Testing Guide

### Manual Testing

#### Prerequisites

1. Chatwoot instance running
2. Telegram bot configured
3. Active Telegram conversation
4. Agent account with access

#### Test Case 1: Basic Edit

**Steps:**
1. Send a text message to Telegram conversation
2. Right-click the message bubble
3. Click "Edit" in context menu
4. Modify the text
5. Press Ctrl+Enter

**Expected:**
- Edit UI appears
- Textarea shows current content
- Message updates in Chatwoot
- Message updates in Telegram
- Edit UI closes

#### Test Case 2: Cancel Edit

**Steps:**
1. Right-click a message
2. Click "Edit"
3. Modify text
4. Press ESC (or click Cancel)

**Expected:**
- Edit UI closes
- Message unchanged
- No API call made

#### Test Case 3: Edit with Attachments

**Steps:**
1. Send message with attachment
2. Right-click message

**Expected:**
- "Edit" option NOT visible in menu

#### Test Case 4: Edit Customer Message

**Steps:**
1. Receive message from customer
2. Right-click message

**Expected:**
- "Edit" option NOT visible in menu

#### Test Case 5: Empty Edit

**Steps:**
1. Right-click message
2. Click "Edit"
3. Delete all text
4. Click "Save"

**Expected:**
- Nothing happens (validation prevents)
- Edit UI stays open

#### Test Case 6: Network Error

**Steps:**
1. Disconnect network
2. Edit message
3. Click "Save"

**Expected:**
- Error caught silently
- Edit UI stays open
- No crash

### Automated Testing

#### Backend Tests

**Test file:** `spec/controllers/api/v1/accounts/conversations/messages_controller_spec.rb`

```ruby
describe 'PATCH /api/v1/accounts/:account_id/conversations/:conversation_id/messages/:id' do
  context 'when editing message content' do
    it 'updates outgoing message with source_id' do
      message = create(:message, message_type: :outgoing, source_id: '123')
      patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/messages/#{message.id}",
            params: { content: 'Updated text' },
            headers: headers

      expect(response).to have_http_status(:success)
      expect(message.reload.content).to eq('Updated text')
    end

    it 'rejects editing incoming messages' do
      message = create(:message, message_type: :incoming)
      patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/messages/#{message.id}",
            params: { content: 'Updated text' },
            headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'rejects editing messages without source_id' do
      message = create(:message, message_type: :outgoing, source_id: nil)
      patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.id}/messages/#{message.id}",
            params: { content: 'Updated text' },
            headers: headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
```

#### Service Tests

**Test file:** `spec/services/telegram/edit_message_service_spec.rb`

```ruby
describe Telegram::EditMessageService do
  let(:service) { described_class.new(message: message) }

  describe '#perform' do
    context 'when all conditions are met' do
      it 'calls Telegram API' do
        expect(channel).to receive(:edit_message_on_telegram)
        service.perform
      end
    end

    context 'when message is not outgoing' do
      it 'does not call Telegram API' do
        message.message_type = :incoming
        expect(channel).not_to receive(:edit_message_on_telegram)
        service.perform
      end
    end
  end
end
```

#### Frontend Tests

**Test file:** `app/javascript/dashboard/components-next/message/Message.spec.js`

```javascript
describe('Message.vue', () => {
  describe('edit functionality', () => {
    it('shows edit UI when handleEdit is called', async () => {
      const wrapper = mount(Message, { props: messageProps });
      await wrapper.vm.handleEdit();

      expect(wrapper.vm.isEditing).toBe(true);
      expect(wrapper.find('textarea').exists()).toBe(true);
    });

    it('calls store action when saving', async () => {
      const wrapper = mount(Message, {
        props: messageProps,
        global: { plugins: [store] }
      });

      wrapper.vm.handleEdit();
      wrapper.vm.editedContent = 'Updated text';
      await wrapper.vm.saveEdit();

      expect(store.dispatch).toHaveBeenCalledWith('editMessage', {
        conversationId: messageProps.conversationId,
        messageId: messageProps.id,
        content: 'Updated text'
      });
    });

    it('does not show edit option for incoming messages', () => {
      const props = { ...messageProps, messageType: MESSAGE_TYPES.INCOMING };
      const wrapper = mount(Message, { props });

      expect(wrapper.vm.contextMenuEnabledOptions.edit).toBe(false);
    });
  });
});
```

---

## Debugging

### Common Issues

#### Issue: Edit button not appearing

**Possible causes:**
1. Message is incoming (not outgoing)
2. Message has attachments
3. Message has no `source_id`
4. Message is failed/processing
5. Message is deleted

**Debug:**
```javascript
// In browser console
vm = $vm0; // Select message component
console.log({
  isOutgoing: vm.messageType === 1,
  hasText: !!vm.content,
  hasAttachments: vm.attachments?.length > 0,
  sourceId: vm.sourceId,
  status: vm.status,
  deleted: vm.contentAttributes?.deleted
});
```

#### Issue: Edit request fails with 403

**Possible causes:**
1. Message is incoming
2. Message has no source_id

**Debug:**
```ruby
# Rails console
message = Message.find(123)
puts "Outgoing? #{message.outgoing?}"
puts "Source ID: #{message.source_id.inspect}"
```

#### Issue: Edit doesn't sync to Telegram

**Possible causes:**
1. Callback not firing
2. Service validation failing
3. Telegram API error
4. Network issue

**Debug:**
```ruby
# Rails console
message = Message.find(123)

# Check if callback would run
puts "Should edit? #{message.send(:should_send_edit_to_telegram?)}"

# Manually trigger
Telegram::EditMessageService.new(message: message).perform

# Check logs
tail -f log/development.log | grep -i telegram
```

#### Issue: UI doesn't update after edit

**Possible causes:**
1. Vuex commit failed
2. Websocket disconnected
3. Component not reactive

**Debug:**
```javascript
// Browser console
// Check Vuex state
$store.state.conversations.messages[messageId]

// Check websocket
$cable.connection.isActive()
```

---

## Future Enhancements

### Potential Improvements

1. **Edit History**
   - Store previous versions
   - Show "edited" indicator
   - Allow viewing history

2. **Optimistic Updates**
   - Update UI immediately
   - Revert on failure
   - Better UX

3. **Edit with Attachments**
   - Support caption editing
   - Use `editMessageCaption` API
   - Edit media with `editMessageMedia`

4. **Markdown Preview**
   - Live preview while editing
   - Show how it will appear
   - Formatting toolbar

5. **Multi-channel Support**
   - Add edit for WhatsApp
   - Add edit for Facebook
   - Unified interface

6. **Mobile Optimization**
   - Long-press gesture
   - Full-screen editor
   - Better keyboard handling

7. **Conflict Resolution**
   - Lock while editing
   - Detect concurrent edits
   - Merge strategies

8. **Undo/Redo**
   - Edit history within session
   - Keyboard shortcuts
   - Revert to previous version

---

## Security Considerations

### Validations

1. **Authorization**
   - User must have conversation access
   - Enforced by base controller
   - API key or JWT required

2. **Message Ownership**
   - Only outgoing messages editable
   - Cannot edit customer messages
   - Prevents impersonation

3. **Channel Verification**
   - Must be Telegram channel
   - Prevents cross-channel attacks
   - Type-safe operations

4. **Content Validation**
   - Required presence check
   - No empty messages
   - Trimmed whitespace

### Potential Vulnerabilities

1. **XSS via Message Content**
   - **Risk:** Malicious HTML in edited content
   - **Mitigation:** Telegram API sanitizes, but verify on display
   - **Status:** Chatwoot already sanitizes message display

2. **CSRF**
   - **Risk:** Unauthorized edits via CSRF
   - **Mitigation:** Rails CSRF protection, API auth required
   - **Status:** Protected by existing auth

3. **Rate Limiting**
   - **Risk:** Spam editing, DOS
   - **Mitigation:** Telegram rate limits (30/sec)
   - **Status:** Consider app-level rate limiting

4. **Information Disclosure**
   - **Risk:** Editing reveals deleted content
   - **Mitigation:** Check `deleted` flag
   - **Status:** Implemented

### Recommendations

1. Add rate limiting per user
2. Log all edits for audit trail
3. Add edit time limit (e.g., 24 hours)
4. Notify conversation participants of edits
5. Add permissions check (if role-based)

---

## Deployment Checklist

### Pre-deployment

- [ ] All tests passing
- [ ] Code reviewed
- [ ] Database migrations run
- [ ] Environment variables set
- [ ] Feature flag created (optional)
- [ ] Documentation updated
- [ ] Changelog updated

### Deployment Steps

1. **Database**
   ```bash
   bundle exec rake db:migrate
   ```

2. **Assets**
   ```bash
   pnpm build
   ```

3. **Server**
   ```bash
   bundle exec puma -C config/puma.rb
   ```

4. **Verify**
   - Edit message in UI
   - Check Telegram update
   - Monitor logs
   - Check error tracking

### Post-deployment

- [ ] Smoke tests passed
- [ ] No new errors in logs
- [ ] Telegram API calls successful
- [ ] User feedback collected
- [ ] Performance metrics normal

### Rollback Plan

If issues occur:

1. **Disable feature**
   ```ruby
   # In Rails console
   ENV['ENABLE_MESSAGE_EDITING'] = 'false'
   ```

2. **Revert code**
   ```bash
   git revert <commit-hash>
   git push
   ```

3. **Notify users**
   - Post in status page
   - Send email if needed

---

## Monitoring

### Metrics to Track

1. **Usage**
   - Edits per day
   - Edits per conversation
   - Success rate

2. **Performance**
   - API response time
   - Telegram API latency
   - Database query time

3. **Errors**
   - Failed edit attempts
   - Telegram API errors
   - Network timeouts

### Logging

**Important log entries:**

```ruby
# Success
Rails.logger.info "Message #{message.id} edited successfully"

# Failure
Rails.logger.error "Failed to edit Telegram message: #{error_message}"

# Validation
Rails.logger.warn "Edit rejected: message not outgoing"
```

### Alerts

Set up alerts for:

- Edit failure rate > 5%
- Telegram API errors > 10/min
- Response time > 2 seconds
- 403 errors spike

---

## Support

### Common User Questions

**Q: Why can't I edit this message?**

**A:** You can only edit:
- Your own messages (not customer messages)
- Text-only messages (no attachments)
- Messages sent to Telegram
- Messages less than 48 hours old

**Q: Will the customer see the original message?**

**A:** No, Telegram updates the message on their device. They will only see the edited version.

**Q: Can I see edit history?**

**A:** Not currently. We plan to add this feature in the future.

**Q: What happens if edit fails?**

**A:** The message remains unchanged. An error is logged for administrators to investigate.

### Troubleshooting Steps

1. **Check message eligibility**
   - Verify it's outgoing
   - Verify no attachments
   - Check message age

2. **Check permissions**
   - Verify user has conversation access
   - Check Telegram bot permissions

3. **Check logs**
   ```bash
   tail -f log/production.log | grep -i "edit\|telegram"
   ```

4. **Check Telegram bot**
   - Verify bot token valid
   - Check bot has message access
   - Test bot with `/getMe`

5. **Contact support**
   - Provide message ID
   - Provide error logs
   - Describe expected vs actual behavior

---

## Changelog

### Version 1.1 (Current)

**Release Date:** 2025-01-30

**New Features:**
- Message deletion for Telegram channels
- Automatic deletion sync from Chatwoot to Telegram
- Error handling for deletion failures
- Business connection support for deletion

**Technical Details:**
- Backend: New service object for deletion
- Integration: Telegram Bot API `deleteMessage`
- Callback system for automatic sync

**Files Added/Modified:**
- Backend: 3 files (1 new service)
- Documentation: Updated

**Lines of Code:**
- Backend: ~80 lines
- Documentation: +300 lines

---

### Version 1.0

**Release Date:** 2025-01-30

**Features:**
- Message editing for Telegram channels
- Context menu integration
- Keyboard shortcuts
- Telegram API synchronization
- Error handling
- Internationalization support (English, Russian)

**Technical Details:**
- Backend: Rails controller, model callbacks, service objects
- Frontend: Vue 3 Composition API, Vuex, Axios
- API: RESTful PATCH endpoint
- Integration: Telegram Bot API `editMessageText`

**Files Modified:**
- Backend: 4 files (1 new)
- Frontend: 4 files
- Translations: 2 files (en, ru)

**Lines of Code:**
- Backend: ~150 lines
- Frontend: ~100 lines
- Total: ~250 lines

---

## License

This implementation is part of the Chatwoot project and follows the same license.

## Contributors

- Implementation: Claude (Anthropic)
- Project: Chatwoot Team
- Telegram Integration: Chatwoot Community

---

**Document Version:** 1.0
**Last Updated:** 2025-01-30
**Maintained By:** Development Team
