<script setup>
import { onMounted, computed, watch, useTemplateRef, nextTick } from 'vue';
import Message from 'next/message/Message.vue';
import { useStore } from 'dashboard/composables/store';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import {
  useScroll,
  useEventListener,
  useThrottleFn,
  useElementSize,
} from '@vueuse/core';

const props = defineProps({
  conversationId: {
    type: Number,
    required: true,
  },
});

const messageListRef = useTemplateRef('messageListRef');
const store = useStore();
const { y } = useScroll(messageListRef);
const { height } = useElementSize(messageListRef);

const conversation = computed(() => {
  return store.getters.getConversationById(props.conversationId);
});

const allMessages = computed(() => {
  if (!conversation.value) return [];

  return useCamelCase(conversation.value.messages);
});

watch(conversation, async () => {
  store.dispatch('fetchPreviousMessages', {
    conversationId: conversation.value.id,
    before: allMessages.value[0].id,
  });
  await nextTick();
  y.value = height.value;
});

onMounted(() => {
  store.dispatch('getConversation', props.conversationId);
});

useEventListener(
  messageListRef,
  'scroll',
  useThrottleFn(() => {
    // eslint-disable-next-line no-console
    console.log('Testing');
    // if (top.value) {
    //   store.dispatch('fetchPreviousMessages', {
    //     conversationId: props.conversationId,
    //     before: allMessages.value[0].id,
    //   });
    // }
  }, 100)
);
</script>

<template>
  <ul ref="messageListRef" class="p-4 bg-n-background h-screen overflow-scroll">
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
