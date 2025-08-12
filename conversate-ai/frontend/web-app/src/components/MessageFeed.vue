<template>
  <div class="message-feed">
    <div class="feed-header">
      <h4>Conversation with {{ activeConversationId || '...' }}</h4>
    </div>
    <div class="feed-body" ref="feedBodyRef">
      <div v-if="isLoading">Loading messages...</div>
      <div v-else-if="!activeConversationId">Select a conversation to start chatting.</div>
      <div v-else v-for="message in messages" :key="message.id"
           class="message-group"
           :class="getMessageClass(message.sender_type)">
        <div class="avatar" v-if="message.sender_type !== 'user'">
          {{ getAvatarInitial(message.sender_type) }}
        </div>
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

const getMessageClass = (senderType) => {
  if (senderType === 'user') return 'outgoing';
  return 'incoming';
};

const getAvatarInitial = (senderType) => {
    if (senderType === 'assistant') return 'AI';
    if (senderType === 'contact') return 'C';
    return '?';
}

const scrollToBottom = () => {
  nextTick(() => {
    const feedBody = feedBodyRef.value;
    if (feedBody) {
      feedBody.scrollTop = feedBody.scrollHeight;
    }
  });
};

watch(messages, () => {
  scrollToBottom();
}, { deep: true });

watch(activeConversationId, () => {
  scrollToBottom();
});
</script>

<style scoped>
.message-feed {
  display: flex;
  flex-direction: column;
  height: 100%;
}
.feed-header {
  padding: 1rem;
  border-bottom: 1px solid #e0e0e0;
  background-color: #fff;
  z-index: 1;
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
  max-width: 80%;
  align-items: flex-end;
}
.message-group.incoming {
  align-self: flex-start;
}
.message-group.outgoing {
  align-self: flex-end;
}
.avatar {
    width: 36px;
    height: 36px;
    border-radius: 50%;
    background-color: #ccc;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
    margin-right: 0.75rem;
    flex-shrink: 0;
}
.message-group .message-bubble {
  padding: 0.75rem 1rem;
  border-radius: 18px;
}
.message-group.incoming .message-bubble {
  background-color: #f0f2f5; /* Lighter grey for incoming */
  color: #333;
  border-top-left-radius: 4px;
}
.message-group.outgoing .message-bubble {
  background-color: #007bff; /* Blue for outgoing user */
  color: white;
  border-top-right-radius: 4px;
}
/* Differentiate AI messages */
.message-group.incoming .avatar {
    background-color: #6c757d; /* Grey for contact */
}
.message-group.incoming[data-sender-type="assistant"] .avatar {
    background-color: #17a2b8; /* Teal for AI */
}
.message-bubble p {
  margin: 0;
}
.timestamp {
  font-size: 0.75rem;
  color: #999;
  text-align: right;
  margin-top: 0.25rem;
}
.message-group.outgoing .timestamp {
    color: rgba(255, 255, 255, 0.8);
}
</style>
