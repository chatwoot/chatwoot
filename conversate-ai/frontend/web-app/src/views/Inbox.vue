<template>
  <div class="inbox-view">
    <div class="conversation-panel">
      <ConversationList />
    </div>
    <div class="chat-panel">
      <MessageFeed />
      <MessageInput />
    </div>
  </div>
</template>

<script setup>
import ConversationList from '../components/ConversationList.vue';
import MessageFeed from '../components/MessageFeed.vue';
import MessageInput from '../components/MessageInput.vue';

// In the future, this view will manage the currently selected conversation
// and pass the relevant data down to its child components as props.
</script>

<style scoped>
.inbox-view {
  display: flex;
  height: 100%;
  width: 100%;
}
.conversation-panel {
  width: 320px;
  flex-shrink: 0;
  height: 100%;
}
.chat-panel {
  flex-grow: 1;
  display: flex;
  flex-direction: column;
  height: 100%;
}
</style>
