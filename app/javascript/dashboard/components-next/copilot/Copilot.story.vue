<script setup>
import { ref } from 'vue';
import Copilot from './Copilot.vue';

const supportAgent = {
  available_name: 'Pranav Raj',
  avatar_url: '',
};

const messages = ref([
  {
    id: 1,
    role: 'user',
    content: 'Hi there! How can I help you today?',
  },
  {
    id: 2,
    role: 'assistant',
    content:
      "Hello! I'm the AI assistant. I'll be helping the support team today.",
  },
]);

const isCaptainTyping = ref(false);

const sendMessage = message => {
  // Add user message
  messages.value.push({
    id: messages.value.length + 1,
    role: 'user',
    content: message,
  });

  // Simulate AI response
  isCaptainTyping.value = true;
  setTimeout(() => {
    isCaptainTyping.value = false;
    messages.value.push({
      id: messages.value.length + 1,
      role: 'assistant',
      content: 'This is a simulated AI response.',
    });
  }, 2000);
};
</script>

<template>
  <Story
    title="Captain/Copilot"
    :layout="{ type: 'grid', width: '400px', height: '800px' }"
  >
    <Copilot
      :support-agent="supportAgent"
      :messages="messages"
      :is-captain-typing="isCaptainTyping"
      @send-message="sendMessage"
    />
  </Story>
</template>
