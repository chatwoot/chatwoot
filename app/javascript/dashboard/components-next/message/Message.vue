<script setup>
import { computed } from 'vue';

import {
  MESSAGE_TYPES,
  MESSAGE_VARIANTS,
  SENDER_TYPES,
  ORIENTATION,
  MESSAGE_STATUS,
} from './constants';

import Avatar from 'next/avatar/Avatar.vue';

import TextBubble from './bubbles/Text.vue';

import MessageError from './MessageError.vue';
import MessageMeta from './MessageMeta.vue';

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
 * @typedef {Object} ContentAttributes
 * @property {string} externalError - an error message to be shown if the message failed to send
 */

/**
 * @typedef {Object} Props
 * @property {number} id - The unique identifier for the message
 * @property {number} messageType - The type of message (must be one of MESSAGE_TYPES)
 * @property {('sent'|'delivered'|'read'|'failed')} status - The delivery status of the message
 * @property {boolean} [private=false] - Whether the message is private
 * @property {number} createdAt - Timestamp when the message was created
 * @property {Sender|null} [sender=null] - The sender information
 * @property {ContentAttributes} [contentAttributes={}] - Additional attributes of the message content
 * @property {number|null} [senderId=null] - The ID of the sender
 * @property {string|null} [senderType=null] - The type of the sender
 * @property {string|null} [error=null] - Error message if the message failed to send
 * @property {string} content - The message content
 * @property {number} currentUserId - The ID of the current user
 */

const props = defineProps({
  id: { type: Number, required: true },
  messageType: {
    type: Number,
    required: true,
    validator: value => Object.values(MESSAGE_TYPES).includes(value),
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
  sender: {
    type: Object,
    default: null,
  },
  senderId: {
    type: Number,
    default: null,
  },
  senderType: {
    type: String,
    default: null,
  },
  content: {
    type: String,
    required: true,
  },
  contentAttributes: {
    type: Object,
    default: () => {},
  },
  currentUserId: {
    type: Number,
    required: true,
  },
  groupWithNext: {
    type: Boolean,
    default: false,
  },
});

/**
 * Computes the message variant based on props
 * @type {import('vue').ComputedRef<'user'|'agent'|'activity'|'private'|'bot'|'template'>}
 */
const variant = computed(() => {
  if (props.private) return MESSAGE_VARIANTS.PRIVATE;
  if (props.status === MESSAGE_STATUS.FAILED) return MESSAGE_VARIANTS.ERROR;

  const variants = {
    [MESSAGE_TYPES.INCOMING]: MESSAGE_VARIANTS.USER,
    [MESSAGE_TYPES.ACTIVITY]: MESSAGE_VARIANTS.ACTIVITY,
    [MESSAGE_TYPES.OUTGOING]: MESSAGE_VARIANTS.AGENT,
    [MESSAGE_TYPES.TEMPLATE]: MESSAGE_VARIANTS.TEMPLATE,
  };

  return variants[props.messageType] || MESSAGE_VARIANTS.USER;
});

const isMyMessage = computed(() => {
  const senderId = props.senderId ?? props.sender?.id;

  return (
    props.senderType === SENDER_TYPES.USER && props.currentUserId === senderId
  );
});

/**
 * Computes the message orientation based on sender type and message type
 * @returns {import('vue').ComputedRef<'left'|'right'|'center'>} The computed orientation
 */
const orientation = computed(() => {
  if (isMyMessage.value) {
    return ORIENTATION.RIGHT;
  }

  if (props.messageType === MESSAGE_TYPES.ACTIVITY) return ORIENTATION.CENTER;

  return ORIENTATION.LEFT;
});

const flexOrientationClass = computed(() => {
  const map = {
    [ORIENTATION.LEFT]: 'justify-start',
    [ORIENTATION.RIGHT]: 'justify-end',
    [ORIENTATION.CENTER]: 'justify-center',
  };

  return map[orientation.value];
});

const gridClass = computed(() => {
  const map = {
    [ORIENTATION.LEFT]: 'grid grid-cols-[24px_1fr]',
    [ORIENTATION.RIGHT]: 'grid grid-cols-1fr',
  };

  return map[orientation.value];
});

const gridTemplate = computed(() => {
  const map = {
    [ORIENTATION.LEFT]: `
      "avatar bubble"
      "spacer meta"
    `,
    [ORIENTATION.RIGHT]: `
      "bubble"
      "meta"
    `,
  };

  return map[orientation.value];
});

const shouldGroupWithNext = computed(() => {
  if (props.status === MESSAGE_STATUS.FAILED) return false;

  return props.groupWithNext;
});

const shouldShowAvatar = computed(() => {
  if (props.messageType === MESSAGE_TYPES.ACTIVITY) return false;
  if (orientation.value === ORIENTATION.RIGHT) return false;

  return true;
});
</script>

<template>
  <div
    class="flex w-full"
    :class="[flexOrientationClass, shouldGroupWithNext ? 'mb-2' : 'mb-4']"
  >
    <div v-if="variant === MESSAGE_VARIANTS.ACTIVITY">
      <TextBubble v-bind="props" :variant :orientation />
    </div>
    <div
      v-else
      :class="[gridClass, { 'gap-y-2': !shouldGroupWithNext }]"
      class="gap-x-3"
      :style="{
        gridTemplateAreas: gridTemplate,
      }"
    >
      <div
        v-if="!shouldGroupWithNext && shouldShowAvatar"
        class="[grid-area:avatar] flex items-end"
      >
        <Avatar :name="sender ? sender.name : ''" src="" :size="24" />
      </div>
      <TextBubble
        v-bind="props"
        :variant
        :orientation
        class="[grid-area:bubble]"
      />
      <MessageError
        v-if="contentAttributes.externalError"
        class="[grid-area:meta]"
        :class="flexOrientationClass"
        :error="contentAttributes.externalError"
      />
      <MessageMeta
        v-else-if="!shouldGroupWithNext"
        class="[grid-area:meta]"
        :class="flexOrientationClass"
        :sender="props.sender"
        :status="props.status"
        :private="props.private"
        :is-my-message="isMyMessage"
        :created-at="props.createdAt"
      />
    </div>
  </div>
</template>
