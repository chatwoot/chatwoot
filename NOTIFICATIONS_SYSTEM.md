# Chatwoot Notification System - Complete Technical Documentation

## Table of Contents
1. [Notification Creation Triggers](#1-notification-creation-triggers)
2. [Notification Model & Database](#2-notification-model--database)
3. [Notification Builder & Filtering](#3-notification-builder--filtering)
4. [Notification Settings & User Preferences](#4-notification-settings--user-preferences)
5. [Notification Delivery System](#5-notification-delivery-system)
6. [Action Cable (WebSocket) Real-Time Sync](#6-action-cable-websocket-real-time-sync)
7. [Frontend Notification System](#7-frontend-notification-system)
8. [Notification UI Components](#8-notification-ui-components)
9. [API Endpoints](#9-api-endpoints)
10. [Notification Finder & Filtering](#10-notification-finder--filtering)
11. [Complete Event Lifecycle Diagram](#11-complete-event-lifecycle-diagram)
12. [Who Sees Which Notifications](#12-who-sees-which-notifications)
13. [Key Files Summary](#13-key-files-summary)
14. [Performance Optimizations](#14-performance-optimizations)

---

## 1. Notification Creation Triggers

### Backend Flow - Event Listeners

Notifications are triggered through event listeners that listen to domain events.

**File: `app/listeners/notification_listener.rb`**

Key triggers:
- `conversation_created` - When a new conversation arrives in an inbox
- `conversation_bot_handoff` - When bot hands off to human agent
- `assignee_changed` - When a conversation is assigned to an agent
- `message_created` - When a message is sent (triggers mention and new message services)

### Specific Notification Types

#### 1. Conversation Creation
- **Trigger**: New conversation created
- **Recipients**: All inbox members (if subscribed)
- **Flow**: `NotificationListener` → `NotificationBuilder`
- **File**: `app/listeners/notification_listener.rb:21-29`

#### 2. Conversation Assignment
- **Trigger**: Assignee changes
- **Recipients**: Only the new assignee
- **File**: `app/listeners/notification_listener.rb:30-48`

#### 3. Message Notifications
- **Service**: `app/services/messages/new_message_notification_service.rb`
- **Recipients**:
  - **Assigned conversation assignee**: Gets `assigned_conversation_new_message`
  - **Participating users**: Get `participating_conversation_new_message`
- **Logic**: Prevents duplicate notifications by checking if already notified

#### 4. Mention Notifications
- **Service**: `app/services/messages/mention_service.rb`
- **Triggered for**:
  - User mentions: `(mention://user/ID/name)`
  - Team mentions: `(mention://team/ID/name)` - expands to all team members
- **Restriction**: Only valid for private messages
- **Notification type**: `conversation_mention`

#### 5. SLA Notifications (6 types)
- `sla_missed_first_response`
- `sla_missed_next_response`
- `sla_missed_resolution`

---

## 2. Notification Model & Database

**File: `app/models/notification.rb`**

### Database Schema

```ruby
notifications table:
  - id: bigint (primary key)
  - user_id: bigint (who receives the notification)
  - account_id: bigint (which account)
  - notification_type: integer (enum - see types below)
  - primary_actor_type: string (usually "Conversation")
  - primary_actor_id: bigint (conversation id)
  - secondary_actor_type: string (optional - usually "Message")
  - secondary_actor_id: bigint (optional - message id)
  - read_at: datetime (null = unread, set when marked read)
  - snoozed_until: datetime (for snoozing notifications)
  - meta: jsonb (metadata like last_snoozed_at)
  - created_at: datetime
  - updated_at: datetime
  - last_activity_at: datetime (tracks when notification was last active)
```

### Notification Types (8 total)

```ruby
enum notification_type: {
  conversation_creation: 1,
  conversation_assignment: 2,
  assigned_conversation_new_message: 3,
  conversation_mention: 4,
  participating_conversation_new_message: 5,
  sla_missed_first_response: 6,
  sla_missed_next_response: 7,
  sla_missed_resolution: 8
}
```

### Key Database Indexes

- **Performance index**: `idx_notifications_performance` on `(user_id, account_id, snoozed_until, read_at)`
- **Uniqueness**: Enforced on `(primary_actor_type, primary_actor_id)` per account to prevent duplicates

### Important Methods

```ruby
# Returns formatted data for push events
def push_event_data
  {
    id: id,
    notification_type: notification_type,
    primary_actor_type: primary_actor_type,
    primary_actor_id: primary_actor_id,
    primary_actor: primary_actor&.push_event_data,
    read_at: read_at,
    secondary_actor: secondary_actor&.push_event_data,
    user: user&.push_event_data,
    created_at: created_at.to_i,
    account_id: account_id,
    snoozed_until: snoozed_until,
    last_activity_at: last_activity_at.to_i
  }
end

# Marks notification as read
def mark_as_read
  update(read_at: DateTime.now.utc)
end

# Snoozes notification until a specific time
def snooze_until(snooze_until)
  update(snoozed_until: snooze_until)
end
```

---

## 3. Notification Builder & Filtering

**File: `app/builders/notification_builder.rb`**

The `NotificationBuilder` is the central gateway for creating notifications.

### Usage

```ruby
NotificationBuilder.new(
  notification_type: 'conversation_creation',
  user: agent,
  account: account,
  primary_actor: conversation,
  secondary_actor: message # optional
).perform
```

### Validation Checks Before Creation

1. **User subscription check**: Verifies user is subscribed to notification type via `NotificationSetting`
2. **Conversation type filter**: For `conversation_creation`, only creates if user subscribed
3. **Blocked contacts**: Skips notifications unless it's a mention
4. **Secondary actor**: Sets to `Current.user` if not provided

### Key Logic

```ruby
def perform
  return unless user_subscribed_to_notification?
  return if notification_already_exists?

  create_notification
end

private

def user_subscribed_to_notification?
  notification_setting = user.notification_settings.find_by(account: account)
  notification_setting&.public_send("push_#{notification_type}?")
end
```

---

## 4. Notification Settings & User Preferences

**File: `app/models/notification_setting.rb`**

Users can configure which notifications they receive through notification settings.

### Database Schema

```ruby
notification_settings table:
  - id: bigint (primary key)
  - user_id: bigint
  - account_id: bigint
  - email_flags: integer (bitfield for email preferences - 8 bits for 8 notification types)
  - push_flags: integer (bitfield for push preferences - 8 bits for 8 notification types)
  - created_at: datetime
  - updated_at: datetime
```

### Implementation Details

Uses `FlagShihTzu` gem for efficient bit-level flag management:

```ruby
has_flags 1 => :email_conversation_creation,
          2 => :email_conversation_assignment,
          3 => :email_assigned_conversation_new_message,
          4 => :email_conversation_mention,
          5 => :email_participating_conversation_new_message,
          # ... and so on
          column: 'email_flags'

has_flags 1 => :push_conversation_creation,
          2 => :push_conversation_assignment,
          # ... and so on
          column: 'push_flags'
```

### Methods Available

- `email_conversation_creation?` - Returns true if user wants email for conversation creation
- `push_conversation_creation?` - Returns true if user wants push for conversation creation
- Similar methods for all 8 notification types for both email and push

**Default**: All flags are enabled by default when NotificationSetting is created.

---

## 5. Notification Delivery System

### A. Database Delivery (Real-time sync)

After notification is created in DB, it dispatches events via callbacks:

**File: `app/models/notification.rb`**

```ruby
after_create_commit :process_notification_delivery, :dispatch_create_event
after_update_commit :dispatch_update_event
after_destroy_commit :dispatch_destroy_event
```

Events dispatched:
- `NOTIFICATION_CREATED`
- `NOTIFICATION_UPDATED`
- `NOTIFICATION_DELETED`

### B. Push Notifications

**File: `app/services/notification/push_notification_service.rb`**

After notification is created, it enqueues:

```ruby
Notification::PushNotificationJob.perform_later(self)
```

**Delivery channels:**
1. **Browser Push** - Web Push API with VAPID keys
2. **FCM (Firebase Cloud Messaging)** - Mobile push
3. **Chatwoot Hub** - Relay server if FCM not configured

**Logic flow:**
```ruby
def perform
  return unless user_subscribed_to_push?

  send_browser_push if browser_push_subscriptions.any?
  send_fcm_push if fcm_tokens.any?
  send_hub_push if hub_enabled? && no_other_channel_available?
end
```

### C. Email Notifications

**File: `app/jobs/notification/email_notification_job.rb`**

```ruby
Notification::EmailNotificationJob.perform_later(self)
```

**Respects**: User's email notification settings from `NotificationSetting`

---

## 6. Action Cable (WebSocket) Real-Time Sync

**File: `app/listeners/action_cable_listener.rb`**

The `ActionCableListener` bridges backend events to frontend WebSocket connections.

### Notification Created Flow

```ruby
def notification_created(event)
  notification, account, unread_count, count = extract_notification_and_account(event)
  tokens = [event.data[:notification].user.pubsub_token]

  broadcast(account, tokens, NOTIFICATION_CREATED, {
    notification: notification.push_event_data,
    unread_count: unread_count,
    count: count
  })
end
```

### Broadcast Mechanism

```ruby
def broadcast(account, tokens, event_name, data)
  tokens.each do |token|
    ActionCableBroadcastJob.perform_later(
      [token],
      event_name,
      data
    )
  end
end
```

**Key Points:**
- Each user has a unique `pubsub_token` (regenerated on password change)
- Broadcast includes: notification payload + updated unread_count + total count
- Uses job queue to avoid blocking

### RoomChannel Subscription

**File: `app/channels/room_channel.rb`**

```ruby
def subscribed
  ensure_stream
  current_user.update(pubsub_token: params[:pubsub_token])
end

private

def ensure_stream
  stream_from user&.pubsub_token
  stream_from current_account.pubsub_token
end
```

**Subscription process:**
1. User logs in
2. Frontend subscribes to RoomChannel with user's pubsub_token
3. User receives real-time updates for their notifications
4. Also receives account-level broadcasts

---

## 7. Frontend Notification System

### A. WebSocket Event Handling

**File: `app/javascript/dashboard/helper/actionCable.js`**

`ActionCableConnector` listens for notification events:

```javascript
events = {
  'notification.created': this.onNotificationCreated,
  'notification.deleted': this.onNotificationDeleted,
  'notification.updated': this.onNotificationUpdated,
  // ... other events
}

onNotificationCreated = data => {
  this.app.$store.dispatch('notifications/addNotification', data);
};

onNotificationUpdated = data => {
  this.app.$store.dispatch('notifications/updateNotification', data);
};

onNotificationDeleted = data => {
  this.app.$store.dispatch('notifications/deleteNotification', data);
};
```

### B. Vuex Store for Notifications

**File: `app/javascript/dashboard/store/modules/notifications/`**

#### State Structure

```javascript
state: {
  meta: {
    count: 0,           // Total notifications
    currentPage: 1,     // Current page number
    unreadCount: 0,     // Unread notification count
  },
  records: {},          // Notifications keyed by ID
  uiFlags: {
    isFetching: false,
    isUpdating: false,
    isDeleting: false,
    isUpdatingUnreadCount: false,
    isAllNotificationsLoaded: false,
  },
  notificationFilters: {}
}
```

#### Key Actions

```javascript
// Fetch notifications with pagination
get({ page = 1 }) {
  // GET /api/v1/accounts/{accountId}/notifications?page={page}
}

// Get unread count
unReadCount() {
  // GET /api/v1/accounts/{accountId}/notifications/unread_count
}

// Mark single notification as read
read({ id }) {
  // PATCH /api/v1/accounts/{accountId}/notifications/{id}
}

// Mark all notifications as read
readAll() {
  // POST /api/v1/accounts/{accountId}/notifications/read_all
}

// Delete notification
delete({ id }) {
  // DELETE /api/v1/accounts/{accountId}/notifications/{id}
}

// Add notification (from WebSocket)
addNotification({ notification, unread_count, count }) {
  // Updates state.records, state.meta.unreadCount, state.meta.count
}

// Update notification (from WebSocket)
updateNotification({ notification, unread_count, count }) {
  // Updates existing notification in state.records
}

// Delete notification (from WebSocket)
deleteNotification({ notification }) {
  // Removes from state.records
}

// Snooze notification
snooze({ id, snoozedUntil }) {
  // POST /api/v1/accounts/{accountId}/notifications/{id}/snooze
}
```

#### Mutations

```javascript
// Set notifications
SET_NOTIFICATIONS(state, data) {
  // Adds notifications to state.records
  // Updates state.meta
}

// Update unread count
SET_UNREAD_COUNT(state, count) {
  state.meta.unreadCount = count;
}

// Add single notification
ADD_NOTIFICATION(state, notification) {
  Vue.set(state.records, notification.id, notification);
}

// Update single notification
UPDATE_NOTIFICATION(state, notification) {
  if (state.records[notification.id]) {
    Vue.set(state.records, notification.id, notification);
  }
}

// Delete notification
DELETE_NOTIFICATION(state, notificationId) {
  Vue.delete(state.records, notificationId);
}

// Mark all as read
MARK_ALL_NOTIFICATIONS_AS_READ(state) {
  Object.values(state.records).forEach(notification => {
    Vue.set(notification, 'read_at', Math.floor(Date.now() / 1000));
  });
}
```

#### Getters

```javascript
// Get all notifications sorted by ID desc
getNotifications(state) {
  return Object.values(state.records).sort((a, b) => b.id - a.id);
}

// Get filtered notifications with sorting
getFilteredNotifications: (state) => (filters) => {
  // Filter by read_at, type, etc.
  // Sort by last_activity_at or created_at
}

// Get meta data
getMeta(state) {
  return state.meta;
}

// Get unread count
getUnreadCount(state) {
  return state.meta.unreadCount;
}

// Check if has unread notifications
getHasUnreadNotifications(state) {
  return state.meta.unreadCount > 0;
}
```

---

## 8. Notification UI Components

### A. Notification Badge (Bell Icon with Red Square)

**File: `app/javascript/dashboard/components-next/sidebar/SidebarNotificationBell.vue`**

This is the **red badge** component that shows notification count.

```vue
<script setup>
import { computed } from 'vue';

const notificationMetadata = useMapGetter('notifications/getMeta');

// Computed property for unread count display
const unreadCount = computed(() => {
  if (!notificationMetadata.value.unreadCount) return '';

  return notificationMetadata.value.unreadCount < 100
    ? `${notificationMetadata.value.unreadCount}`
    : '99+';
});
</script>

<template>
  <button @click="openNotificationPanel">
    <span class="i-lucide-bell" />
    <!-- RED BADGE WITH COUNT -->
    <span
      v-if="unreadCount"
      class="bg-n-ruby-9 rounded-lg text-white text-xs px-1"
    >
      {{ unreadCount }}
    </span>
  </button>
</template>
```

**Features:**
- Shows **red badge** (`bg-n-ruby-9`) with count when `unreadCount > 0`
- Shows "99+" for 100+ notifications
- Badge disappears when no unread notifications
- Clicking opens notification panel

**When does the red badge appear?**
- Immediately when `state.meta.unreadCount > 0`
- Updated via WebSocket in real-time when new notifications arrive
- Updated when marking notifications as read

**For whom does it appear?**
- Every logged-in user sees their own unread count
- Count is user-specific (not shared)

### B. Notifications Table/List View

**File: `app/javascript/dashboard/routes/dashboard/notifications/components/NotificationsView.vue`**

Main notification page component:

```vue
<script setup>
onMounted(() => {
  // Fetch first page of notifications
  dispatch('notifications/get', { page: 1 });
});

const handlePageChange = (page) => {
  dispatch('notifications/get', { page });
};

const markAllDone = () => {
  dispatch('notifications/readAll');
};
</script>

<template>
  <NotificationTable
    :notifications="notifications"
    @page-change="handlePageChange"
  />
  <button @click="markAllDone">Mark All Done</button>
</template>
```

**File: `app/javascript/dashboard/routes/dashboard/notifications/components/NotificationTable.vue`**

Table displaying notifications:

```vue
<template>
  <table>
    <thead>
      <tr>
        <th>Conversation</th>
        <th>Type</th>
        <th>Assignee</th>
        <th>Time</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
      <tr
        v-for="notification in notifications"
        :key="notification.id"
        :class="{ 'is-unread': !notification.read_at }"
        @click="openConversation(notification)"
      >
        <td>
          <!-- Blue dot for unread -->
          <span
            v-if="!notification.read_at"
            class="notification--unread-indicator"
          />
          <span :class="{ 'font-bold': !notification.read_at }">
            {{ notification.primary_actor.display_id }}
          </span>
        </td>
        <td>{{ getNotificationType(notification) }}</td>
        <td><Avatar :user="notification.primary_actor.assignee" /></td>
        <td>{{ dynamicTime(notification.created_at) }}</td>
        <td>
          <span v-if="!notification.read_at" class="badge-unread">
            Unread
          </span>
        </td>
      </tr>
    </tbody>
  </table>
</template>
```

**Visual indicators:**
- **Blue dot** (`.notification--unread-indicator`) - Shows if `read_at` is null
- **Bold text** - Row text is bold when unread
- **Row highlight** - Hover effect on rows
- **"Unread" badge** - Shows badge in status column

**Clicking a row:**
- Opens conversation: `/app/accounts/{accountId}/conversations/{conversationId}`
- Marks notification as read automatically

---

## 9. API Endpoints

**Controller: `app/controllers/api/v1/accounts/notifications_controller.rb`**

### GET /api/v1/accounts/{account_id}/notifications

Fetch paginated notifications.

**Parameters:**
- `page` (integer) - Page number (default: 1)
- `sort_order` (string) - Sort order (default: 'desc')
- `includes` (array) - Filters: 'read', 'snoozed'

**Response:**
```json
{
  "data": {
    "payload": [...notifications],
    "meta": {
      "count": 150,
      "current_page": 1,
      "unread_count": 25
    }
  }
}
```

### GET /api/v1/accounts/{account_id}/notifications/unread_count

Get unread notification count.

**Response:**
```json
{
  "unread_count": 25
}
```

### POST /api/v1/accounts/{account_id}/notifications/read_all

Mark all notifications as read.

**Parameters:**
- `primary_actor_type` (string, optional) - Filter by actor type
- `primary_actor_id` (integer, optional) - Filter by actor ID

**Response:**
```json
{
  "unread_count": 0
}
```

### PATCH /api/v1/accounts/{account_id}/notifications/{id}

Update notification (mark as read).

**Response:**
```json
{
  "notification": {...}
}
```

### DELETE /api/v1/accounts/{account_id}/notifications/{id}

Delete notification.

**Response:**
```json
{
  "success": true
}
```

### POST /api/v1/accounts/{account_id}/notifications/{id}/unread

Mark notification as unread.

**Response:**
```json
{
  "notification": {...}
}
```

### POST /api/v1/accounts/{account_id}/notifications/{id}/snooze

Snooze notification until specified time.

**Parameters:**
- `snoozed_until` (datetime) - ISO 8601 datetime string

**Response:**
```json
{
  "notification": {...}
}
```

### POST /api/v1/accounts/{account_id}/notifications/destroy_all

Bulk delete notifications.

**Parameters:**
- `type` (string) - 'read' or 'all'

**Response:**
```json
{
  "success": true
}
```

---

## 10. Notification Finder & Filtering

**File: `app/finders/notification_finder.rb`**

Handles query building and filtering for notifications.

### Filtering Logic

```ruby
def find_all_notifications
  @notifications = current_user.notifications
    .where(account_id: @current_account.id)
    .includes(:primary_actor, :secondary_actor)

  @notifications = apply_filters(@notifications)
  @notifications = apply_sort(@notifications)
  @notifications
end

private

def apply_filters(notifications)
  # 1. Filter by snoozed status
  notifications = filter_snoozed(notifications) unless @params[:includes].include?('snoozed')

  # 2. Filter by read status
  notifications = filter_read(notifications) unless @params[:includes].include?('read')

  notifications
end

def filter_snoozed(notifications)
  notifications.where('snoozed_until IS NULL OR snoozed_until < ?', Time.current)
end

def filter_read(notifications)
  notifications.where(read_at: nil)
end

def apply_sort(notifications)
  notifications.order(last_activity_at: @params[:sort_order] || :desc)
end
```

### Pagination

- **Page size**: 15 notifications per page
- **Sorted by**: `last_activity_at` (desc by default)

### Usage in Controller

```ruby
def index
  @notifications = NotificationFinder.new(current_user, current_account, params).find_all_notifications

  @notifications = @notifications.page(params[:page]).per(15)

  render json: {
    data: {
      payload: @notifications,
      meta: {
        count: @notifications.total_count,
        current_page: params[:page],
        unread_count: current_user.notifications.where(account_id: current_account.id, read_at: nil).count
      }
    }
  }
end
```

---

## 11. Complete Event Lifecycle Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 1: BACKEND EVENT TRIGGERS                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ Trigger: conversation_created event                             │
│    └─> NotificationListener.conversation_created               │
│        └─> NotificationBuilder.perform                          │
│            ├─> Check: user subscribed? (NotificationSetting)   │
│            ├─> Check: notification already exists?             │
│            └─> Create Notification record in DB                │
│                                                                  │
│ Trigger: message_created event                                  │
│    └─> NewMessageNotificationService.perform                   │
│        ├─> Notify assignee (if assigned)                       │
│        └─> Notify participating users                          │
│            └─> NotificationBuilder.perform for each            │
│                └─> Create Notification records in DB           │
│                                                                  │
│ Trigger: @mention in message                                    │
│    └─> Messages::MentionService.perform                        │
│        ├─> Extract mentioned user/team IDs                     │
│        └─> For each mentioned user:                            │
│            └─> NotificationBuilder.perform                     │
│                └─> Create Notification record                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
           │
           │ (Notification saved to DB)
           ▼
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 2: AFTER_CREATE_COMMIT CALLBACKS                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ Notification.after_create_commit do                             │
│   ├─> process_notification_delivery                            │
│   │   ├─> Enqueue PushNotificationJob (if subscribed)         │
│   │   │   └─> Send browser/FCM/hub push                       │
│   │   └─> Enqueue EmailNotificationJob (if subscribed)        │
│   │       └─> Send email notification                         │
│   │                                                             │
│   └─> dispatch_create_event                                    │
│       └─> Rails.configuration.dispatcher.dispatch(             │
│             NOTIFICATION_CREATED,                              │
│             timestamp: Time.zone.now,                          │
│             data: { notification: self }                       │
│           )                                                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
           │
           │ (NOTIFICATION_CREATED event published)
           ▼
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 3: ACTION CABLE LISTENER                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ ActionCableListener.notification_created(event)                │
│    ├─> Extract notification from event.data                    │
│    ├─> Calculate unread_count for user                         │
│    ├─> Calculate total count for user                          │
│    ├─> Get user.pubsub_token                                   │
│    └─> Call broadcast(                                         │
│          account: account,                                     │
│          tokens: [user.pubsub_token],                          │
│          event_name: 'notification.created',                   │
│          data: {                                               │
│            notification: notification.push_event_data,         │
│            unread_count: unread_count,                         │
│            count: count                                        │
│          }                                                      │
│        )                                                        │
│        └─> ActionCableBroadcastJob.perform_later(              │
│              [user.pubsub_token],                              │
│              'notification.created',                           │
│              payload                                           │
│            )                                                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
           │
           │ (WebSocket message sent to client)
           ▼
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 4: FRONTEND WEBSOCKET RECEIVER                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ User's browser connected to RoomChannel via pubsub_token        │
│    │                                                             │
│    └─> Receives: 'notification.created' event                  │
│        └─> ActionCableConnector.onNotificationCreated(data)    │
│            └─> this.app.$store.dispatch(                       │
│                  'notifications/addNotification',              │
│                  {                                             │
│                    notification: data.notification,            │
│                    unread_count: data.unread_count,            │
│                    count: data.count                           │
│                  }                                             │
│                )                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 5: VUEX STORE UPDATE                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ Action: notifications/addNotification                           │
│    ├─> Commit: ADD_NOTIFICATION                                │
│    │   └─> state.records[notification.id] = notification       │
│    ├─> Commit: SET_UNREAD_COUNT                                │
│    │   └─> state.meta.unreadCount = unread_count               │
│    └─> Commit: UPDATE_COUNT                                    │
│        └─> state.meta.count = count                            │
│                                                                  │
│ Getters automatically react to state changes:                   │
│    ├─> getMeta() → returns updated meta                        │
│    ├─> getUnreadCount() → returns updated unreadCount          │
│    └─> getNotifications() → returns updated notifications list │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 6: UI REACTIVE UPDATES                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ Component: SidebarNotificationBell.vue                          │
│    ├─> unreadCount computed property updates                   │
│    │   (watches notifications/getMeta getter)                  │
│    │                                                             │
│    └─> Template re-renders:                                    │
│        └─> RED BADGE appears/updates with new count            │
│            - Shows badge if unreadCount > 0                    │
│            - Shows "99+" if unreadCount >= 100                 │
│            - Badge has red background (bg-n-ruby-9)            │
│                                                                  │
│ Component: NotificationTable.vue (if viewing notifications)     │
│    ├─> notifications computed property updates                 │
│    │   (watches notifications/getNotifications getter)         │
│    │                                                             │
│    └─> Table re-renders:                                       │
│        ├─> New row prepended to top                            │
│        ├─> Row styled with bold text (is-unread class)        │
│        ├─> Blue dot indicator visible                          │
│        └─> Row animates into view                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

USER SEES: Red badge with notification count appears instantly!
```

---

## 12. Who Sees Which Notifications

### Access Control

**User-scoped queries** (enforced by `NotificationFinder`):

```ruby
current_user.notifications.where(account_id: current_account.id)
```

- Users **only see their own notifications**
- Scoped to **current account** they're viewing
- Cannot see other users' notifications

### Notification Type Recipients

| Notification Type | Who Receives It |
|------------------|-----------------|
| `conversation_creation` | All inbox members who are subscribed |
| `conversation_assignment` | Only the newly assigned agent |
| `assigned_conversation_new_message` | Only the conversation assignee |
| `participating_conversation_new_message` | Users who participated in conversation (not sender) |
| `conversation_mention` | Only mentioned users (or all team members if team mention) |
| `sla_missed_*` | SLA owner/assignee |

### Visibility Filters

**Read Status:**
- `read_at = null` → Notification is **unread** (shows in default list)
- `read_at != null` → Notification is **read** (hidden unless `includes: ['read']`)

**Snoozed Status:**
- `snoozed_until = null` → Not snoozed (shows in list)
- `snoozed_until > now` → Currently snoozed (hidden unless `includes: ['snoozed']`)
- `snoozed_until <= now` → Snooze expired (shows in list again)

**Pagination:**
- Only 15 notifications per page
- Must navigate to see more

---

## 13. Key Files Summary

| File Path | Purpose |
|-----------|---------|
| **Backend - Models** |
| `app/models/notification.rb` | Core notification model with lifecycle callbacks |
| `app/models/notification_setting.rb` | User notification preferences (bitflags) |
| **Backend - Builders** |
| `app/builders/notification_builder.rb` | Creates notifications with validation |
| **Backend - Services** |
| `app/services/messages/new_message_notification_service.rb` | Creates message notifications |
| `app/services/messages/mention_service.rb` | Creates mention notifications |
| `app/services/notification/push_notification_service.rb` | Sends browser/FCM/hub push |
| **Backend - Listeners** |
| `app/listeners/notification_listener.rb` | Event listener for conversation events |
| `app/listeners/action_cable_listener.rb` | WebSocket broadcast dispatcher |
| **Backend - Controllers** |
| `app/controllers/api/v1/accounts/notifications_controller.rb` | API endpoints |
| **Backend - Finders** |
| `app/finders/notification_finder.rb` | Query builder with filters |
| **Backend - Jobs** |
| `app/jobs/notification/push_notification_job.rb` | Push notification queue |
| `app/jobs/notification/email_notification_job.rb` | Email notification queue |
| `app/jobs/action_cable_broadcast_job.rb` | WebSocket broadcast queue |
| **Backend - Channels** |
| `app/channels/room_channel.rb` | ActionCable room subscription |
| **Frontend - Store** |
| `app/javascript/dashboard/store/modules/notifications/actions.js` | Vuex actions |
| `app/javascript/dashboard/store/modules/notifications/getters.js` | Vuex getters |
| `app/javascript/dashboard/store/modules/notifications/mutations.js` | Vuex mutations |
| `app/javascript/dashboard/store/modules/notifications/index.js` | Vuex module entry |
| **Frontend - Helpers** |
| `app/javascript/dashboard/helper/actionCable.js` | WebSocket event handler |
| **Frontend - Components** |
| `app/javascript/dashboard/components-next/sidebar/SidebarNotificationBell.vue` | Bell icon with red badge |
| `app/javascript/dashboard/routes/dashboard/notifications/components/NotificationsView.vue` | Main notifications page |
| `app/javascript/dashboard/routes/dashboard/notifications/components/NotificationTable.vue` | Notifications table/list |

---

## 14. Performance Optimizations

### Database Level

**Indexes:**
```sql
-- Performance index for common queries
CREATE INDEX idx_notifications_performance
ON notifications (user_id, account_id, snoozed_until, read_at);

-- Uniqueness to prevent duplicate notifications
CREATE UNIQUE INDEX index_notifications_on_primary_actor
ON notifications (account_id, user_id, primary_actor_type, primary_actor_id);
```

**Batch Operations:**
```ruby
# Mark all as read - uses single UPDATE query
Notification.where(user_id: user.id, read_at: nil)
            .update_all(read_at: Time.current)
```

**Includes (N+1 Prevention):**
```ruby
@notifications = current_user.notifications
  .includes(:primary_actor, :secondary_actor)
  .where(account_id: current_account.id)
```

### Backend Level

**Job Queues:**
- Push notifications are queued via `PushNotificationJob`
- Email notifications are queued via `EmailNotificationJob`
- ActionCable broadcasts are queued via `ActionCableBroadcastJob`
- Prevents blocking main request thread

**Event-Driven Architecture:**
- Uses Rails event dispatcher for loose coupling
- Listeners react to events asynchronously

### Frontend Level

**Real-time Updates:**
- Uses WebSocket (no polling)
- Instant notification delivery
- Reduced server load

**State Management:**
- Vuex store caches notifications
- Computed properties for reactive updates
- Minimal re-renders

**Lazy Loading:**
- Only fetches first 15 notifications on page load
- Pagination for additional notifications
- Reduces initial payload size

**Optimistic Updates:**
- Marks as read immediately in UI
- Background API call to persist
- Better user experience

### Notification Deduplication

**Unique Index:**
- Prevents duplicate notifications for same conversation
- `(account_id, user_id, primary_actor_type, primary_actor_id)` must be unique

**Builder Check:**
```ruby
def notification_already_exists?
  Notification.exists?(
    user: user,
    account: account,
    primary_actor: primary_actor
  )
end
```

---

## Summary

The Chatwoot notification system is a comprehensive real-time notification delivery system:

1. **Backend**: Event-driven architecture with Rails events, listeners, and job queues
2. **Database**: Efficient schema with proper indexing and deduplication
3. **Delivery**: Multiple channels (WebSocket, push, email) with user preferences
4. **Frontend**: Reactive Vuex store with WebSocket integration
5. **UI**: Red badge on bell icon showing unread count, detailed table view
6. **Performance**: Optimized with indexes, job queues, and real-time updates

The **red square notification badge** appears instantly when:
- New conversation is created (for inbox members)
- Message is received in assigned/participating conversation
- User is mentioned in a message
- SLA is missed

It updates in **real-time** via WebSocket and shows the **unread count** for the logged-in user.
