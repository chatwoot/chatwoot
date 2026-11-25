<script setup>
import {
  computed,
  nextTick,
  onBeforeUnmount,
  onMounted,
  ref,
  watch,
} from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import MessageBubble from './MessageBubble.vue';
import MessageEditor from './MessageEditor.vue';
import { vOnClickOutside } from '@vueuse/components';
import { useBreakpoints, breakpointsTailwind } from '@vueuse/core';

const props = defineProps({
  channelId: {
    type: Number,
    required: true,
  },
  parentMessage: {
    type: Object,
    required: true,
  },
  currentUserId: {
    type: Number,
    required: true,
  },
  isAdmin: {
    type: Boolean,
    default: false,
  },
  highlightMessageId: {
    type: Number,
    default: null,
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();

const breakpoints = useBreakpoints(breakpointsTailwind);
const isBelowLarge = breakpoints.smaller('lg');

// The panel only overlays the conversation below lg. As a desktop column it has
// to stay put when the user clicks a message next to it.
const closeOnClickOutside = () => {
  if (isBelowLarge.value) emit('close');
};

const isLoading = ref(false);
const isSending = ref(false);
const editingMessage = ref(null);
const threadEditorRef = ref(null);
const scrollContainerRef = ref(null);
let activeThreadRequestId = null;

const HIGHLIGHT_CLASSES = [
  'bg-n-amber-3',
  'ring-1',
  'ring-n-amber-7',
  'rounded-lg',
];

function scrollToBottom() {
  const el = scrollContainerRef.value;
  if (!el) return;
  el.scrollTop = el.scrollHeight;
}

function scrollToMessage(messageId) {
  const container = scrollContainerRef.value;
  if (!container) return false;
  const el = container.querySelector(`[data-message-id="${messageId}"]`);
  if (!el) return false;
  el.scrollIntoView({ behavior: 'smooth', block: 'center' });
  el.classList.add(...HIGHLIGHT_CLASSES);
  setTimeout(() => el.classList.remove(...HIGHLIGHT_CLASSES), 3000);
  return true;
}

const threadReplies = computed(() => {
  return store.getters['internalChat/messages/getThreadReplies'](
    props.parentMessage.id
  );
});

const replyCount = computed(() => threadReplies.value.length);

async function fetchThread() {
  const requestId = props.parentMessage.id;
  activeThreadRequestId = requestId;
  isLoading.value = true;
  try {
    await store.dispatch('internalChat/messages/fetchThread', {
      channelId: props.channelId,
      messageId: props.parentMessage.id,
    });
    if (activeThreadRequestId !== requestId) return;
    isLoading.value = false;
    await nextTick();
    if (props.highlightMessageId) {
      scrollToMessage(props.highlightMessageId);
    } else {
      scrollToBottom();
    }
  } catch {
    if (activeThreadRequestId !== requestId) return;
    useAlert(t('INTERNAL_CHAT.ERRORS.FETCH_MESSAGES'));
  } finally {
    if (activeThreadRequestId === requestId) {
      isLoading.value = false;
    }
  }
}

function deleteThreadDraft(parentId = props.parentMessage.id) {
  const draft = store.getters['internalChat/drafts/getThreadDraft'](
    props.channelId,
    parentId
  );
  if (draft) {
    store
      .dispatch('internalChat/drafts/deleteDraft', {
        channelId: props.channelId,
        draftId: draft.id,
        parentId,
      })
      .catch(() => {});
  }
}

async function handleSendReply(content, options = {}) {
  isSending.value = true;
  try {
    if (editingMessage.value) {
      await store.dispatch('internalChat/messages/updateMessage', {
        channelId: props.channelId,
        messageId: editingMessage.value.id,
        data: { content },
      });
      editingMessage.value = null;
    } else {
      await store.dispatch('internalChat/messages/sendThreadReply', {
        channelId: props.channelId,
        parentMessageId: props.parentMessage.id,
        data: { content, also_send_in_channel: !!options.alsoSendInChannel },
        files: options.files || [],
      });
      deleteThreadDraft();
      await nextTick();
      scrollToBottom();
    }
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  } finally {
    isSending.value = false;
  }
}

function handleEditReply(message) {
  editingMessage.value = message;
}

function handleCancelEdit() {
  editingMessage.value = null;
}

function handleDeleteReply(message) {
  store
    .dispatch('internalChat/messages/deleteMessage', {
      channelId: props.channelId,
      messageId: message.id,
    })
    .catch(() => {
      useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
    });
}

function handleAddReaction({ messageId, emoji }) {
  store
    .dispatch('internalChat/messages/addReaction', {
      channelId: props.channelId,
      messageId,
      emoji,
    })
    .catch(() => {
      // Silently ignore reaction errors
    });
}

function handleRemoveReaction({ messageId, reactionId }) {
  store
    .dispatch('internalChat/messages/removeReaction', {
      channelId: props.channelId,
      messageId,
      reactionId,
    })
    .catch(() => {
      // Silently ignore reaction errors
    });
}

function handleVote({ messageId, optionId }) {
  const msg = store.getters['internalChat/messages/getMessageById'](
    props.channelId,
    messageId
  );
  const pollId = msg?.poll?.id || msg?.content_attributes?.poll?.id;
  if (!pollId) return;
  store
    .dispatch('internalChat/polls/vote', {
      pollId,
      optionId,
      channelId: props.channelId,
    })
    .catch(() => {});
}

function handleUnvote({ messageId, optionId }) {
  const msg = store.getters['internalChat/messages/getMessageById'](
    props.channelId,
    messageId
  );
  const pollId = msg?.poll?.id || msg?.content_attributes?.poll?.id;
  if (!pollId) return;
  store
    .dispatch('internalChat/polls/unvote', {
      pollId,
      optionId,
      channelId: props.channelId,
    })
    .catch(() => {});
}

function loadThreadDraft() {
  const draft = store.getters['internalChat/drafts/getThreadDraft'](
    props.channelId,
    props.parentMessage.id
  );
  if (threadEditorRef.value) {
    threadEditorRef.value.setContent(draft ? draft.content : '');
  }
}

async function handleThreadDraftUpdate(content) {
  if (!content || !content.trim()) {
    deleteThreadDraft();
    return;
  }
  try {
    await store.dispatch('internalChat/drafts/saveDraft', {
      channelId: props.channelId,
      content,
      parentId: props.parentMessage.id,
    });
  } catch {
    // Silently handle
  }
}

function saveThreadDraftImmediately(parentId = props.parentMessage.id) {
  const content = threadEditorRef.value?.getContent?.() || '';
  if (content.trim()) {
    store
      .dispatch('internalChat/drafts/saveDraft', {
        channelId: props.channelId,
        content,
        parentId,
      })
      .catch(() => {});
  } else {
    deleteThreadDraft(parentId);
  }
}

watch(
  () => props.parentMessage.id,
  (newId, oldId) => {
    if (oldId) saveThreadDraftImmediately(oldId);
    fetchThread();
    loadThreadDraft();
  }
);

async function jumpToReply(messageId) {
  if (!messageId) return;
  await nextTick();
  if (!scrollToMessage(messageId)) {
    await fetchThread();
    await nextTick();
    scrollToMessage(messageId);
  }
}

defineExpose({ jumpToReply });

onMounted(() => {
  fetchThread();
  loadThreadDraft();
});

onBeforeUnmount(() => {
  saveThreadDraftImmediately();
});
</script>

<template>
  <div
    v-on-click-outside="[
      closeOnClickOutside,
      {
        ignore: ['dialog', '[data-popover-content]', '[data-popover-backdrop]'],
      },
    ]"
    class="fixed inset-y-0 z-40 flex w-full max-w-sm flex-col overflow-x-clip bg-n-solid-1 shadow-lg border-n-slate-5 ltr:right-0 ltr:border-l rtl:left-0 rtl:border-r lg:static lg:h-full lg:w-96 lg:max-w-none lg:shadow-none"
  >
    <div
      class="flex h-[53px] items-center justify-between border-b border-n-slate-5 px-4"
    >
      <h3 class="text-sm font-semibold text-n-slate-12">
        {{ t('INTERNAL_CHAT.THREAD.TITLE') }}
      </h3>
      <button
        :aria-label="t('INTERNAL_CHAT.THREAD.CLOSE')"
        class="flex items-center justify-center rounded p-1 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
        @click="emit('close')"
      >
        <Icon icon="i-lucide-x" class="size-4" />
      </button>
    </div>

    <div ref="scrollContainerRef" class="flex-1 overflow-y-auto">
      <div
        class="border-b border-n-slate-5 pb-2"
        :data-message-id="parentMessage.id"
      >
        <MessageBubble
          :message="parentMessage"
          :current-user-id="currentUserId"
          :is-admin="isAdmin"
          in-thread
          @edit="handleEditReply"
          @delete="handleDeleteReply"
          @add-reaction="handleAddReaction"
          @remove-reaction="handleRemoveReaction"
          @vote="handleVote"
          @unvote="handleUnvote"
        />
      </div>

      <div class="px-4 py-2">
        <span class="text-xs font-medium text-n-slate-10">
          {{ t('INTERNAL_CHAT.THREAD.REPLIES', { count: replyCount }) }}
        </span>
      </div>

      <div v-if="isLoading" class="flex items-center justify-center py-4">
        <Spinner :size="16" />
        <span class="ml-2 text-xs text-n-slate-10">
          {{ t('INTERNAL_CHAT.LOADING_MESSAGES') }}
        </span>
      </div>

      <div v-else>
        <div
          v-for="reply in threadReplies"
          :key="reply.id"
          :data-message-id="reply.id"
        >
          <MessageBubble
            :message="reply"
            :current-user-id="currentUserId"
            :is-admin="isAdmin"
            in-thread
            @edit="handleEditReply"
            @delete="handleDeleteReply"
            @add-reaction="handleAddReaction"
            @remove-reaction="handleRemoveReaction"
            @vote="handleVote"
            @unvote="handleUnvote"
          />
        </div>
      </div>
    </div>

    <MessageEditor
      ref="threadEditorRef"
      :disabled="isSending"
      :editing-message="editingMessage"
      :placeholder="t('INTERNAL_CHAT.THREAD.REPLY_PLACEHOLDER')"
      :show-poll="false"
      show-also-send-in-channel
      @send="handleSendReply"
      @cancel-edit="handleCancelEdit"
      @draft-update="handleThreadDraftUpdate"
    />
  </div>
</template>
