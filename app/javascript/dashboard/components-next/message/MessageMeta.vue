<script setup>
import { computed } from 'vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';

import MessageStatus from './MessageStatus.vue';
import Icon from 'next/icon/Icon.vue';
import { useInbox } from 'dashboard/composables/useInbox';

import { MESSAGE_STATUS, MESSAGE_TYPES } from './constants';

/**
 * @typedef {Object} Sender
 * @property {Object} additional_attributes - Additional attributes of the sender
 * @property {Object} custom_attributes - Custom attributes of the sender
 * @property {string} email - Email of the sender
 * @property {number} id - ID of the sender
 * @property {string|null} identifier - Identifier of the sender
 * @property {string} name - Name of the sender
 * @property {string|null} phone_number - Phone number of the sender
 * @property {string} thumbnail - Thumbnail URL of the sender
 * @property {string} type - Type of sender
 */

/**
 * @typedef {Object} Props
 * @property {('sent'|'delivered'|'read'|'failed')} status - The delivery status of the message
 * @property {boolean} [private=false] - Whether the message is private
 * @property {isMyMessage} [private=false] - Whether the message is sent by the current user or not
 * @property {number} createdAt - Timestamp when the message was created
 * @property {Sender|null} [sender=null] - The sender information
 */

const props = defineProps({
  sender: {
    type: [Object, null],
    required: true,
  },
  status: {
    type: String,
    required: true,
    validator: value => Object.values(MESSAGE_STATUS).includes(value),
  },
  private: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Number,
    required: true,
  },
  sourceId: {
    type: String,
    default: '',
  },
  messageType: {
    type: Number,
    required: true,
    validator: value => Object.values(MESSAGE_TYPES).includes(value),
  },
});

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
} = useInbox();

const readableTime = computed(() =>
  messageTimestamp(props.createdAt, 'LLL d, h:mm a')
);

const showSender = computed(() => !props.isMyMessage && props.sender);

const showStatusIndicator = computed(() => {
  if (props.private) return false;
  if (props.messageType === MESSAGE_TYPES.OUTGOING) return true;
  if (props.messageType === MESSAGE_TYPES.TEMPLATE) return true;

  return false;
});

const isSent = computed(() => {
  if (!showStatusIndicator.value) return false;

  // Messages will be marked as sent for the Email channel if they have a source ID.
  if (isAnEmailChannel.value) return !!props.sourceId;

  if (
    isAWhatsAppChannel.value ||
    isATwilioChannel.value ||
    isAFacebookInbox.value ||
    isASmsInbox.value ||
    isATelegramChannel.value
  ) {
    return props.sourceId && props.status === MESSAGE_STATUS.SENT;
  }

  // All messages will be mark as sent for the Line channel, as there is no source ID.
  if (props.isALineChannel) return true;

  return false;
});

const isDelivered = computed(() => {
  if (!showStatusIndicator.value) return false;

  if (
    isAWhatsAppChannel.value ||
    isATwilioChannel.value ||
    isASmsInbox.value ||
    isAFacebookInbox.value
  ) {
    return props.sourceId && props.status === MESSAGE_STATUS.DELIVERED;
  }
  // All messages marked as delivered for the web widget inbox and API inbox once they are sent.
  if (isAWebWidgetInbox.value || isAPIInbox.value) {
    return props.status === MESSAGE_STATUS.SENT;
  }
  if (isALineChannel.value) {
    return props.status === MESSAGE_STATUS.DELIVERED;
  }

  return false;
});

const isRead = computed(() => {
  if (!showStatusIndicator.value) return false;

  if (
    isAWhatsAppChannel.value ||
    isATwilioChannel.value ||
    isAFacebookInbox.value
  ) {
    return props.sourceId && props.status === MESSAGE_STATUS.READ;
  }

  if (isAWebWidgetInbox.value || isAPIInbox.value) {
    return props.status === MESSAGE_STATUS.READ;
  }

  return false;
});

const statusToShow = computed(() => {
  if (isRead.value) return MESSAGE_STATUS.READ;
  if (isDelivered.value) return MESSAGE_STATUS.DELIVERED;
  if (isSent.value) return MESSAGE_STATUS.SENT;

  return MESSAGE_STATUS.PROGRESS;
});
</script>

<template>
  <div class="text-xs text-n-slate-11 flex items-center gap-1.5">
    <div class="inline">
      <span v-if="showSender" class="inline capitalize">{{ sender.name }}</span>
      <span v-if="showSender && readableTime" class="inline"> • </span>
      <span class="inline">{{ readableTime }}</span>
    </div>
    <Icon
      v-if="props.private"
      icon="i-lucide-lock-keyhole"
      class="text-n-slate-10 size-3"
    />
    <MessageStatus v-if="showStatusIndicator" :status="statusToShow" />
  </div>
</template>
