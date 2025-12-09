<script setup>
import { ref, onMounted, computed, watch, useTemplateRef } from 'vue';
import Message from 'next/message/Message.vue';
import TypingIndicator from 'next/message/TypingIndicator.vue';
import shouldGroupWithNext from 'next/message/groupWithNext';
import Snipper from 'next/spinner/Spinner.vue';
import LiteReplyBox from './LiteReplyBox.vue';
import {
  useStore,
  useMapGetter,
  useFunctionGetter,
  //
} from '../dashboard/composables/store';
import { getTypingUsersText } from '../dashboard/helper/commons';
import { useCamelCase } from '../dashboard/composables/useTransformKeys';
import { useInfiniteScroll, useThrottleFn } from '@vueuse/core';
import { useI18n } from 'vue-i18n';

const conversationId = computed(() => {
  // eslint-disable-next-line no-underscore-dangle
  return window.__WOOT_CONVERSATION_ID__;
});

const { t } = useI18n();

const messageListRef = useTemplateRef('messageListRef');
const store = useStore();
const isAllLoaded = useMapGetter('getAllMessagesLoaded');
const isFetching = ref(false);

const typingUserList = useFunctionGetter(
  'conversationTypingStatus/getUserList',
  conversationId.value
);

const isAnyoneTyping = computed(() => {
  return typingUserList.value.length > 0;
});

const typingUserNames = computed(() => {
  if (!isAnyoneTyping.value) return '';
  const [i18nKey, params] = getTypingUsersText(typingUserList.value);
  // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
  return t(i18nKey, params);
});

const conversation = computed(() => {
  return store.getters.getConversationById(conversationId.value);
});

const allMessages = computed(() => {
  if (!conversation.value) return [];

  return useCamelCase(conversation.value.messages, { deep: true }).reverse();
});

const fetchMore = async () => {
  if (isFetching.value) return;
  if (!conversation?.value?.id) return;
  if (!allMessages.value?.length) return;

  try {
    isFetching.value = true;

    await store.dispatch('fetchPreviousMessages', {
      conversationId: conversation.value.id,
      before: allMessages.value[allMessages.value.length - 1].id,
    });
  } finally {
    isFetching.value = false;
  }
};

onMounted(async () => {
  await store.dispatch('inboxes/get');
  await Promise.all([
    store.dispatch('getConversation', conversationId.value),
    store.dispatch('fetchAllAttachments', conversationId.value),
  ]);
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
      class="px-4 pt-4 flex flex-col-reverse pb-60 bg-n-background overflow-scroll h-screen"
    >
      <div
        v-if="isAnyoneTyping"
        id="conversationFooter"
        class="my-2 py-2 flex items-center w-full"
      >
        <div
          class="flex py-2 px-4 shadow-md rounded-full bg-white dark:bg-slate-700 text-n-slate-11 text-xs font-semibold mx-auto items-center gap-1"
        >
          {{ typingUserNames }}
          <TypingIndicator class="text-n-slate-9" />
        </div>
      </div>
      <template v-for="(message, index) in allMessages" :key="message.id">
        <Message
          v-bind="message"
          :is-email-inbox="false"
          :group-with-next="shouldGroupWithNext(index, allMessages)"
          :inbox-supports-reply-to="false"
        />
      </template>
      <div v-show="isFetching" class="w-full py-4">
        <Snipper class="mx-auto" />
      </div>
    </ul>
    <div class="p-2 w-full bg-white absolute bottom-0">
      <LiteReplyBox />
    </div>
  </div>
</template>

<style>
/* this will disable elastic scrolling on the y axis  */
* {
  overscroll-behavior-y: none;
}
</style>
