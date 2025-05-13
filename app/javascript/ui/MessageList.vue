<script setup>
import { ref, onMounted, computed, watch, useTemplateRef } from 'vue';
import Message from 'next/message/Message.vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { useInfiniteScroll, useThrottleFn } from '@vueuse/core';

const props = defineProps({
  conversationId: {
    type: Number,
    required: true,
  },
});

const messageListRef = useTemplateRef('messageListRef');
const store = useStore();
const isAllLoaded = useMapGetter('getAllMessagesLoaded');
const isFetching = ref(false);

const conversation = computed(() => {
  return store.getters.getConversationById(props.conversationId);
});

const allMessages = computed(() => {
  if (!conversation.value) return [];

  return useCamelCase(conversation.value.messages).reverse();
});

const fetchMore = () => {
  if (isFetching.value) return;
  if (!conversation?.value?.id) return;
  if (!allMessages.value?.length) return;
  try {
    isFetching.value = true;

    store.dispatch('fetchPreviousMessages', {
      conversationId: conversation.value.id,
      before: allMessages.value[allMessages.value.length - 1].id,
    });
  } finally {
    isFetching.value = false;
  }
};

onMounted(() => {
  store.dispatch('inboxes/get');
  store.dispatch('getConversation', props.conversationId);
});

watch(conversation, () => {
  store.dispatch('setActiveChat', {
    data: {
      id: conversation.value.id,
    },
  });
});

useInfiniteScroll(messageListRef, useThrottleFn(fetchMore, 1000), {
  canLoadMore: () => {
    return !isAllLoaded.value;
  },
  distance: 10,
  direction: 'top',
});
</script>

<template>
  <div class="relative">
    <ul
      ref="messageListRef"
      class="px-4 pt-4 flex flex-col-reverse pb-32 bg-n-background h-screen overflow-scroll"
    >
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
    <div class="p-2 w-full bg-white absolute bottom-0">
      <div
        class="w-full h-28 rounded-lg outline outline-1 outline-n-weak border-none"
      />
    </div>
  </div>
</template>
