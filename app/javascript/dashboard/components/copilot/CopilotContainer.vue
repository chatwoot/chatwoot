<script setup>
import Copilot from 'dashboard/components-next/copilot/Copilot.vue';
import { useMapGetter } from 'dashboard/composables/store.js';
import { ref } from 'vue';
const currentUser = useMapGetter('getCurrentUser');

const messages = ref([]);

const isCaptainTyping = ref(false);

const sendMessage = message => {
  // Add user message
  messages.value.push({
    id: messages.value.length + 1,
    type: 'user',
    content: message,
  });

  // Simulate AI response
  isCaptainTyping.value = true;
  setTimeout(() => {
    isCaptainTyping.value = false;
    messages.value.push({
      id: messages.value.length + 1,
      type: 'assistant',
      content: 'This is a simulated AI response.',
    });
  }, 2000);
};
</script>

<template>
  <div class="border-n-weak border-l w-80">
    <Copilot
      :messages="messages"
      :support-agent="currentUser"
      :is-captain-typing="isCaptainTyping"
      @send-message="sendMessage"
    />
  </div>
</template>
