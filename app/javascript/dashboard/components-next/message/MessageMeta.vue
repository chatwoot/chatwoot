<script setup>
import { computed } from 'vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';

import MessageStatus from './MessageStatus.vue';
import Icon from 'next/icon/Icon.vue';

import { MESSAGE_STATUS } from './constants';

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
    type: Object,
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
  isMyMessage: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Number,
    required: true,
  },
});

const readableTime = computed(() =>
  messageTimestamp(props.createdAt, 'LLL d, h:mm a')
);

const showSender = computed(() => !props.isMyMessage && props.sender);
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
    <MessageStatus v-if="props.isMyMessage" :status />
  </div>
</template>
