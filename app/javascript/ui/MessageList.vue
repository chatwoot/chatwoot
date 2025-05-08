<script setup>
import Message from 'next/message/Message.vue';
import allMessages from 'next/message/fixtures/textWithMedia.js';

// const props = defineProps({
//   accountId: {
//     type: Number,
//     required: true,
//   },
//   conversationId: {
//     type: Number,
//     required: true,
//   },
//   token: {
//     type: String,
//     required: true,
//   },
// });
</script>

<template>
  <ul class="px-4 bg-n-background">
    <Message
      v-for="message in allMessages"
      :key="message.id"
      v-bind="message"
      :is-email-inbox="isAnEmailChannel"
      :group-with-next="false"
      :inbox-supports-reply-to="inboxSupportsReplyTo"
      :current-user-id="currentUserId"
    />
  </ul>
</template>
