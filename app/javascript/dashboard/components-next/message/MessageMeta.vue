<script setup>
import { computed } from 'vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import { useI18n } from 'vue-i18n';
import { useFunctionGetter } from 'dashboard/composables/store';

import MessageStatus from './MessageStatus.vue';
import Icon from 'next/icon/Icon.vue';
import { useInbox } from 'dashboard/composables/useInbox';
import { useMessageContext } from './provider.js';

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

const { t, locale } = useI18n();

const {
  status,
  isPrivate,
  createdAt,
  sourceId,
  messageType,
  contentAttributes,
  additionalAttributes,
  sender,
  currentUserId,
} = useMessageContext();

const readableTime = computed(() =>
  messageTimestamp(
    contentAttributes?.value?.externalCreatedAt ?? createdAt.value,
    'LLL d, h:mm a'
  )
);

const isScheduledMessage = computed(
  () => !!additionalAttributes.value?.scheduledMessageId
);
const scheduledBy = computed(() => additionalAttributes.value?.scheduledBy);
const scheduledById = computed(() => scheduledBy.value?.id);
const scheduledByType = computed(() =>
  scheduledBy.value?.type ? String(scheduledBy.value.type) : ''
);
const scheduledByTypeNormalized = computed(() =>
  scheduledByType.value.toLowerCase()
);
const scheduledByAgent = useFunctionGetter(
  'agents/getAgentById',
  scheduledById
);

const isScheduledByCurrentUser = computed(() => {
  if (!scheduledById.value || !currentUserId.value) return false;
  return Number(scheduledById.value) === Number(currentUserId.value);
});

const scheduledAt = computed(() => additionalAttributes.value?.scheduledAt);
const scheduledAtTimestamp = computed(() => {
  if (!scheduledAt.value) return null;
  return Math.floor(scheduledAt.value);
});

const scheduledAtLabel = computed(() => {
  if (!scheduledAtTimestamp.value) {
    return t('SCHEDULED_MESSAGES.ITEM.NO_SCHEDULE');
  }
  const date = new Date(scheduledAtTimestamp.value * 1000);
  const now = new Date();

  const options = {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  };

  if (date.getFullYear() !== now.getFullYear()) {
    options.year = 'numeric';
  }

  return date.toLocaleString(locale.value.replace('_', '-'), options);
});

const scheduledByLabel = computed(() => {
  if (!isScheduledMessage.value) return '';
  if (isScheduledByCurrentUser.value) {
    const userName = scheduledByAgent.value?.name;
    return t('SCHEDULED_MESSAGES.META.AUTHOR_YOU', { name: userName });
  }
  if (scheduledByTypeNormalized.value.includes('automation')) {
    const automationLabel = t('SCHEDULED_MESSAGES.META.AUTOMATION');
    if (scheduledBy.value?.name) {
      return `${scheduledBy.value.name} (${automationLabel})`;
    }
    return automationLabel;
  }
  if (scheduledByAgent.value?.name) {
    return scheduledByAgent.value.name;
  }
  if (sender.value?.name) {
    return sender.value.name;
  }
  return t('SCHEDULED_MESSAGES.META.UNKNOWN_AUTHOR');
});

const scheduledTooltip = computed(() => {
  if (!isScheduledMessage.value) return '';
  return t('SCHEDULED_MESSAGES.META.TOOLTIP', {
    time: scheduledAtLabel.value,
    author: scheduledByLabel.value,
  });
});

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
    isATiktokChannel.value
  ) {
    return sourceId.value && status.value === MESSAGE_STATUS.DELIVERED;
  }
  // All messages marked as delivered for the web widget inbox and API inbox once they are sent.
  if (isAWebWidgetInbox.value || isAPIInbox.value) {
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

const isEdited = computed(() => {
  return contentAttributes.value?.isEdited === true;
});

const previousContent = computed(() => {
  return contentAttributes.value?.previousContent || '';
});
</script>

<template>
  <div class="text-xs flex items-center gap-1.5">
    <div class="inline">
      <time class="inline">{{ readableTime }}</time>
    </div>
    <span
      v-if="isScheduledMessage"
      v-tooltip.top-start="{
        content: scheduledTooltip,
        delay: { show: 300, hide: 0 },
      }"
      class="inline-flex items-center gap-0.5"
    >
      <Icon icon="i-lucide-alarm-clock" class="size-3" />
    </span>
    <span
      v-if="isEdited"
      v-tooltip.top="{
        content: previousContent,
        delay: { show: 300, hide: 0 },
      }"
      class="inline-flex items-center gap-0.5"
    >
      <Icon icon="i-lucide-pencil" class="size-3" />
    </span>
    <Icon v-if="isPrivate" icon="i-lucide-lock-keyhole" class="size-3" />
    <MessageStatus v-if="showStatusIndicator" :status="statusToShow" />
  </div>
</template>
