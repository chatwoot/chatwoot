<script setup>
import { computed, ref, onMounted, onBeforeUnmount } from 'vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { useI18n } from 'vue-i18n';

import MessageStatus from './MessageStatus.vue';
import MessageEditHistory from './MessageEditHistory.vue';
import Icon from 'next/icon/Icon.vue';
import { useInbox } from 'dashboard/composables/useInbox';
import { useMessageContext } from './provider.js';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

import { MESSAGE_STATUS, MESSAGE_TYPES } from './constants';

const {
  isAFacebookInbox,
  isALineChannel,
  isAPIInbox,
  isASmsInbox,
  isATelegramChannel,
  isATwilioChannel,
  isAWebWidgetInbox,
  isAWhatsAppChannel,
  isAnEmailChannel,
  isAnInstagramChannel,
  isATiktokChannel,
} = useInbox();

const {
  id,
  status,
  isPrivate,
  createdAt,
  sourceId,
  messageType,
  content,
  contentAttributes,
  shouldGroupWithNext,
} = useMessageContext();

const { t } = useI18n();

const editHistoryRef = ref(null);

const readableTime = computed(() =>
  messageTimestamp(createdAt.value, 'LLL d, h:mm a')
);

const showStatusIndicator = computed(() => {
  if (isPrivate.value) return false;
  // Don't show status for failed messages, we already show error message
  if (status.value === MESSAGE_STATUS.FAILED) return false;
  // Don't show status for deleted messages
  if (contentAttributes.value?.deleted) return false;

  if (messageType.value === MESSAGE_TYPES.OUTGOING) return true;
  if (messageType.value === MESSAGE_TYPES.TEMPLATE) return true;

  return false;
});

const isSent = computed(() => {
  if (!showStatusIndicator.value) return false;

  // Messages will be marked as sent for the Email channel if they have a source ID.
  if (isAnEmailChannel.value) return !!sourceId.value;

  if (
    isAWhatsAppChannel.value ||
    isATwilioChannel.value ||
    isAFacebookInbox.value ||
    isASmsInbox.value ||
    isATelegramChannel.value ||
    isAnInstagramChannel.value ||
    isATiktokChannel.value
  ) {
    return sourceId.value && status.value === MESSAGE_STATUS.SENT;
  }

  // API inbox messages use real sent/delivered/read status values from the external system.
  if (isAPIInbox.value) return status.value === MESSAGE_STATUS.SENT;

  // All messages will be mark as sent for the Line channel, as there is no source ID.
  if (isALineChannel.value) return true;

  return false;
});

const isDelivered = computed(() => {
  if (!showStatusIndicator.value) return false;

  if (
    isAWhatsAppChannel.value ||
    isATwilioChannel.value ||
    isASmsInbox.value ||
    isAFacebookInbox.value ||
    isAnInstagramChannel.value ||
    isATiktokChannel.value
  ) {
    return sourceId.value && status.value === MESSAGE_STATUS.DELIVERED;
  }
  // API inbox messages use real delivered status from the external system.
  if (isAPIInbox.value) return status.value === MESSAGE_STATUS.DELIVERED;
  // All messages marked as delivered for the web widget inbox once they are sent.
  if (isAWebWidgetInbox.value) {
    return status.value === MESSAGE_STATUS.SENT;
  }
  if (isALineChannel.value) {
    return status.value === MESSAGE_STATUS.DELIVERED;
  }

  return false;
});

const isRead = computed(() => {
  if (!showStatusIndicator.value) return false;

  if (
    isAWhatsAppChannel.value ||
    isATwilioChannel.value ||
    isAFacebookInbox.value ||
    isAnInstagramChannel.value ||
    isATiktokChannel.value
  ) {
    return sourceId.value && status.value === MESSAGE_STATUS.READ;
  }

  if (isAWebWidgetInbox.value || isAPIInbox.value) {
    return status.value === MESSAGE_STATUS.READ;
  }

  return false;
});

const statusToShow = computed(() => {
  if (isRead.value) return MESSAGE_STATUS.READ;
  if (isDelivered.value) return MESSAGE_STATUS.DELIVERED;
  if (isSent.value) return MESSAGE_STATUS.SENT;

  return MESSAGE_STATUS.PROGRESS;
});

const isEditableChannel = computed(
  () => isATelegramChannel.value || isAnInstagramChannel.value
);

const previousContents = computed(
  () => contentAttributes.value?.previousContents || []
);

const showEditedIndicator = computed(() => {
  if (!isEditableChannel.value) return false;
  if (contentAttributes.value?.deleted) return false;
  return previousContents.value.length > 0;
});

const latestEditedAt = computed(() => {
  if (!showEditedIndicator.value) return null;
  const last = previousContents.value[previousContents.value.length - 1];
  return last?.editedAt ?? null;
});

const showMeta = computed(
  () =>
    !shouldGroupWithNext.value ||
    isPrivate.value ||
    showEditedIndicator.value ||
    showStatusIndicator.value
);

const openEditHistory = () => {
  editHistoryRef.value?.open();
};

const handleOpenEditHistoryEvent = ({ messageId } = {}) => {
  if (!showEditedIndicator.value) return;
  if (messageId !== id.value) return;
  openEditHistory();
};

onMounted(() => {
  emitter.on(BUS_EVENTS.OPEN_MESSAGE_EDIT_HISTORY, handleOpenEditHistoryEvent);
});

onBeforeUnmount(() => {
  emitter.off(BUS_EVENTS.OPEN_MESSAGE_EDIT_HISTORY, handleOpenEditHistoryEvent);
});
</script>

<template>
  <div v-if="showMeta" class="text-xs flex items-center gap-1.5">
    <div v-if="!shouldGroupWithNext" class="inline">
      <time class="inline">{{ readableTime }}</time>
    </div>
    <Icon v-if="isPrivate" icon="i-lucide-lock-keyhole" class="size-3" />
    <button
      v-if="showEditedIndicator"
      v-tooltip.top="t('CONVERSATION.EDIT_HISTORY.EDITED_TOOLTIP')"
      type="button"
      class="inline-flex items-center gap-0.5 text-n-slate-11 hover:text-n-slate-12 cursor-pointer focus:outline-none"
      :aria-label="t('CONVERSATION.EDIT_HISTORY.EDITED')"
      @click="openEditHistory"
    >
      <Icon icon="i-lucide-pencil" class="size-3" />
      <span>{{ t('CONVERSATION.EDIT_HISTORY.EDITED') }}</span>
    </button>
    <MessageStatus v-if="showStatusIndicator" :status="statusToShow" />
    <MessageEditHistory
      v-if="showEditedIndicator"
      ref="editHistoryRef"
      :current-content="content"
      :current-edited-at="latestEditedAt"
      :previous-contents="previousContents"
    />
  </div>
</template>
