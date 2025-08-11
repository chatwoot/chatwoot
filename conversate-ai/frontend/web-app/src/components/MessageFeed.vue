<template>
  <div class="message-feed">
    <div class="feed-header">
      <h4>Chat with {{ activeConversationId || '...' }}</h4>
    </div>
    <div class="feed-body" ref="feedBodyRef">
      <div v-if="isLoading">Loading messages...</div>
      <div v-else-if="!activeConversationId">Select a conversation to start chatting.</div>
      <div v-else v-for="message in messages" :key="message.id"
           class="message-group"
           :class="{ outgoing: message.sender_type === 'user', incoming: message.sender_type !== 'user' }">
        <div class="message-bubble">
          <p>{{ message.content }}</p>
          <div class="timestamp">{{ new Date(message.created_at).toLocaleTimeString() }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, watch, nextTick } from 'vue';
import { useConversationStore } from '../store/conversations';

const store = useConversationStore();
const feedBodyRef = ref(null);

const messages = computed(() => store.activeConversationMessages);
const activeConversationId = computed(() => store.activeConversationId);
const isLoading = computed(() => store.isLoading);

const scrollToBottom = () => {
  nextTick(() => {
    const feedBody = feedBodyRef.value;
    if (feedBody) {
      feedBody.scrollTop = feedBody.scrollHeight;
    }
  });
};

// Watch for new messages and scroll to the bottom
watch(messages, () => {
  scrollToBottom();
}, { deep: true });

// Also scroll when the conversation changes
watch(activeConversationId, () => {
  scrollToBottom();
});

</script>

<style scoped>
/* Styles are unchanged, but re-included for completeness */
.message-feed {
  display: flex;
  flex-direction: column;
  height: 100%;
}
.feed-header {
  padding: 1rem;
  border-bottom: 1px solid #e0e0e0;
}
.feed-body {
  flex-grow: 1;
  padding: 1rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
}
.message-group {
  display: flex;
  margin-bottom: 1rem;
}
.message-group.incoming {
  justify-content: flex-start;
}
.message-group.outgoing {
  justify-content: flex-end;
}
.message-bubble {
  max-width: 70%;
  padding: 0.75rem;
  border-radius: 18px;
  color: white;
}
.message-group.incoming .message-bubble {
  background-color: #007bff;
  border-top-left-radius: 4px;
}
.message-group.outgoing .message-bubble {
  background-color: #28a745;
  border-top-right-radius: 4px;
}
.message-bubble p {
  margin: 0;
}
.timestamp {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.7);
  text-align: right;
  margin-top: 0.25rem;
}
</style>
