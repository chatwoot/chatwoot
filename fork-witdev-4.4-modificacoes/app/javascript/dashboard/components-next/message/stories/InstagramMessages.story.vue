<script setup>
import Message from '../Message.vue';
import instagramConversation from '../fixtures/instagramConversation.js';

const messages = instagramConversation;

const shouldGroupWithNext = index => {
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

const getReplyToMessage = message => {
  const idToCheck = message.contentAttributes.inReplyTo;
  if (!idToCheck) return null;

  return messages.find(candidate => idToCheck === candidate.id);
};
</script>

<template>
  <Story title="Components/Messages/Instagram" :layout="{ type: 'single' }">
    <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
      <template v-for="(message, index) in messages" :key="message.id">
        <Message
          :current-user-id="1"
          :group-with-next="shouldGroupWithNext(index)"
          :in-reply-to="getReplyToMessage(message)"
          v-bind="message"
        />
      </template>
    </div>
  </Story>
</template>
