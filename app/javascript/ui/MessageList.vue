<script setup>
import { onMounted, computed, watch } from 'vue';
import Message from 'next/message/Message.vue';
import { useStore } from 'dashboard/composables/store';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';

const props = defineProps({
  conversationId: {
    type: Number,
    required: true,
  },
});

const store = useStore();

onMounted(() => {
  store.dispatch('getConversation', props.conversationId);
});

const conversation = computed(() => {
  return store.getters.getConversationById(props.conversationId);
});

const allMessages = computed(() => {
  if (!conversation.value) return [];

  return useCamelCase(conversation.value.messages);
});

watch(conversation, () => {
  store.dispatch('fetchPreviousMessages', {
    conversationId: conversation.value.id,
    before: allMessages.value[0].id,
  });
});
</script>

<template>
  <ul class="px-4 bg-n-background">
    <Message
      v-for="message in allMessages"
      :key="message.id"
      v-bind="message"
      :is-email-inbox="isAnEmailChannel"
      :group-with-next="false"
      :inbox-supports-reply-to="inboxSupportsReplyTo"
      :current-user-id="currentUserId"
    />
  </ul>
</template>
