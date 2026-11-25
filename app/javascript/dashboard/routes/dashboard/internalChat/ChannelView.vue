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
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { emitter } from 'shared/helpers/mitt';
import InternalChatChannelsAPI from 'dashboard/api/internalChatChannels';
import ChannelHeader from './ChannelHeader.vue';
import MessageList from './MessageList.vue';
import MessageEditor from './MessageEditor.vue';
import TypingIndicator from './TypingIndicator.vue';
import ThreadPanel from './ThreadPanel.vue';
import PollCreator from './PollCreator.vue';
import ChannelSettings from './ChannelSettings.vue';
import EditMembersModal from './EditMembersModal.vue';
import ProFeatureNudge from './ProFeatureNudge.vue';
import { useInternalChatPro } from 'dashboard/composables/useInternalChatPro';
import { useBreakpoints, breakpointsTailwind } from '@vueuse/core';

const props = defineProps({
  channelId: {
    type: Number,
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const breakpoints = useBreakpoints(breakpointsTailwind);
const isBelowLarge = breakpoints.smaller('lg');

const typingUsers = computed(() => {
  return (
    store.getters['internalChatTypingStatus/getUserList'](props.channelId) || []
  );
});
const editorRef = ref(null);
const messageListRef = ref(null);
const activeThread = ref(null);
const threadHighlightMessageId = ref(null);
const threadPanelRef = ref(null);
const pollCreatorRef = ref(null);
const editMembersRef = ref(null);
const channelSettingsRef = ref(null);
const proNudgeRef = ref(null);
const proNudgeFeature = ref('polls');
const { pollsEnabled } = useInternalChatPro();
const editingMessage = ref(null);
// Below lg the settings panel covers the conversation, so a stored "open" from
// a desktop session must not be what greets you when you open a channel here.
const showSettings = ref(
  !isBelowLarge.value &&
    localStorage.getItem('internal_chat_settings_open') === 'true'
);
const isLoadingMore = ref(false);
const isViewingHistory = ref(false);
const firstUnreadMessageId = ref(null);

const currentUser = useMapGetter('getCurrentUser');
const currentRole = useMapGetter('getCurrentRole');

const channel = computed(() => {
  return store.getters['internalChat/getChannelById'](props.channelId);
});

const messages = computed(() => {
  return store.getters['internalChat/messages/getMessages'](props.channelId);
});

const messagesUIFlags = computed(() => {
  return store.getters['internalChat/messages/getUIFlags'];
});

const currentUserId = computed(() => {
  return currentUser.value?.id;
});

const isAdmin = computed(() => {
  return currentRole.value === 'administrator';
});

const isArchived = computed(() => {
  return channel.value?.status === 'archived';
});

const pinnedMessages = computed(() => {
  return messages.value.filter(m => m.content_attributes?.pinned);
});

const threadDraftParentIds = computed(() => {
  return store.getters['internalChat/drafts/getThreadDraftParentIds'](
    props.channelId
  );
});

function markRead() {
  store.dispatch('internalChat/markRead', props.channelId);
}

async function fetchMessages() {
  try {
    await store.dispatch('internalChat/messages/fetchMessages', {
      channelId: props.channelId,
    });
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.FETCH_MESSAGES'));
  }
}

function computeFirstUnreadId(unreadCount) {
  if (unreadCount > 0 && messages.value.length > 0) {
    const idx = Math.max(0, messages.value.length - unreadCount);
    firstUnreadMessageId.value = messages.value[idx]?.id || null;
  } else {
    firstUnreadMessageId.value = null;
  }
}

function loadDraft() {
  // Set editor content immediately from store (no network wait)
  const draft = store.getters['internalChat/drafts/getDraftByChannelId'](
    props.channelId
  );
  if (editorRef.value) {
    editorRef.value.setContent(draft ? draft.content : '');
  }
}

function deleteDraftForChannel() {
  const draft = store.getters['internalChat/drafts/getDraftByChannelId'](
    props.channelId
  );
  if (draft) {
    store
      .dispatch('internalChat/drafts/deleteDraft', {
        channelId: props.channelId,
        draftId: draft.id,
      })
      .catch(() => {});
  }
}

async function handleSend(content, options = {}) {
  try {
    if (editingMessage.value) {
      await store.dispatch('internalChat/messages/updateMessage', {
        channelId: props.channelId,
        messageId: editingMessage.value.id,
        data: { content },
      });
      editingMessage.value = null;
    } else {
      await store.dispatch('internalChat/messages/sendMessage', {
        channelId: props.channelId,
        data: { content },
        files: options.files || [],
      });
      markRead();
      deleteDraftForChannel();
    }
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  }
}

function handleEdit(message) {
  editingMessage.value = message;
}

function handleCancelEdit() {
  editingMessage.value = null;
}

async function handleDelete(message) {
  try {
    await store.dispatch('internalChat/messages/deleteMessage', {
      channelId: props.channelId,
      messageId: message.id,
    });
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  }
}

async function handleAddReaction({ messageId, emoji }) {
  try {
    await store.dispatch('internalChat/messages/addReaction', {
      channelId: props.channelId,
      messageId,
      emoji,
    });
  } catch {
    // Silently ignore reaction errors
  }
}

async function handleRemoveReaction({ messageId, reactionId }) {
  try {
    await store.dispatch('internalChat/messages/removeReaction', {
      channelId: props.channelId,
      messageId,
      reactionId,
    });
  } catch {
    // Silently ignore reaction errors
  }
}

let typingOffTimer = null;

function handleTyping() {
  InternalChatChannelsAPI.toggleTypingStatus(props.channelId, 'on');
  if (typingOffTimer) clearTimeout(typingOffTimer);
  typingOffTimer = setTimeout(() => {
    InternalChatChannelsAPI.toggleTypingStatus(props.channelId, 'off');
  }, 3000);
}

function handleReply(message) {
  activeThread.value = message;
  showSettings.value = false;
  localStorage.setItem('internal_chat_settings_open', 'false');
}

function handleCreatePoll() {
  if (!pollsEnabled.value) {
    proNudgeFeature.value = 'polls';
    proNudgeRef.value?.open();
    return;
  }
  pollCreatorRef.value?.open();
}

function handleOpenThread(message) {
  // If message has parent_id, find the parent message to open its thread
  const parentId = message.parent_id;
  if (parentId) {
    const parent = messages.value.find(m => m.id === parentId);
    if (parent) {
      activeThread.value = parent;
    } else {
      // Parent not in local messages, use the message itself as a stub
      activeThread.value = {
        id: parentId,
        content: '',
        sender: message.sender,
      };
    }
  } else {
    activeThread.value = message;
  }
  showSettings.value = false;
  localStorage.setItem('internal_chat_settings_open', 'false');
}

function closeThread() {
  activeThread.value = null;
  threadHighlightMessageId.value = null;
}

async function handlePin(message) {
  try {
    await store.dispatch('internalChat/messages/pinMessage', {
      channelId: props.channelId,
      messageId: message.id,
    });
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  }
}

async function handleUnpin(message) {
  try {
    await store.dispatch('internalChat/messages/unpinMessage', {
      channelId: props.channelId,
      messageId: message.id,
    });
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  }
}

async function handleVote({ messageId, optionId }) {
  const msg = store.getters['internalChat/messages/getMessageById'](
    props.channelId,
    messageId
  );
  const pollId = msg?.poll?.id || msg?.content_attributes?.poll?.id;
  if (!pollId) return;
  try {
    await store.dispatch('internalChat/polls/vote', {
      pollId,
      optionId,
      channelId: props.channelId,
    });
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  }
}

async function handleUnvote({ messageId, optionId }) {
  const msg = store.getters['internalChat/messages/getMessageById'](
    props.channelId,
    messageId
  );
  const pollId = msg?.poll?.id || msg?.content_attributes?.poll?.id;
  if (!pollId) return;
  try {
    await store.dispatch('internalChat/polls/unvote', {
      pollId,
      optionId,
      channelId: props.channelId,
    });
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  }
}

async function handlePollSubmit(pollData) {
  try {
    await store.dispatch('internalChat/polls/createPoll', {
      channelId: props.channelId,
      data: pollData,
    });
    // Dialog closes itself after submit
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  }
}

function handleScrollToPinned(message) {
  messageListRef.value?.scrollToMessage(message.id);
}

async function handleArchive() {
  try {
    await store.dispatch('internalChat/archive', props.channelId);
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  }
}

async function handleUnarchive() {
  try {
    await store.dispatch('internalChat/unarchive', props.channelId);
  } catch (error) {
    if (error?.response?.status === 402) {
      proNudgeFeature.value = 'private_channels';
      proNudgeRef.value?.open();
    } else {
      useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
    }
  }
}

async function handleDeleteChannel() {
  try {
    await store.dispatch('internalChat/delete', props.channelId);
    showSettings.value = false;
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  }
}

async function handleCloseDM() {
  try {
    const ch = channel.value;
    const membership = (ch?.members || []).find(
      m => m.user_id === currentUserId.value
    );
    if (membership) {
      await InternalChatChannelsAPI.updateMember(
        props.channelId,
        membership.id,
        { hidden: true }
      );
    }
    store.commit('internalChat/UPDATE_CHANNEL', {
      id: props.channelId,
      hidden: true,
    });
    showSettings.value = false;
    router.push({
      name: 'internal_chat_home',
      params: { accountId: route.params.accountId },
    });
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  }
}

async function handleToggleMute() {
  try {
    await store.dispatch('internalChat/toggleMute', props.channelId);
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  }
}

async function handleToggleFavorite() {
  try {
    await store.dispatch('internalChat/toggleFavorite', props.channelId);
  } catch {
    useAlert(t('INTERNAL_CHAT.ERRORS.SEND_MESSAGE'));
  }
}

async function handleDraftUpdate(content) {
  if (!content || !content.trim()) {
    deleteDraftForChannel();
    return;
  }
  try {
    await store.dispatch('internalChat/drafts/saveDraft', {
      channelId: props.channelId,
      content,
    });
  } catch {
    // Silently handle draft save error
  }
}

function saveDraftImmediately() {
  const content = editorRef.value?.getContent?.() || '';
  if (content.trim()) {
    store
      .dispatch('internalChat/drafts/saveDraft', {
        channelId: props.channelId,
        content,
      })
      .catch(() => {});
  } else {
    deleteDraftForChannel();
  }
}

function handleToggleSettings() {
  showSettings.value = !showSettings.value;
  if (showSettings.value) activeThread.value = null;
  localStorage.setItem(
    'internal_chat_settings_open',
    String(showSettings.value)
  );
}

async function handleLoadMore() {
  if (!messages.value.length) return;
  const oldestMessage = messages.value[0];
  isLoadingMore.value = true;
  try {
    await store.dispatch('internalChat/messages/fetchMessages', {
      channelId: props.channelId,
      params: { before: oldestMessage.created_at },
    });
  } catch {
    // silently ignore pagination errors
  } finally {
    isLoadingMore.value = false;
  }
}

watch(
  () => props.channelId,
  async (newId, oldId) => {
    if (oldId) saveDraftImmediately();
    activeThread.value = null;
    editingMessage.value = null;
    isViewingHistory.value = false;
    firstUnreadMessageId.value = null;
    const unreadCount = channel.value?.unread_count || 0;
    await fetchMessages();
    computeFirstUnreadId(unreadCount);
    markRead();
    loadDraft();
  }
);

async function scrollToLinkedMessage(override = null) {
  const messageId = override?.messageId ?? route.query.messageId;
  const parentId = override?.parentId ?? route.query.parentId;
  if (!messageId) return;

  await nextTick();

  if (parentId) {
    const numericParentId = Number(parentId);
    const numericMessageId = Number(messageId);
    if (activeThread.value?.id === numericParentId) {
      threadPanelRef.value?.jumpToReply(numericMessageId);
      return;
    }
    try {
      const response = await store.dispatch(
        'internalChat/messages/fetchThread',
        {
          channelId: props.channelId,
          messageId: numericParentId,
        }
      );
      if (response?.parent) {
        threadHighlightMessageId.value = numericMessageId;
        activeThread.value = response.parent;
        showSettings.value = false;
        localStorage.setItem('internal_chat_settings_open', 'false');
      }
    } catch {
      // Thread may not exist
    }
    return;
  }

  const scrolled = messageListRef.value?.scrollToMessage(Number(messageId));

  if (!scrolled) {
    try {
      messageListRef.value?.scrollToMessageOnLoad(Number(messageId));
      await store.dispatch('internalChat/messages/fetchMessages', {
        channelId: props.channelId,
        params: { around: messageId },
      });
      isViewingHistory.value = true;
    } catch {
      // Message may not exist
    }
  }
}

async function handleLoadNewer() {
  if (!messages.value.length) return;
  const newestMessage = messages.value[messages.value.length - 1];
  try {
    const result = await store.dispatch('internalChat/messages/fetchMessages', {
      channelId: props.channelId,
      params: { after: newestMessage.created_at },
    });
    if (!result || result.length === 0) {
      isViewingHistory.value = false;
    }
  } catch {
    // silently ignore
  }
}

function handleJumpToLatest() {
  isViewingHistory.value = false;
  fetchMessages();
}

onMounted(async () => {
  store.dispatch('internalChat/drafts/fetchDrafts').catch(() => {});
  const unreadCount = channel.value?.unread_count || 0;
  await fetchMessages();
  computeFirstUnreadId(unreadCount);
  markRead();
  loadDraft();
  scrollToLinkedMessage();
});

watch(
  () => [route.query.messageId, route.query.parentId],
  ([newMessageId]) => {
    if (!newMessageId) return;
    scrollToLinkedMessage();
  }
);

function handleJumpToMessage(payload) {
  if (!payload || payload.channelId !== props.channelId) return;
  scrollToLinkedMessage({
    messageId: payload.messageId,
    parentId: payload.parentId,
  });
}

emitter.on('internal-chat:jump-to-message', handleJumpToMessage);

onBeforeUnmount(() => {
  emitter.off('internal-chat:jump-to-message', handleJumpToMessage);
  if (typingOffTimer) {
    clearTimeout(typingOffTimer);
    typingOffTimer = null;
  }
  saveDraftImmediately();
});
</script>

<template>
  <div class="flex h-full">
    <div class="flex flex-1 flex-col bg-n-solid-1 min-w-0">
      <ChannelHeader
        :channel="channel"
        :pinned-messages="pinnedMessages"
        @settings="handleToggleSettings"
        @scroll-to-pinned="handleScrollToPinned"
      />
      <MessageList
        ref="messageListRef"
        :channel-id="channelId"
        :messages="messages"
        :current-user-id="currentUserId"
        :is-admin="isAdmin"
        :is-loading="messagesUIFlags.isFetching"
        :is-loading-more="isLoadingMore"
        :is-viewing-history="isViewingHistory"
        :first-unread-message-id="firstUnreadMessageId"
        :thread-draft-parent-ids="threadDraftParentIds"
        @edit="handleEdit"
        @delete="handleDelete"
        @reply="handleReply"
        @open-thread="handleOpenThread"
        @add-reaction="handleAddReaction"
        @remove-reaction="handleRemoveReaction"
        @pin="handlePin"
        @unpin="handleUnpin"
        @vote="handleVote"
        @unvote="handleUnvote"
        @load-more="handleLoadMore"
        @load-newer="handleLoadNewer"
        @jump-to-latest="handleJumpToLatest"
      />
      <TypingIndicator :typing-users="typingUsers" />
      <MessageEditor
        v-if="!isArchived"
        ref="editorRef"
        :disabled="messagesUIFlags.isSending"
        :editing-message="editingMessage"
        @send="handleSend"
        @typing="handleTyping"
        @draft-update="handleDraftUpdate"
        @create-poll="handleCreatePoll"
        @cancel-edit="handleCancelEdit"
      />
      <div
        v-else
        class="border-t border-n-slate-5 bg-n-solid-2 px-4 py-3 text-center text-sm text-n-slate-10"
      >
        {{ t('INTERNAL_CHAT.CHANNEL.ARCHIVED') }}
      </div>
    </div>

    <ThreadPanel
      v-if="activeThread"
      ref="threadPanelRef"
      :channel-id="channelId"
      :parent-message="activeThread"
      :current-user-id="currentUserId"
      :is-admin="isAdmin"
      :highlight-message-id="threadHighlightMessageId"
      @close="closeThread"
    />

    <ChannelSettings
      v-if="showSettings"
      ref="channelSettingsRef"
      :channel="channel"
      :current-user-id="currentUserId"
      :is-admin="isAdmin"
      @close="handleToggleSettings"
      @archive="handleArchive"
      @unarchive="handleUnarchive"
      @delete="handleDeleteChannel"
      @mute="handleToggleMute"
      @unmute="handleToggleMute"
      @favorite="handleToggleFavorite"
      @unfavorite="handleToggleFavorite"
      @close-dm="handleCloseDM"
      @edit-members="editMembersRef?.open()"
    />

    <PollCreator ref="pollCreatorRef" @submit="handlePollSubmit" />
    <ProFeatureNudge ref="proNudgeRef" :feature="proNudgeFeature" />
    <EditMembersModal
      ref="editMembersRef"
      :channel-id="channelId"
      @updated="channelSettingsRef?.fetchMembers()"
    />
  </div>
</template>
