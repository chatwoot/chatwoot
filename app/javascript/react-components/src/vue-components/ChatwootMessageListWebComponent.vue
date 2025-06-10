<script setup>
import { watch } from 'vue';
import MessageList from '../../../ui/MessageList.vue';

// Props that become Web Component attributes
const props = defineProps({
  conversationId: {
    type: [String, Number],
    required: true,
  },
});

function updateConversationId() {
  if (props.conversationId) {
    // eslint-disable-next-line no-underscore-dangle
    window.__WOOT_CONVERSATION_ID__ = Number(props.conversationId);
  }
}

// Watch for conversation ID changes
watch(
  () => props.conversationId,
  () => updateConversationId,
  {
    immediate: true,
  }
);
</script>

<template>
  <MessageList />
</template>

<style>
/* Import all necessary styles for the MessageList */
@import '../../../dashboard/assets/scss/app.scss';
@import 'vue-multiselect/dist/vue-multiselect.css';
@import 'floating-vue/dist/style.css';

.chatwoot-message-list-container {
  height: 100%;
  width: 100%;
  position: relative;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto,
    Oxygen-Sans, Ubuntu, Cantarell, 'Helvetica Neue', sans-serif;
}

.chatwoot-loading,
.chatwoot-error {
  height: 100%;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.chatwoot-message-list {
  height: 100%;
  width: 100%;
}

/* Ensure proper containment */
.chatwoot-message-list-container {
  contain: layout style;
}
</style>
