<script setup>
import { ref, computed, watch, provide } from 'vue';
import { Virtualizer } from 'virtua/vue';
import { useBreakpoints } from '@vueuse/core';
import { useChatListKeyboardEvents } from 'dashboard/composables/chatlist/useChatListKeyboardEvents';
import ConversationItem from './ConversationItem.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import IntersectionObserver from 'dashboard/components/IntersectionObserver.vue';

import wootConstants from 'dashboard/constants/globals';

const props = defineProps({
  conversationList: { type: Array, default: () => [] },
  isLoading: { type: Boolean, default: false },
  showEndOfListMessage: { type: Boolean, default: false },
  label: { type: String, default: '' },
  teamId: { type: [String, Number], default: 0 },
  foldersId: { type: [String, Number], default: 0 },
  conversationType: { type: String, default: '' },
  showAssignee: { type: Boolean, default: false },
  isOnExpandedLayout: { type: Boolean, default: false },
  activeStatus: { type: String, default: 'open' },
});

const emit = defineEmits(['loadMore']);

const conversationListRef = ref(null);
const virtualListRef = ref(null);
const isContextMenuOpen = ref(false);

let initialResolvedIds = null;

const dismissedIds = ref(new Set());

provide('contextMenuElementTarget', virtualListRef);

const breakpoints = useBreakpoints({
  lg: wootConstants.LARGE_SCREEN_BREAKPOINT,
});
const isLgScreen = breakpoints.greaterOrEqual('lg');
const showExpandedCards = computed(
  () => props.isOnExpandedLayout && isLgScreen.value
);

useChatListKeyboardEvents(conversationListRef);

const intersectionObserverOptions = computed(() => ({
  root: conversationListRef.value,
  rootMargin: '100px 0px 100px 0px',
}));

const isOpenFilter = computed(() => props.activeStatus === 'open');

watch(
  () => props.conversationList,
  list => {
    if (initialResolvedIds !== null || list.length === 0) return;
    initialResolvedIds = new Set(
      list.filter(c => c.status === 'resolved').map(c => c.id)
    );
  },
  { immediate: true }
);

const visibleConversations = computed(() => {
  if (!isOpenFilter.value) return props.conversationList;

  const filtered = props.conversationList.filter(c => {
    if (c.status === 'resolved') {
      return c.resolved_by_contact === true && !dismissedIds.value.has(c.id);
    }
    return true;
  });

  return filtered.sort((a, b) => {
    const aResolved = a.status === 'resolved' ? 1 : 0;
    const bResolved = b.status === 'resolved' ? 1 : 0;
    return aResolved - bResolved;
  });
});

const onHideConversation = id => {
  dismissedIds.value = new Set([...dismissedIds.value, id]);
};

const onContextMenuToggle = state => {
  isContextMenuOpen.value = state;
};

const loadMoreConversations = () => {
  emit('loadMore');
};

provide('toggleContextMenu', onContextMenuToggle);

defineExpose({ conversationListRef });
</script>

<template>
  <div
    ref="conversationListRef"
    class="flex-1 min-h-0 overflow-y-auto conversations-list"
    :class="{ '!overflow-hidden': isContextMenuOpen }"
  >
    <Virtualizer
      ref="virtualListRef"
      v-slot="{ item }"
      :data="visibleConversations"
      class="[&>div:has(+_div_.active)>*]:!border-n-surface-1 [&>div:has(+_div_.selected)>*]:!border-n-surface-1"
    >
      <div
        :class="{
          'resolved-in-open bg-n-slate-3 dark:bg-n-slate-3':
            item.status === 'resolved' && isOpenFilter,
        }"
      >
        <ConversationItem
          :source="item"
          :label="label"
          :team-id="teamId"
          :folders-id="foldersId"
          :conversation-type="conversationType"
          :show-assignee="showAssignee"
          :show-expanded="showExpandedCards"
          :is-open-filter="isOpenFilter"
          @hide-conversation="onHideConversation"
        />
      </div>
    </Virtualizer>
    <div v-if="isLoading" class="flex justify-center my-4">
      <Spinner class="text-n-brand" />
    </div>
    <p v-else-if="showEndOfListMessage" class="p-4 text-center text-n-slate-11">
      {{ $t('CHAT_LIST.EOF') }}
    </p>
    <IntersectionObserver
      v-else
      :options="intersectionObserverOptions"
      @observed="loadMoreConversations"
    />
  </div>
</template>

<style scoped>
.resolved-in-open :deep(*) {
  color: #343434;
}

.dark .resolved-in-open :deep(*) {
  color: #e9e9e9;
}
</style>
