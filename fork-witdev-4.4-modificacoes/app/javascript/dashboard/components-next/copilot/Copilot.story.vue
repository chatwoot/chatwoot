<script setup>
import { ref } from 'vue';
import Copilot from './Copilot.vue';

const supportAgent = {
  available_name: 'Pranav Raj',
  avatar_url:
    'https://app.chatwoot.com/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBd3FodGc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--d218a325af0ef45061eefd352f8efb9ac84275e8/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lKYW5CbFp3WTZCa1ZVT2hOeVpYTnBlbVZmZEc5ZlptbHNiRnNIYVFINk1BPT0iLCJleHAiOm51bGwsInB1ciI6InZhcmlhdGlvbiJ9fQ==--533c3ad7218e24c4b0e8f8959dc1953ce1d279b9/1707423736896.jpeg',
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
