<script setup>
import { provide, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { Virtualizer } from 'virtua/vue';
import { useInfiniteScroll } from '@vueuse/core';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import ConversationItem from './ConversationItem.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  items: { type: Array, default: () => [] },
  isLoading: { type: Boolean, default: false },
  showEndOfListMessage: { type: Boolean, default: false },
  isContextMenuOpen: { type: Boolean, default: false },
  label: { type: String, default: '' },
  teamId: { type: [String, Number], default: 0 },
  foldersId: { type: [String, Number], default: 0 },
  conversationType: { type: String, default: '' },
  showAssignee: { type: Boolean, default: false },
  isExpandedLayout: { type: Boolean, default: false },
});

const emit = defineEmits(['loadMore']);
const { t } = useI18n();

const parentRef = useTemplateRef('parentRef');

provide('contextMenuElementTarget', parentRef);

useInfiniteScroll(
  parentRef,
  () => {
    if (props.isLoading || props.showEndOfListMessage) return;
    emit('loadMore');
  },
  {
    distance: 400,
  }
);

// Keyboard navigation for conversation list
const handleConversationNavigation = direction => {
  if (!parentRef.value) return;

  // Get all wrapper divs with data-id
  const allWrappers = Array.from(parentRef.value.querySelectorAll('[data-id]'));

  if (allWrappers.length === 0) return;

  const activeIndex = allWrappers.findIndex(wrapper =>
    wrapper.querySelector('.active')
  );

  const delta = direction === 'previous' ? -1 : 1;
  const newIndex = activeIndex + delta;

  // Clamp index to valid range [0, length-1]
  const targetIndex = Math.max(0, Math.min(newIndex, allWrappers.length - 1));

  // Click the first child (ConversationItem root element)
  allWrappers[targetIndex]?.firstElementChild?.click();
};

useKeyboardEvents({
  'Alt+KeyJ': {
    action: () => handleConversationNavigation('previous'),
    allowOnFocusedInput: true,
  },
  'Alt+KeyK': {
    action: () => handleConversationNavigation('next'),
    allowOnFocusedInput: true,
  },
});
</script>

<template>
  <div
    ref="parentRef"
    class="conversation-list flex-1 w-full h-full touch-pan-y overscroll-contain [-webkit-overflow-scrolling:touch] [contain:strict] px-2 pt-2.5"
    :class="isContextMenuOpen ? 'overflow-hidden' : 'overflow-y-auto'"
  >
    <Virtualizer
      :data="items"
      class="[&>div]:after:content-[''] [&>div]:after:absolute [&>div]:after:bottom-0 [&>div]:after:left-0 [&>div]:after:right-0 [&>div]:after:h-px [&>div]:after:bg-n-weak [&>div]:after:pointer-events-none [&>div]:after:transition-colors [&>div]:after:duration-150 [&>div:has(*:hover)]:after:!bg-n-surface-1 [&>div:has(+_*:hover)]:after:!bg-n-surface-1 [&>div:has(.active)]:after:!bg-n-surface-1 [&>div:has(+_*_.active)]:after:!bg-n-surface-1 [&>div:has(.selected)]:after:!bg-n-surface-1 [&>div:has(+_*_.selected)]:after:!bg-n-surface-1"
    >
      <template #default="{ item }">
        <div :data-id="item.id">
          <ConversationItem
            :source="item"
            :label="label"
            :team-id="teamId"
            :folders-id="foldersId"
            :conversation-type="conversationType"
            :show-assignee="showAssignee"
            :is-expanded-layout="isExpandedLayout"
          />
        </div>
      </template>
    </Virtualizer>

    <div class="py-2">
      <div v-if="isLoading" class="flex justify-center my-4">
        <Spinner class="text-n-brand" />
      </div>
      <p
        v-else-if="showEndOfListMessage"
        class="p-4 text-center text-n-slate-11"
      >
        {{ t('CHAT_LIST.EOF') }}
      </p>
    </div>
  </div>
</template>

<style scoped>
.conversation-list {
  overflow-anchor: none;
}
</style>
