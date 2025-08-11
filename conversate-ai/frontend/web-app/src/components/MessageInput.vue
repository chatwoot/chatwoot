<template>
  <div class="message-input-area">
    <textarea
      v-model="message"
      placeholder="Type your message here..."
      @keydown.enter.prevent="handleSend"
      :disabled="!activeConversationId"
    ></textarea>
    <button @click="handleSend" :disabled="!message.trim() || !activeConversationId">Send</button>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { useConversationStore } from '../store/conversations';

const store = useConversationStore();
const message = ref('');

const activeConversationId = computed(() => store.activeConversationId);

const handleSend = () => {
  if (message.value.trim()) {
    store.sendMessage(message.value);
    message.value = '';
  }
};
</script>

<style scoped>
/* Styles are unchanged, but re-included for completeness */
.message-input-area {
  display: flex;
  padding: 1rem;
  border-top: 1px solid #e0e0e0;
  background-color: #f9f9f9;
}
textarea {
  flex-grow: 1;
  border-radius: 18px;
  padding: 0.75rem;
  border: 1px solid #ccc;
  resize: none;
  font-family: inherit;
  font-size: 1rem;
  margin-right: 1rem;
}
button {
  padding: 0.5rem 1.5rem;
  border: none;
  background-color: #007bff;
  color: white;
  border-radius: 18px;
  cursor: pointer;
  font-size: 1rem;
  transition: background-color 0.2s;
}
button:hover {
  background-color: #0056b3;
}
button:disabled {
  background-color: #a0cfff;
  cursor: not-allowed;
}
</style>
