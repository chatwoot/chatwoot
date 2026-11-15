<script setup>
import { ref, computed, nextTick, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import MessageSkeleton from './MessageSkeleton.vue';
import MessageBubble from './MessageBubble.vue';
import {
  currentDateLocale,
  dateTimeFormat,
} from 'shared/helpers/localizedDate';

const props = defineProps({
  channelId: {
    type: Number,
    required: true,
  },
  messages: {
    type: Array,
    default: () => [],
  },
  currentUserId: {
    type: Number,
    required: true,
  },
  isAdmin: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  isLoadingMore: {
    type: Boolean,
    default: false,
  },
  isViewingHistory: {
    type: Boolean,
    default: false,
  },
  firstUnreadMessageId: {
    type: Number,
    default: null,
  },
  threadDraftParentIds: {
    type: Set,
    default: () => new Set(),
  },
});

const emit = defineEmits([
  'edit',
  'delete',
  'reply',
  'openThread',
  'addReaction',
  'removeReaction',
  'pin',
  'unpin',
  'vote',
  'unvote',
  'loadMore',
  'loadNewer',
  'jumpToLatest',
]);

const { t } = useI18n();

const listRef = ref(null);
const showScrollToBottom = ref(false);
const hasReachedOldest = ref(false);
const isLoadingNewer = ref(false);
const lastMessageCount = ref(0);

// Track edge message IDs to detect prepend (older loaded) vs append (newer loaded)
// vs real-time new message. Set when loadMore/loadNewer triggers.
let previousFirstMessageId = null;
let previousLastMessageId = null;

// Suppresses the scroll handler briefly after scroll restoration,
// preventing the restored position from immediately re-triggering loadMore.
let suppressScrollUntil = 0;

// When set, the messages.length watcher scrolls to this message instead
// of auto-scrolling to bottom. Used by linked message navigation.
let pendingScrollTarget = null;

function scrollToMessageOnLoad(messageId) {
  pendingScrollTarget = messageId;
}

function getMessageTimestamp(message) {
  const createdAt = message.created_at;
  if (typeof createdAt === 'number') return createdAt;
  return Math.floor(new Date(createdAt).getTime() / 1000);
}

function shouldGroup(a, b) {
  if (!a || !b) return false;
  const sameSender = a.sender?.id && a.sender.id === b.sender?.id;
  if (!sameSender) return false;
  if ((a.parent_id || null) !== (b.parent_id || null)) return false;
  return (
    Math.floor(getMessageTimestamp(a) / 60) ===
    Math.floor(getMessageTimestamp(b) / 60)
  );
}

const dateSeparatedMessages = computed(() => {
  const groups = [];
  let currentDate = null;
  let unreadInserted = false;

  props.messages.forEach(message => {
    // Insert unread separator before the first unread message
    if (
      !unreadInserted &&
      props.firstUnreadMessageId &&
      message.id === props.firstUnreadMessageId
    ) {
      groups.push({ type: 'unread', key: 'unread-separator' });
      unreadInserted = true;
    }

    const createdAt = message.created_at;
    const msgDate =
      typeof createdAt === 'number'
        ? new Date(createdAt * 1000)
        : new Date(createdAt);
    const dateKey = msgDate.toDateString();

    if (dateKey !== currentDate) {
      currentDate = dateKey;
      groups.push({ type: 'date', date: msgDate, key: `date-${dateKey}` });
    }
    groups.push({ type: 'message', data: message, key: `msg-${message.id}` });
  });

  // Compute grouping flags: consecutive messages from same sender within same minute
  const messageItems = groups.filter(g => g.type === 'message');
  for (let i = 0; i < messageItems.length; i += 1) {
    const prev = i > 0 ? messageItems[i - 1].data : null;
    const curr = messageItems[i].data;
    const next = i < messageItems.length - 1 ? messageItems[i + 1].data : null;
    messageItems[i].groupWithPrevious = shouldGroup(prev, curr);
    messageItems[i].groupWithNext = shouldGroup(curr, next);
  }

  return groups;
});

function formatDateSeparator(date) {
  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);

  if (date.toDateString() === today.toDateString()) {
    return t('INTERNAL_CHAT.DATE_SEPARATOR.TODAY');
  }
  if (date.toDateString() === yesterday.toDateString()) {
    return t('INTERNAL_CHAT.DATE_SEPARATOR.YESTERDAY');
  }
  return dateTimeFormat(currentDateLocale(), {
    month: 'short',
    day: 'numeric',
    year: date.getFullYear() !== today.getFullYear() ? 'numeric' : undefined,
  }).format(date);
}

// With flex-col-reverse, scrollTop = 0 is the bottom (newest messages).
function scrollToBottom() {
  if (!listRef.value) return;
  listRef.value.scrollTop = 0;
  showScrollToBottom.value = false;
}

const HIGHLIGHT_CLASSES = [
  'bg-n-amber-3',
  'ring-1',
  'ring-n-amber-7',
  'rounded-lg',
];

function scrollToMessage(messageId) {
  const el = listRef.value?.querySelector(`[data-message-id="${messageId}"]`);
  if (el) {
    el.scrollIntoView({ behavior: 'smooth', block: 'center' });
    el.classList.add(...HIGHLIGHT_CLASSES);
    setTimeout(() => el.classList.remove(...HIGHLIGHT_CLASSES), 3000);
    return true;
  }
  return false;
}

function handleScroll() {
  if (!listRef.value || Date.now() < suppressScrollUntil) return;

  const { scrollTop, scrollHeight, clientHeight } = listRef.value;

  // flex-col-reverse: scrollTop is 0 at bottom (newest), negative when scrolled up
  const distanceFromBottom = Math.abs(scrollTop);
  const maxScroll = scrollHeight - clientHeight;
  const distanceFromTop = maxScroll - distanceFromBottom;

  showScrollToBottom.value = distanceFromBottom > 100;

  // Load older messages when near the top (oldest messages)
  if (
    distanceFromTop < 100 &&
    maxScroll > 0 &&
    props.messages.length > 0 &&
    !props.isLoading &&
    !props.isLoadingMore &&
    !hasReachedOldest.value
  ) {
    lastMessageCount.value = props.messages.length;
    previousFirstMessageId = props.messages[0]?.id;
    emit('loadMore');
  }

  // Load newer messages when near bottom while viewing history
  if (
    props.isViewingHistory &&
    distanceFromBottom < 100 &&
    props.messages.length > 0 &&
    !props.isLoading &&
    !props.isLoadingMore &&
    !isLoadingNewer.value
  ) {
    isLoadingNewer.value = true;
    previousLastMessageId = props.messages[props.messages.length - 1]?.id;
    emit('loadNewer');
  }
}

// Detect when loadMore completes with no new messages (reached oldest)
watch(
  () => props.isLoadingMore,
  (loading, wasLoading) => {
    if (wasLoading && !loading) {
      if (props.messages.length === lastMessageCount.value) {
        hasReachedOldest.value = true;
      }
    }
  }
);

// Reset isLoadingNewer when isViewingHistory changes (load completed)
watch(
  () => props.isViewingHistory,
  () => {
    isLoadingNewer.value = false;
  }
);

// Scroll to the unread separator when it appears (after channel load)
watch(
  () => props.firstUnreadMessageId,
  async id => {
    if (!id || !listRef.value) return;
    await nextTick();
    const el = listRef.value.querySelector('[data-unread-separator]');
    if (el) {
      el.scrollIntoView({ block: 'center' });
      suppressScrollUntil = Date.now() + 200;
    }
  }
);

// Reset state on channel switch
watch(
  () => props.channelId,
  async () => {
    hasReachedOldest.value = false;
    isLoadingNewer.value = false;
    showScrollToBottom.value = false;
    lastMessageCount.value = 0;
    previousFirstMessageId = null;
    previousLastMessageId = null;
    // Ensure scroll resets to bottom (scrollTop = 0) for the new channel
    await nextTick();
    scrollToBottom();
  }
);

// Handle new messages arriving
watch(
  () => props.messages.length,
  async (newLen, oldLen) => {
    if (newLen === 0) {
      hasReachedOldest.value = false;
      isLoadingNewer.value = false;
      previousFirstMessageId = null;
      previousLastMessageId = null;
      return;
    }

    isLoadingNewer.value = false;

    // Linked message navigation: scroll to target instead of bottom
    if (pendingScrollTarget) {
      const targetId = pendingScrollTarget;
      pendingScrollTarget = null;
      await nextTick();
      scrollToMessage(targetId);
      suppressScrollUntil = Date.now() + 200;
      return;
    }

    if (newLen > oldLen && oldLen > 0) {
      const firstMessageId = props.messages[0]?.id;
      const lastMessageId = props.messages[props.messages.length - 1]?.id;

      const wasPrepend =
        previousFirstMessageId && firstMessageId !== previousFirstMessageId;

      const wasAppendFromHistory =
        previousLastMessageId && lastMessageId !== previousLastMessageId;

      if (wasPrepend && listRef.value) {
        // Older messages loaded: anchor on the previously-first message
        const anchorId = previousFirstMessageId;
        await nextTick();
        const anchorEl = listRef.value.querySelector(
          `[data-message-id="${anchorId}"]`
        );
        if (anchorEl) {
          anchorEl.scrollIntoView({ block: 'start' });
        }
        previousFirstMessageId = firstMessageId;
        suppressScrollUntil = Date.now() + 200;
        return;
      }

      if (wasAppendFromHistory && listRef.value) {
        // Newer messages loaded (history navigation): anchor on the
        // previously-last message so the view doesn't jump to bottom
        const anchorId = previousLastMessageId;
        previousLastMessageId = null;
        await nextTick();
        const anchorEl = listRef.value.querySelector(
          `[data-message-id="${anchorId}"]`
        );
        if (anchorEl) {
          anchorEl.scrollIntoView({ block: 'end' });
        }
        suppressScrollUntil = Date.now() + 200;
        return;
      }

      // Real-time new message: auto-scroll if user was near bottom or sent it
      const lastMsg = props.messages[props.messages.length - 1];
      const isOwnMessage = lastMsg?.sender?.id === props.currentUserId;

      if (isOwnMessage || !showScrollToBottom.value) {
        await nextTick();
        scrollToBottom();
      }
    }
  }
);

defineExpose({ scrollToMessage, scrollToMessageOnLoad });
</script>

<template>
  <div class="relative flex-1 overflow-hidden">
    <div
      ref="listRef"
      class="flex h-full flex-col-reverse overflow-y-auto"
      @scroll="handleScroll"
    >
      <div>
        <div v-if="isLoading && messages.length === 0">
          <MessageSkeleton />
        </div>
        <div v-if="isLoadingMore">
          <MessageSkeleton />
        </div>
        <div
          v-if="messages.length === 0 && !isLoading"
          class="flex h-full flex-col items-center justify-center gap-2 py-16"
        >
          <Icon
            icon="i-lucide-message-square-plus"
            class="size-10 text-n-slate-8"
          />
          <p class="text-sm font-medium text-n-slate-12">
            {{ t('INTERNAL_CHAT.CHANNEL.NO_MESSAGES') }}
          </p>
          <p class="text-xs text-n-slate-10">
            {{ t('INTERNAL_CHAT.CHANNEL.NO_MESSAGES_SUBTITLE') }}
          </p>
        </div>
        <template v-for="item in dateSeparatedMessages" :key="item.key">
          <div
            v-if="item.type === 'unread'"
            data-unread-separator
            class="flex items-center gap-3 px-4 py-2"
          >
            <div class="flex-1 border-t border-n-ruby-7" />
            <span class="text-xs font-medium text-n-ruby-11">
              {{ t('INTERNAL_CHAT.NEW_MESSAGES') }}
            </span>
            <div class="flex-1 border-t border-n-ruby-7" />
          </div>
          <div
            v-else-if="item.type === 'date'"
            class="flex items-center gap-3 px-4 py-2"
          >
            <div class="flex-1 border-t border-n-slate-5" />
            <span class="text-xs font-medium text-n-slate-10">
              {{ formatDateSeparator(item.date) }}
            </span>
            <div class="flex-1 border-t border-n-slate-5" />
          </div>
          <div v-else :data-message-id="item.data.id">
            <MessageBubble
              :message="item.data"
              :current-user-id="currentUserId"
              :is-admin="isAdmin"
              :group-with-previous="item.groupWithPrevious"
              :group-with-next="item.groupWithNext"
              :has-thread-draft="threadDraftParentIds.has(item.data.id)"
              @edit="emit('edit', $event)"
              @delete="emit('delete', $event)"
              @reply="emit('reply', $event)"
              @open-thread="emit('openThread', $event)"
              @add-reaction="emit('addReaction', $event)"
              @remove-reaction="emit('removeReaction', $event)"
              @pin="emit('pin', $event)"
              @unpin="emit('unpin', $event)"
              @vote="emit('vote', $event)"
              @unvote="emit('unvote', $event)"
            />
          </div>
        </template>
      </div>
    </div>
    <button
      v-if="showScrollToBottom || isViewingHistory"
      class="absolute bottom-4 right-4 z-20 flex items-center justify-center rounded-full bg-n-solid-3 p-2 shadow-md border border-n-slate-6 text-n-slate-11 hover:bg-n-solid-4 hover:text-n-slate-12 transition-colors"
      :title="t('INTERNAL_CHAT.SCROLL_TO_BOTTOM')"
      @click="isViewingHistory ? emit('jumpToLatest') : scrollToBottom()"
    >
      <Icon icon="i-lucide-arrow-down" class="size-4" />
    </button>
  </div>
</template>
