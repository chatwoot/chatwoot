# Feature Plan: Sidebar New Messages Count (v2 - Improved)

## Overview

Add the count of conversations with at least one new unseen message to the sidebar navigation for:
- **Conversations tabs** (All, Mine, Unassigned)
- **Channels/Inboxes** (each channel shows its own count)
- **Labels** (each label shows its own count)

A message is considered "unseen" if it was created after `agent_last_seen_at` timestamp.

---

## Key Design Decisions (Improvements from v1)

| Issue | v1 Approach | v2 Improved Approach |
|-------|-------------|---------------------|
| Performance | JOIN messages table on every request | Add `has_unread_messages` boolean column to conversations |
| Real-time updates | Frontend polling via API | Push updates via ActionCable from backend |
| Store module | Create new `conversationUnreadCounts` module | Extend existing `conversationStats` module |
| Permission scoping | Not detailed | Reuse `Conversations::PermissionFilterService` |
| Label complexity | Not addressed | Handle multi-label conversations properly |

---

## Current Architecture Summary

### How Unread Messages Are Tracked
- **Backend**: `Conversation#agent_last_seen_at` stores when an agent last viewed
- **Backend**: `Conversation#unread_incoming_messages` returns messages since `agent_last_seen_at`
- **Frontend**: Each conversation object contains `unread_count` property

### Existing Real-time Infrastructure
- **ActionCable events** (`app/javascript/dashboard/helper/actionCable.js`):
  - `message.created` → triggers stats refresh via `fetch_conversation_stats` event
  - `conversation.read` → updates conversation in store
  - `assignee.changed`, `conversation.status_changed` → trigger stats refresh

### Existing Permission Scoping
- **OSS**: `Conversations::PermissionFilterService` filters by inbox membership
- **Enterprise**: `Enterprise::Conversations::PermissionFilterService` adds custom role permissions:
  - `conversation_manage` → all accessible conversations
  - `conversation_unassigned_manage` → unassigned + own conversations
  - `conversation_participating_manage` → only assigned conversations

### Existing Stats Module
- **File**: `app/javascript/dashboard/store/modules/conversationStats.js`
- **State**: `mineCount`, `unAssignedCount`, `allCount`
- **Pattern**: Debounced API calls based on conversation volume

---

## Implementation Plan

### Phase 1: Database Schema Changes

#### 1.1 Add `has_unread_messages` Column to Conversations

**File**: `db/migrate/xxx_add_has_unread_messages_to_conversations.rb`

```ruby
class AddHasUnreadMessagesToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :has_unread_messages, :boolean, default: false, null: false
    add_index :conversations, [:account_id, :has_unread_messages],
              where: 'has_unread_messages = true',
              name: 'index_conversations_on_account_has_unread'
    add_index :conversations, [:inbox_id, :has_unread_messages],
              where: 'has_unread_messages = true',
              name: 'index_conversations_on_inbox_has_unread'
  end
end
```

#### 1.2 Backfill Existing Data

**File**: `db/migrate/xxx_backfill_has_unread_messages.rb`

```ruby
class BackfillHasUnreadMessages < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # Backfill in batches to avoid locking
    Conversation.where(status: [:open, :pending]).in_batches(of: 1000) do |batch|
      batch.each do |conversation|
        has_unread = conversation.messages
          .where(message_type: :incoming, private: false)
          .where('created_at > COALESCE(?, created_at - interval \'1 second\')',
                 conversation.agent_last_seen_at)
          .exists?
        conversation.update_column(:has_unread_messages, has_unread)
      end
    end
  end

  def down
    # No rollback needed - column will be dropped
  end
end
```

---

### Phase 2: Backend Model & Callback Changes

#### 2.1 Add Callback to Update `has_unread_messages` on Message Creation

**File**: `app/models/message.rb`

Add after-commit callback:

```ruby
after_commit :update_conversation_unread_status, on: :create

private

def update_conversation_unread_status
  return unless incoming? && !private?

  conversation.update_column(:has_unread_messages, true)
end
```

#### 2.2 Add Method to Clear Unread Status When Conversation is Read

**File**: `app/models/conversation.rb`

Update the method that marks conversation as read:

```ruby
def mark_as_read!(agent_last_seen_at_time = Time.current)
  update!(agent_last_seen_at: agent_last_seen_at_time, has_unread_messages: false)
end
```

Also add a scope for unread conversations:

```ruby
scope :with_unread_messages, -> { where(has_unread_messages: true) }
```

#### 2.3 Handle Edge Cases

**File**: `app/models/conversation.rb`

```ruby
# When conversation is snoozed/resolved, we may want to keep or clear unread status
# Decision: Keep unread status - user should see count when reopened

# When labels change, no action needed - count will reflect current labels

# When conversation is deleted, ActiveRecord callbacks handle cleanup
```

---

### Phase 3: Backend Service for Unread Counts

#### 3.1 Create `ConversationUnreadCountService`

**File**: `app/services/conversation_unread_count_service.rb`

```ruby
class ConversationUnreadCountService
  attr_reader :account, :user

  def initialize(account:, user:)
    @account = account
    @user = user
  end

  def perform
    {
      by_inbox: unread_by_inbox,
      by_label: unread_by_label,
      by_status: unread_by_status,
      total: total_unread_count
    }
  end

  private

  def base_conversations
    # Reuse existing permission filter service for proper scoping
    conversations = account.conversations.with_unread_messages.where(status: [:open, :pending])
    Conversations::PermissionFilterService.new(conversations, user, account).perform
  end

  def unread_by_inbox
    base_conversations.group(:inbox_id).count
  end

  def unread_by_label
    # Handle multi-label conversations correctly
    # Each conversation counted once per label it has
    base_conversations
      .joins(:taggings)
      .joins('INNER JOIN tags ON tags.id = taggings.tag_id')
      .group('tags.name')
      .count
  end

  def unread_by_status
    conversations = base_conversations
    {
      all: conversations.count,
      mine: conversations.assigned_to(user).count,
      unassigned: conversations.unassigned.count
    }
  end

  def total_unread_count
    base_conversations.count
  end
end

# Prepend enterprise module if exists
ConversationUnreadCountService.prepend_mod_with('ConversationUnreadCountService')
```

#### 3.2 Add API Endpoint

**File**: `app/controllers/api/v1/accounts/conversations_controller.rb`

Add new action:

```ruby
def unread_counts
  @unread_counts = ConversationUnreadCountService.new(
    account: Current.account,
    user: Current.user
  ).perform
end
```

**File**: `config/routes.rb`

Add route in conversations collection:

```ruby
resources :conversations, only: [...] do
  collection do
    get :meta
    get :search
    get :filter
    get :unread_counts  # New endpoint
  end
end
```

#### 3.3 Create JSON View

**File**: `app/views/api/v1/accounts/conversations/unread_counts.json.jbuilder`

```ruby
json.by_inbox @unread_counts[:by_inbox]
json.by_label @unread_counts[:by_label]
json.by_status do
  json.all @unread_counts[:by_status][:all]
  json.mine @unread_counts[:by_status][:mine]
  json.unassigned @unread_counts[:by_status][:unassigned]
end
json.total @unread_counts[:total]
```

---

### Phase 4: ActionCable Real-time Updates

#### 4.1 Broadcast Unread Count Changes

**File**: `app/models/message.rb`

Extend the callback to broadcast:

```ruby
after_commit :broadcast_unread_count_update, on: :create

private

def broadcast_unread_count_update
  return unless incoming? && !private?

  # Broadcast to all agents in this account
  Rails.configuration.dispatcher.dispatch(
    CONVERSATION_UNREAD_COUNT_CHANGED,
    Time.zone.now,
    conversation: conversation,
    account: conversation.account
  )
end
```

#### 4.2 Create New ActionCable Event

**File**: `app/listeners/action_cable_listener.rb`

Add handler for unread count changes:

```ruby
def conversation_unread_count_changed(event)
  conversation = event.data[:conversation]
  account = event.data[:account]

  # Broadcast to account channel
  ActionCableBroadcastJob.perform_later(
    account.pubsub_token,
    'conversation.unread_count_changed',
    {
      inbox_id: conversation.inbox_id,
      labels: conversation.cached_label_list&.split(',') || [],
      assignee_id: conversation.assignee_id
    }
  )
end
```

#### 4.3 Handle Event in Frontend

**File**: `app/javascript/dashboard/helper/actionCable.js`

Add new event handler:

```javascript
// In events object
'conversation.unread_count_changed': this.onUnreadCountChanged,

// New method
onUnreadCountChanged = data => {
  // Debounced refresh of unread counts
  this.debouncedRefreshUnreadCounts();
};

debouncedRefreshUnreadCounts = debounce(() => {
  emitter.emit('fetch_unread_counts');
}, 1000);
```

---

### Phase 5: Frontend Store Changes (Extend `conversationStats`)

#### 5.1 Update Store State

**File**: `app/javascript/dashboard/store/modules/conversationStats.js`

```javascript
const state = {
  mineCount: 0,
  unAssignedCount: 0,
  allCount: 0,
  // New: Unread counts
  unreadCounts: {
    byInbox: {},      // { inboxId: count }
    byLabel: {},      // { labelName: count }
    byStatus: {
      all: 0,
      mine: 0,
      unassigned: 0,
    },
    total: 0,
  },
};
```

#### 5.2 Add Getters

```javascript
export const getters = {
  getStats: $state => $state,
  // New getters
  getUnreadCountForInbox: $state => inboxId =>
    $state.unreadCounts.byInbox[inboxId] || 0,
  getUnreadCountForLabel: $state => labelName =>
    $state.unreadCounts.byLabel[labelName] || 0,
  getUnreadCountAll: $state => $state.unreadCounts.byStatus.all,
  getUnreadCountMine: $state => $state.unreadCounts.byStatus.mine,
  getUnreadCountUnassigned: $state => $state.unreadCounts.byStatus.unassigned,
  getTotalUnreadCount: $state => $state.unreadCounts.total,
};
```

#### 5.3 Add Actions

```javascript
export const actions = {
  get: async ({ commit, state: $state }, params) => {
    // Existing debounced fetch...
  },

  // New action for unread counts
  fetchUnreadCounts: async ({ commit }) => {
    try {
      const response = await ConversationApi.getUnreadCounts();
      commit(types.SET_UNREAD_COUNTS, response.data);
    } catch (error) {
      // Silently fail - counts are non-critical
    }
  },
};
```

#### 5.4 Add Mutations

```javascript
export const mutations = {
  [types.SET_CONV_TAB_META](...) { /* existing */ },

  [types.SET_UNREAD_COUNTS]($state, payload) {
    $state.unreadCounts = {
      byInbox: payload.by_inbox || {},
      byLabel: payload.by_label || {},
      byStatus: payload.by_status || { all: 0, mine: 0, unassigned: 0 },
      total: payload.total || 0,
    };
  },
};
```

#### 5.5 Add Mutation Type

**File**: `app/javascript/dashboard/store/mutation-types.js`

```javascript
export default {
  // ... existing
  SET_UNREAD_COUNTS: 'SET_UNREAD_COUNTS',
};
```

#### 5.6 Add API Method

**File**: `app/javascript/dashboard/api/inbox/conversation.js`

```javascript
getUnreadCounts() {
  return axios.get(`${this.url}/unread_counts`);
}
```

---

### Phase 6: Sidebar Component Updates

#### 6.1 Fetch Unread Counts on Mount

**File**: `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`

```javascript
import { emitter } from 'shared/helpers/mitt';

onMounted(() => {
  // Existing dispatches...
  store.dispatch('conversationStats/fetchUnreadCounts');

  // Listen for real-time updates
  emitter.on('fetch_unread_counts', () => {
    store.dispatch('conversationStats/fetchUnreadCounts');
  });
});

onUnmounted(() => {
  emitter.off('fetch_unread_counts');
});
```

#### 6.2 Update Conversation Tab Items

**File**: `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`

Update conversation menu items to use the new getters:

```javascript
// All conversations
{
  name: 'All',
  label: t('SIDEBAR.ALL_CONVERSATIONS'),
  // ... existing props
  getterKeys: {
    count: 'conversationStats/getUnreadCountAll',
  },
}

// Mine
{
  name: 'Mine',
  label: t('SIDEBAR.MINE'),
  getterKeys: {
    count: 'conversationStats/getUnreadCountMine',
  },
}

// Unassigned
{
  name: 'Unassigned',
  label: t('SIDEBAR.UNASSIGNED'),
  getterKeys: {
    count: 'conversationStats/getUnreadCountUnassigned',
  },
}
```

#### 6.3 Update `ChannelLeaf.vue` for Per-Inbox Count

**File**: `app/javascript/dashboard/components-next/sidebar/ChannelLeaf.vue`

```vue
<script setup>
import { computed } from 'vue';
import { useStore } from 'dashboard/composables/store';

const props = defineProps({
  inbox: { type: Object, required: true },
  label: { type: String, default: '' },
  active: { type: Boolean, default: false },
});

const store = useStore();

const unreadCount = computed(() =>
  store.getters['conversationStats/getUnreadCountForInbox'](props.inbox.id)
);

const displayCount = computed(() =>
  unreadCount.value > 99 ? '99+' : unreadCount.value
);
</script>

<template>
  <div class="flex items-center justify-between">
    <!-- Existing inbox name and icon -->
    <span v-if="unreadCount > 0" class="...badge-styles...">
      {{ displayCount }}
    </span>
  </div>
</template>
```

#### 6.4 Create `LabelLeaf.vue` for Per-Label Count

**File**: `app/javascript/dashboard/components-next/sidebar/LabelLeaf.vue`

```vue
<script setup>
import { computed } from 'vue';
import { useStore } from 'dashboard/composables/store';

const props = defineProps({
  label: { type: Object, required: true },
  active: { type: Boolean, default: false },
});

const store = useStore();

const unreadCount = computed(() =>
  store.getters['conversationStats/getUnreadCountForLabel'](props.label.title)
);

const displayCount = computed(() =>
  unreadCount.value > 99 ? '99+' : unreadCount.value
);
</script>

<template>
  <div class="flex items-center justify-between gap-2">
    <div class="flex items-center gap-2 min-w-0">
      <span
        class="size-2 rounded-full flex-shrink-0"
        :style="{ backgroundColor: props.label.color }"
      />
      <span class="truncate">{{ props.label.title }}</span>
    </div>
    <span
      v-if="unreadCount > 0"
      class="rounded-md text-xs px-1 text-n-slate-11 outline outline-1 outline-n-strong flex-shrink-0"
    >
      {{ displayCount }}
    </span>
  </div>
</template>
```

#### 6.5 Update Labels Menu in Sidebar

**File**: `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`

```javascript
// In labels children mapping
children: labelsOnSidebar.value.map(label => ({
  name: `label-${label.id}`,
  label: label.title,
  to: accountScopedRoute('label_conversations', { label: label.title }),
  component: leafProps =>
    h(LabelLeaf, {
      label: label,
      active: leafProps.active,
    }),
}))
```

---

### Phase 7: Handle All Update Triggers

#### 7.1 Events That Should Refresh Counts

| Event | Location | Action |
|-------|----------|--------|
| New incoming message | `actionCable.js` | Debounced refresh via `fetch_unread_counts` |
| Conversation marked as read | `messageReadActions.js` | Immediate refresh |
| Assignee changed | `actionCable.js` | Already triggers `fetch_conversation_stats` - add unread counts |
| Labels added/removed | Label mutation | Trigger refresh |
| Conversation status changed | `actionCable.js` | Already triggers refresh - add unread counts |
| Conversation deleted | Contact deletion handler | Refresh counts |

#### 7.2 Update Existing Event Handlers

**File**: `app/javascript/dashboard/helper/actionCable.js`

Update `fetchConversationStats` to also fetch unread counts:

```javascript
fetchConversationStats = () => {
  emitter.emit('fetch_conversation_stats');
  emitter.emit('fetch_unread_counts');  // Add this
};
```

#### 7.3 Handle Mark as Read

**File**: `app/javascript/dashboard/store/modules/conversations/actions/messageReadActions.js`

```javascript
export const actions = {
  markMessagesRead: async ({ commit, dispatch }, data) => {
    // Existing logic...

    // Refresh unread counts after marking as read
    dispatch('conversationStats/fetchUnreadCounts', null, { root: true });
  },
};
```

---

## File Changes Summary

### New Files

| File | Purpose |
|------|---------|
| `db/migrate/xxx_add_has_unread_messages_to_conversations.rb` | Add boolean column |
| `db/migrate/xxx_backfill_has_unread_messages.rb` | Backfill existing data |
| `app/services/conversation_unread_count_service.rb` | Calculate unread counts with permission scoping |
| `app/views/api/v1/accounts/conversations/unread_counts.json.jbuilder` | API response |
| `app/javascript/dashboard/components-next/sidebar/LabelLeaf.vue` | Label item with count |

### Modified Files

| File | Changes |
|------|---------|
| `app/models/message.rb` | Add callback to set `has_unread_messages` |
| `app/models/conversation.rb` | Add scope, update `mark_as_read!` method |
| `config/routes.rb` | Add `unread_counts` route |
| `app/controllers/api/v1/accounts/conversations_controller.rb` | Add `unread_counts` action |
| `app/javascript/dashboard/store/modules/conversationStats.js` | Add unread counts state/getters/actions |
| `app/javascript/dashboard/store/mutation-types.js` | Add `SET_UNREAD_COUNTS` |
| `app/javascript/dashboard/api/inbox/conversation.js` | Add `getUnreadCounts()` |
| `app/javascript/dashboard/helper/actionCable.js` | Add unread count event handling |
| `app/javascript/dashboard/components-next/sidebar/Sidebar.vue` | Wire up getters, fetch on mount |
| `app/javascript/dashboard/components-next/sidebar/ChannelLeaf.vue` | Add count display |
| `app/listeners/action_cable_listener.rb` | Add unread count broadcast |

---

## Enterprise Considerations

### Files to Check/Update

1. **`enterprise/app/services/conversation_unread_count_service.rb`** (new if needed)
   - May need to extend for SLA or custom role considerations

2. **`enterprise/app/services/enterprise/conversations/permission_filter_service.rb`** (existing)
   - Already handles custom role permissions - will be used automatically via `prepend_mod_with`

3. **Policy Files**
   - No changes needed - we're using the existing permission filter service

### What Enterprise Gets Automatically

- Custom role permission filtering (via `PermissionFilterService.prepend_mod_with`)
- Inbox access restrictions
- Team-based filtering

---

## Performance Optimizations

### Database Level

1. **Partial indexes** on `has_unread_messages = true` - only index rows we care about
2. **Column is denormalized** - no JOIN with messages table needed
3. **Counts use GROUP BY** - single query for all inboxes/labels

### Application Level

1. **Debounced API calls** - prevent flooding on rapid message arrival
2. **ActionCable push** - no polling, updates pushed in real-time
3. **Permission scoping reuse** - no duplicate permission logic

### Query Comparison

**Before (v1 - JOIN based):**
```sql
-- Expensive: scans messages table
SELECT inbox_id, COUNT(DISTINCT conversations.id)
FROM conversations
INNER JOIN messages ON messages.conversation_id = conversations.id
WHERE messages.created_at > conversations.agent_last_seen_at
  AND messages.message_type = 0
GROUP BY inbox_id;
```

**After (v2 - Boolean column):**
```sql
-- Fast: uses partial index, no JOIN
SELECT inbox_id, COUNT(*)
FROM conversations
WHERE has_unread_messages = true
  AND status IN ('open', 'pending')
GROUP BY inbox_id;
```

---

## Edge Cases Handled

| Edge Case | Handling |
|-----------|----------|
| No unread messages | Display nothing (not "0") |
| Count > 99 | Display "99+" |
| Deleted conversation | Counts refresh on deletion event |
| Multi-label conversation | Counted once per label (correct behavior) |
| Snoozed with unread | Keep `has_unread_messages` true |
| Resolved with unread | Keep `has_unread_messages` true (shows when reopened) |
| Bot messages | Excluded (`message_type = 0` is incoming from contact only) |
| Private notes | Excluded (`private = false` check) |
| Permission changes | Next fetch respects new permissions |

---

## Testing Plan

### Backend Tests

**File**: `spec/services/conversation_unread_count_service_spec.rb`

```ruby
RSpec.describe ConversationUnreadCountService do
  describe '#perform' do
    it 'returns counts grouped by inbox'
    it 'returns counts grouped by label'
    it 'returns counts by status (all/mine/unassigned)'
    it 'respects inbox permission filtering for agents'
    it 'returns all conversations for administrators'
    it 'handles conversations with multiple labels correctly'
    it 'excludes resolved and snoozed conversations'
  end
end
```

**File**: `spec/models/message_spec.rb`

```ruby
describe 'callbacks' do
  describe '#update_conversation_unread_status' do
    it 'sets has_unread_messages to true on incoming message'
    it 'does not update for outgoing messages'
    it 'does not update for private notes'
  end
end
```

**File**: `spec/models/conversation_spec.rb`

```ruby
describe '#mark_as_read!' do
  it 'sets has_unread_messages to false'
  it 'updates agent_last_seen_at'
end

describe '.with_unread_messages' do
  it 'returns only conversations with has_unread_messages = true'
end
```

### Frontend Tests

**File**: `spec/javascript/dashboard/store/modules/conversationStats.spec.js`

```javascript
describe('conversationStats', () => {
  describe('getters', () => {
    it('getUnreadCountForInbox returns count for specific inbox');
    it('getUnreadCountForLabel returns count for specific label');
    it('returns 0 for unknown inbox/label');
  });

  describe('actions', () => {
    it('fetchUnreadCounts calls API and commits mutation');
  });
});
```

---

## Rollout Strategy

### Phase 1: Backend Only (No UI)
1. Deploy migrations
2. Deploy service and API endpoint
3. Verify backfill completed correctly
4. Monitor query performance

### Phase 2: Conversation Tabs
1. Enable unread counts for All/Mine/Unassigned tabs
2. Monitor for issues

### Phase 3: Channels
1. Enable per-inbox counts
2. Monitor performance with many inboxes

### Phase 4: Labels
1. Enable per-label counts
2. Monitor for any edge cases

---

## Open Questions (Resolved)

| Question | Decision |
|----------|----------|
| Include snoozed conversations? | No - filter by `status: [:open, :pending]` |
| Include resolved conversations? | No - filter by `status: [:open, :pending]` |
| Feature flag? | Optional - can add if needed for gradual rollout |
| Teams tab counts? | Future enhancement - same pattern applies |

---

## Estimated Complexity

| Component | Complexity | Notes |
|-----------|------------|-------|
| Database migration | Low | Simple column add + backfill |
| Message callback | Low | Single column update |
| Unread count service | Medium | Permission scoping, grouping |
| API endpoint | Low | Thin controller action |
| Store changes | Medium | Extend existing module |
| Sidebar components | Low-Medium | Follow existing patterns |
| ActionCable integration | Medium | New event type |
| Testing | Medium | Multiple layers |

**Total**: Medium complexity, well-contained changes.
