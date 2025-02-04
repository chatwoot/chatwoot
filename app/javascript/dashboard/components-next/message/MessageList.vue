<script setup>
import { defineProps, computed } from 'vue';
import Message from './Message.vue';
import { MESSAGE_TYPES } from './constants.js';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';

/**
 * Props definition for the component
 * @typedef {Object} Props
 * @property {Array} readMessages - Array of read messages
 * @property {Array} unReadMessages - Array of unread messages
 * @property {Number} currentUserId - ID of the current user
 * @property {Boolean} isAnEmailChannel - Whether this is an email channel
 * @property {Object} inboxSupportsReplyTo - Inbox reply support configuration
 * @property {Array} messages - Array of all messages [These are not in camelcase]
 */
const props = defineProps({
  currentUserId: {
    type: Number,
    required: true,
  },
  isAnEmailChannel: {
    type: Boolean,
    default: false,
  },
  inboxSupportsReplyTo: {
    type: Object,
    default: () => ({ incoming: false, outgoing: false }),
  },
  lastSeenAt: {
    type: Number,
    default: 0,
  },
  messages: {
    type: Array,
    default: () => [],
  },
});

const allMessages = computed(() => {
  return useCamelCase(props.messages);
});

/**
 * Determines if a message should be grouped with the next message
 * @param {Number} index - Index of the current message
 * @param {Array} searchList - Array of messages to check
 * @returns {Boolean} - Whether the message should be grouped with next
 */
const shouldGroupWithNext = (index, searchList) => {
  if (index === searchList.length - 1) return false;

  const current = searchList[index];
  const next = searchList[index + 1];

  if (next.status === 'failed') return false;

  const nextSenderId = next.senderId ?? next.sender?.id;
  const currentSenderId = current.senderId ?? current.sender?.id;
  const hasSameSender = nextSenderId === currentSenderId;

  const nextMessageType = next.messageType;
  const currentMessageType = current.messageType;

  const areBothTemplates =
    nextMessageType === MESSAGE_TYPES.TEMPLATE &&
    currentMessageType === MESSAGE_TYPES.TEMPLATE;

  if (!hasSameSender || areBothTemplates) return false;

  if (currentMessageType !== nextMessageType) return false;

  // Check if messages are in the same minute by rounding down to nearest minute
  return Math.floor(next.createdAt / 60) === Math.floor(current.createdAt / 60);
};

/**
 * Gets the message that was replied to
 * @param {Object} parentMessage - The message containing the reply reference
 * @returns {Object|null} - The message being replied to, or null if not found
 */
const getInReplyToMessage = parentMessage => {
  if (!parentMessage) return null;

  const inReplyToMessageId =
    parentMessage.contentAttributes?.inReplyTo ??
    parentMessage.content_attributes?.in_reply_to;

  if (!inReplyToMessageId) return null;

  // Find in-reply-to message in the messages prop
  const replyMessage = props.messages?.find(
    message => message.id === inReplyToMessageId
  );

  return replyMessage ? useCamelCase(replyMessage) : null;
};

const isUnread = message => {
  return message.createdAt * 1000 > props.lastSeenAt * 1000;
};
</script>

<template>
  <ul class="px-4 bg-n-background next-messages-list">
    <slot name="beforeAll" />
    <template v-for="(message, index) in allMessages" :key="message.id">
      <Message
        v-bind="message"
        :class="{ 'is-unread': isUnread(message) }"
        :is-email-inbox="isAnEmailChannel"
        :in-reply-to="getInReplyToMessage(message)"
        :group-with-next="shouldGroupWithNext(index, allMessages)"
        :inbox-supports-reply-to="inboxSupportsReplyTo"
        :current-user-id="currentUserId"
        data-clarity-mask="True"
      />
    </template>
    <slot name="after" />
  </ul>
</template>

<style>
.message-bubble-container.is-unread:not(.is-unread ~ .is-unread) {
  margin-top: 3rem;
  position: relative;
}

.message-bubble-container.is-unread:not(.is-unread ~ .is-unread)::before {
  content: var(--unread-label-text, 'New Messages');
  position: absolute;
  top: -40px;
  left: 50%;
  font-size: 11px;
  color: rgb(var(--text-blue));
  background: rgb(var(--solid-blue));
  padding: 3px 8px;
  border-radius: 100px;
}
</style>
