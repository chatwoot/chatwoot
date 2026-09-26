<script setup>
import { onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { getContrastingTextColor } from '@chatwoot/utils';
import { useStore, useMapGetter } from 'dashboard/composables/store.js';
import Spinner from 'shared/components/Spinner.vue';
import ConversationListItem from 'widget/components/ConversationListItem.vue';

const store = useStore();
const router = useRouter();

const conversations = useMapGetter('conversationList/getRecords');
const hasNextPage = useMapGetter('conversationList/getHasNextPage');
const isFetching = useMapGetter('conversationList/getIsFetching');
const widgetColor = useMapGetter('appConfig/getWidgetColor');

const { preChatFormEnabled } = window.chatwootWebChannel;
const LOAD_MORE_THRESHOLD_PX = 160;

onMounted(() => store.dispatch('conversationList/fetch'));

const onScroll = ({ target }) => {
  const remaining =
    target.scrollHeight - target.scrollTop - target.clientHeight;
  if (remaining < LOAD_MORE_THRESHOLD_PX) {
    store.dispatch('conversationList/fetchMore');
  }
};

const openConversation = async id => {
  await store.dispatch('conversationList/open', id);
  router.replace({ name: 'messages' });
};

const startNewConversation = async () => {
  await store.dispatch('conversationList/startNew');
  router.replace({ name: preChatFormEnabled ? 'prechat-form' : 'messages' });
};
</script>

<template>
  <div class="relative flex flex-col flex-1 overflow-hidden">
    <div class="flex-1 p-4 overflow-auto pb-40" @scroll="onScroll">
      <div
        v-if="isFetching && !conversations.length"
        class="flex justify-center py-8"
        role="status"
      >
        <Spinner />
      </div>
      <div
        v-else-if="!conversations.length"
        class="flex flex-col items-center gap-3 px-6 py-12 text-center"
      >
        <span
          class="flex items-center justify-center size-14 surface-card rounded-full"
        >
          <i
            class="i-lucide-messages-square size-6 text-n-slate-11"
            aria-hidden="true"
          />
        </span>
        <h2 class="font-medium text-n-slate-12">
          {{ $t('CONVERSATIONS.EMPTY_TITLE') }}
        </h2>
        <p class="text-sm text-n-slate-11">
          {{ $t('CONVERSATIONS.EMPTY_DESCRIPTION') }}
        </p>
      </div>
      <section v-else :aria-label="$t('CONVERSATIONS.TITLE')">
        <h2 class="px-1 pb-3 text-sm font-medium text-n-slate-11">
          {{ $t('CONVERSATIONS.TITLE') }}
        </h2>
        <ul class="flex flex-col gap-3">
          <li
            v-for="conversation in conversations"
            :key="conversation.id"
            class="overflow-hidden surface-card"
          >
            <ConversationListItem
              :conversation="conversation"
              class="px-4 py-2.5 transition-colors hover:bg-n-alpha-2"
              @select="openConversation"
            />
          </li>
        </ul>
        <div
          v-if="hasNextPage && isFetching"
          class="flex justify-center py-4"
          role="status"
        >
          <Spinner />
        </div>
      </section>
    </div>
    <div
      class="absolute inset-x-0 z-50 flex justify-center pointer-events-none bottom-20"
    >
      <button
        type="button"
        class="inline-flex items-center gap-2 px-4 py-2 text-base font-medium rounded-lg pointer-events-auto outline-none shadow-[0_0_24px_10px_rgb(var(--surface-1)/0.9),0_14px_28px_-10px_rgba(50,50,93,0.45),0_4px_10px_-4px_rgba(50,50,93,0.25)] dark:shadow-[0_0_24px_10px_rgb(var(--surface-1)/0.9),0_14px_28px_-10px_rgba(0,0,0,0.8),0_4px_10px_-4px_rgba(0,0,0,0.5)] focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-n-slate-7"
        :style="{
          backgroundColor: widgetColor,
          color: getContrastingTextColor(widgetColor),
        }"
        @click="startNewConversation"
      >
        <span>{{ $t('START_NEW_CONVERSATION') }}</span>
        <i class="i-lucide-pencil-line size-4" aria-hidden="true" />
      </button>
    </div>
  </div>
</template>
