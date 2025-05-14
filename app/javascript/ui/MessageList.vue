<script setup>
import { ref, onMounted, computed, watch, useTemplateRef } from 'vue';
import Message from 'next/message/Message.vue';
import ButtonNext from 'next/button/Button.vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { useInfiniteScroll, useThrottleFn } from '@vueuse/core';

const props = defineProps({
  conversationId: {
    type: Number,
    // eslint-disable-next-line no-underscore-dangle
    default: window.__WOOT_CONVERSATION_ID__,
  },
});

const messageListRef = useTemplateRef('messageListRef');
const store = useStore();
const isAllLoaded = useMapGetter('getAllMessagesLoaded');
const isFetching = ref(false);
const messageContent = ref('');

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

const isMessageEmpty = computed(() => {
  return !messageContent.value || !messageContent.value.trim();
});

const sendMessage = async () => {
  if (isMessageEmpty.value) return;

  try {
    await store.dispatch('createPendingMessageAndSend', {
      conversationId: conversation.value.id,
      message: messageContent.value,
      private: false,
      files: [],
      sourceId: null,
      ccEmails: [],
      bccEmails: [],
      editMessageId: null,
      type: 'incoming',
    });

    messageContent.value = '';
  } catch (error) {
    // Handle error
    // eslint-disable-next-line no-console
    console.error('Error sending message:', error);
  }
};
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
        id="replyInput"
        class="w-full rounded-xl outline outline-1 outline-n-weak border-none overflow-hidden"
      >
        <div class="flex flex-col p-2 gap-2">
          <textarea
            v-model="messageContent"
            rows="3"
            class="flex-grow p-2 !mb-0 resize-none"
            placeholder="Type your message..."
            @keydown.meta.enter.prevent="sendMessage"
            @keydown.ctrl.enter.prevent="sendMessage"
          />
          <div class="grid grid-cols-4">
            <div class="col-span-3" />
            <div class="col-span-1 flex justify-end">
              <ButtonNext
                sm
                blue
                label="Send"
                :disabled="isMessageEmpty"
                @click="sendMessage"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
