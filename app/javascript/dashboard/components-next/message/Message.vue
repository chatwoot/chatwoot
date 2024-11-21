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

// id: 5272,
// content: 'Hey, how are ya, I had a few questions about Chatwoot?',
// inbox_id: 475,
// conversation_id: 43,
// message_type: 0,
// content_type: 'text',
// status: 'sent',
// content_attributes: {
//   in_reply_to: null,
// },
// created_at: 1732195656,
// private: false,
// source_id: null,
// sender: {
//   additional_attributes: {},
//   custom_attributes: {},
//   email: 'hey@example.com',
//   id: 597,
//   identifier: null,
//   name: 'hey',
//   phone_number: null,
//   thumbnail: '',
//   type: 'contact',
// },
//

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
  currentUserId: {
    type: Number,
    required: true,
  },
});

const variant = computed(() => {
  if (props.private) {
    return MESSAGE_VARIANTS.PRIVATE;
  }

  if (props.messageType === MESSAGE_TYPES.INCOMING) {
    return MESSAGE_VARIANTS.USER;
  }

  if (props.messageType === MESSAGE_TYPES.ACTIVITY) {
    return MESSAGE_VARIANTS.ACTIVITY;
  }

  if (props.messageType === MESSAGE_TYPES.OUTGOING) {
    return MESSAGE_VARIANTS.AGENT;
  }

  if (props.messageType === MESSAGE_TYPES.TEMPLATE) {
    return MESSAGE_VARIANTS.TEMPLATE;
  }

  return MESSAGE_VARIANTS.USER;
});

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
</script>

<template>
  <div class="flex w-full" :class="flexOrientationClass">
    <div v-if="variant === MESSAGE_VARIANTS.ACTIVITY">
      <TextBubble v-bind="props" :variant :orientation />
    </div>
    <div
      v-else
      :class="gridClass"
      class="gap-x-3 gap-y-2 grid-area"
      :style="{
        gridTemplateAreas: gridTemplate,
      }"
    >
      <div class="[grid-area:avatar] flex items-end">
        <Avatar :name="sender ? sender.name : ''" src="" :size="24" />
      </div>
      <TextBubble
        v-bind="props"
        :variant
        :orientation
        class="[grid-area:bubble]"
      />
      <div
        class="[grid-area:meta] text-xs text-n-slate-11 flex items-center gap-1.5"
        :class="flexOrientationClass"
      >
        <span>{{ sender ? sender.name : '' }} {{ '• 1m ago' }}</span>
        <Icon
          v-if="variant === MESSAGE_VARIANTS.PRIVATE"
          icon="i-lucide-lock-keyhole"
          class="text-n-slate-10 size-3"
        />
      </div>
    </div>
  </div>
</template>
