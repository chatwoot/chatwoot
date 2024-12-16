<script setup>
import NextMessage from 'next/message/Message.vue';
import { defineProps } from 'vue';

/**
 * Props definition for the component
 * @typedef {Object} Props
 * @property {Array} readMessages - Array of read messages
 * @property {Array} unReadMessages - Array of unread messages
 * @property {Number} currentUserId - ID of the current user
 * @property {Boolean} isAnEmailChannel - Whether this is an email channel
 * @property {Object} inboxSupportsReplyTo - Inbox reply support configuration
 * @property {Array} messages - Array of all messages
 */
const props = defineProps({
  readMessages: {
    type: Array,
    default: () => [],
  },
  unReadMessages: {
    type: Array,
    default: () => [],
  },
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
  messages: {
    type: Array,
    default: () => [],
  },
});

/**
 * Determines if a message should be grouped with the next message
 * @param {Number} index - Index of the current message
 * @param {Array} messages - Array of messages to check
 * @returns {Boolean} - Whether the message should be grouped with next
 */
const shouldGroupWithNext = (index, messages) => {
  if (index === messages.length - 1) return false;

  const current = messages[index];
  const next = messages[index + 1];

  if (next.status === 'failed') return false;

  const nextSenderId = next.senderId ?? next.sender?.id;
  const currentSenderId = current.senderId ?? current.sender?.id;
  if (currentSenderId !== nextSenderId) return false;

  // Check if messages are in the same minute by rounding down to nearest minute
  return Math.floor(next.createdAt / 60) === Math.floor(current.createdAt / 60);
};

/**
 * Gets the message that was replied to
 * @param {Object} parentMessage - The message containing the reply reference
 * @returns {Object|null} - The message being replied to, or null if not found
 */
const getInReplyToMessage = parentMessage => {
  const emptyOption = null;

  if (!parentMessage) return emptyOption;

  const inReplyToMessageId =
    parentMessage.contentAttributes?.inReplyTo ??
    parentMessage.content_attributes?.in_reply_to;

  if (!inReplyToMessageId) return emptyOption;

  // Find in-reply-to message in the messages prop
  return props.messages?.find(message => message.id === inReplyToMessageId);
};
</script>

<template>
  <ul class="px-4 bg-n-background">
    <slot name="beforeAll" />
    <template v-for="(message, index) in readMessages" :key="message.id">
      <NextMessage
        v-bind="message"
        :is-email-inbox="isAnEmailChannel"
        :in-reply-to="getInReplyToMessage(message)"
        :group-with-next="shouldGroupWithNext(index, readMessages)"
        :inbox-supports-reply-to="inboxSupportsReplyTo"
        :current-user-id="currentUserId"
        data-clarity-mask="True"
      />
    </template>
    <slot name="beforeUnread" />
    <template v-for="(message, index) in unReadMessages" :key="message.id">
      <NextMessage
        v-bind="message"
        :in-reply-to="getInReplyToMessage(message)"
        :group-with-next="shouldGroupWithNext(index, unReadMessages)"
        :inbox-supports-reply-to="inboxSupportsReplyTo"
        :current-user-id="currentUserId"
        :is-email-inbox="isAnEmailChannel"
        data-clarity-mask="True"
      />
    </template>
    <slot name="after" />
  </ul>
</template>
