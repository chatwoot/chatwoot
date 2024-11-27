<script setup>
import { computed } from 'vue';

import {
  MESSAGE_TYPES,
  MESSAGE_VARIANTS,
  SENDER_TYPES,
  ORIENTATION,
} from './constants';

import TextBubble from './bubbles/Text.vue';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'next/icon/Icon.vue';

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
 * @property {number} id - The unique identifier for the message
 * @property {number} messageType - The type of message (must be one of MESSAGE_TYPES)
 * @property {('sent'|'delivered'|'read'|'failed')} status - The delivery status of the message
 * @property {boolean} [private=false] - Whether the message is private
 * @property {number} createdAt - Timestamp when the message was created
 * @property {Sender|null} [sender=null] - The sender information
 * @property {number|null} [senderId=null] - The ID of the sender
 * @property {string|null} [senderType=null] - The type of the sender
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
    validator: value => ['sent', 'delivered', 'read', 'failed'].includes(value),
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
  error: {
    type: String,
    default: '',
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
  if (props.error) return MESSAGE_VARIANTS.ERROR;

  const variants = {
    [MESSAGE_TYPES.INCOMING]: MESSAGE_VARIANTS.USER,
    [MESSAGE_TYPES.ACTIVITY]: MESSAGE_VARIANTS.ACTIVITY,
    [MESSAGE_TYPES.OUTGOING]: MESSAGE_VARIANTS.AGENT,
    [MESSAGE_TYPES.TEMPLATE]: MESSAGE_VARIANTS.TEMPLATE,
  };

  return variants[props.messageType] || MESSAGE_VARIANTS.USER;
});

/**
 * Computes the message orientation based on sender type and message type
 * @returns {import('vue').ComputedRef<'left'|'right'|'center'>} The computed orientation
 */
const orientation = computed(() => {
  if (
    props.senderType === SENDER_TYPES.USER &&
    props.currentUserId === props.senderId
  ) {
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
    [ORIENTATION.RIGHT]: 'grid grid-cols-[1fr_24px]',
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
      "bubble avatar"
      "meta spacer"
    `,
  };

  return map[orientation.value];
});

const shouldGroupWithNext = computed(() => {
  if (props.error) return false;

  return props.groupWithNext;
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
        v-if="!shouldGroupWithNext"
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
      <div
        v-if="error"
        class="[grid-area:meta] text-xs text-n-ruby-11 flex items-center gap-1.5"
        :class="flexOrientationClass"
      >
        <span>{{ 'Failed to send' }}</span>
        <div class="relative group">
          <div
            class="bg-n-alpha-2 rounded-sm size-5 grid place-content-center cursor-pointer"
          >
            <Icon
              icon="i-lucide-alert-triangle"
              class="text-n-ruby-11 size-[14px]"
            />
          </div>
          <div
            class="absolute bg-n-alpha-3 px-4 py-3 border rounded-xl border-n-strong text-n-slate-12 bottom-6 w-52 right-0 text-xs backdrop-blur-[100px] shadow-[0px_0px_24px_0px_rgba(0,0,0,0.12)] opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all"
          >
            {{ error }}
          </div>
        </div>
      </div>
      <div
        v-else-if="!shouldGroupWithNext"
        class="[grid-area:meta] text-xs text-n-slate-11 flex items-center gap-1.5"
        :class="flexOrientationClass"
      >
        <span>{{ sender ? sender.name + ' •' : '' }} {{ '1m ago' }}</span>
        <Icon
          v-if="variant === MESSAGE_VARIANTS.PRIVATE"
          icon="i-lucide-lock-keyhole"
          class="text-n-slate-10 size-3"
        />
      </div>
    </div>
  </div>
</template>
