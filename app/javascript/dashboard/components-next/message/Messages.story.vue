<script setup>
import Message from './Message.vue';

const messages = [
  {
    variant: 'user',
    user: 'Elizabeth',
    text: 'Hey, the usual things I order is out of stock.',
    orientation: 'left',
  },
  {
    variant: 'system',
    text: 'Conversation auto-assigned to Stanley',
    orientation: 'center',
  },
  {
    variant: 'agent',
    user: 'Stanley',
    text: 'Hello Elizabeth, there was a recent change in our office supplies.',
    orientation: 'right',
  },
  {
    variant: 'private',
    user: 'Stanley',
    text: 'Should we give her a premium discount?',
    orientation: 'right',
  },
  {
    variant: 'private',
    user: 'Jim',
    text: 'They have placed multiple orders already, can go ahead. @Michael thoughts?',
    orientation: 'left',
  },
  {
    variant: 'private',
    user: 'Michael',
    text: 'Yes, let’s offer her a 20% discount',
    orientation: 'left',
  },
  {
    variant: 'agent',
    user: 'Stanley',
    text: 'If you want to buy our premium supplies, we can offer you a 20% discount! They come with indices and laser beams! ⚡',
    orientation: 'right',
  },
  {
    variant: 'user',
    user: 'Elizabeth',
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
      <Message v-for="message in messages" v-bind="message" />
    </div>
  </Story>
</template>
