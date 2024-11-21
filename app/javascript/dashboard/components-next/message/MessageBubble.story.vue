<script setup>
import MessageBubble from './MessageBubble.vue';

const messages = [
  {
    variant: 'system',
    text: 'Conversation auto-assigned to Stanley',
    orientation: 'center',
  },
  {
    variant: 'agent',
    text: 'Hello Elizabeth, there was a recent change in our office supplies.',
    orientation: 'right',
  },
  {
    variant: 'private',
    text: 'Should we give her a premium discount?',
    orientation: 'right',
  },
  {
    variant: 'private',
    text: 'They have placed multiple orders already, can go ahead. @Michael thoughts?',
    orientation: 'left',
  },
  {
    variant: 'private',
    text: 'Yes, let’s offer her a 20% discount',
    orientation: 'left',
  },
  {
    variant: 'agent',
    text: 'If you want to buy our premium supplies, we can offer you a 20% discount! They come with indices and laser beams! ⚡',
    orientation: 'right',
  },
  {
    variant: 'user',
    text: 'That’s great!',
    orientation: 'left',
  },
];
</script>

<template>
  <Story
    title="Components/Messages/Text"
    :layout="{ type: 'grid', width: '800' }"
  >
    <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid gap-4">
      <MessageBubble v-for="message in messages" v-bind="message" />
    </div>
  </Story>
</template>
