<template>
  <div class="conversation-list">
    <div class="list-header">
      <h3>Conversations</h3>
    </div>
    <div class="list-body">
      <div
        v-for="conversation in conversations"
        :key="conversation.id"
        class="conversation-item"
        :class="{ active: conversation.id === activeConversationId }"
        @click="selectConversation(conversation.id)"
      >
        <div class="item-avatar">{{ conversation.participants[0].name.charAt(0) }}</div>
        <div class="item-details">
          <div class="item-name">{{ conversation.participants[0].name }}</div>
          <div class="item-preview">Placeholder for last message...</div>
        </div>
      </div>
      <div v-if="isLoading" class="loading">Loading...</div>
      <div v-if="error" class="error">{{ error }}</div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, computed } from 'vue';
import { useConversationStore } from '../store/conversations';

const store = useConversationStore();

const conversations = computed(() => store.conversations);
const activeConversationId = computed(() => store.activeConversationId);
const isLoading = computed(() => store.isLoading);
const error = computed(() => store.error);

onMounted(() => {
  store.fetchConversations();
});

const selectConversation = (conversationId) => {
  store.setActiveConversation(conversationId);
};
</script>

<style scoped>
/* Styles are unchanged, but re-included for completeness */
.conversation-list {
  border-right: 1px solid #e0e0e0;
  height: 100%;
  display: flex;
  flex-direction: column;
}
.list-header {
  padding: 1rem;
  border-bottom: 1px solid #e0e0e0;
}
.list-body {
  overflow-y: auto;
  flex-grow: 1;
}
.conversation-item {
  display: flex;
  align-items: center;
  padding: 1rem;
  cursor: pointer;
  border-bottom: 1px solid #e0e0e0;
}
.conversation-item:hover {
  background-color: #f5f5f5;
}
.conversation-item.active {
  background-color: #e0f7fa;
}
.item-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background-color: #007bff;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  margin-right: 1rem;
}
.item-details {
  overflow: hidden;
}
.item-name {
  font-weight: bold;
}
.item-preview {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  color: #666;
  font-size: 0.9rem;
}
.loading, .error {
  text-align: center;
  padding: 1rem;
  color: #666;
}
</style>
