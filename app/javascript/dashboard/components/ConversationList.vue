<script setup>
import { computed, provide, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVirtualizer } from '@tanstack/vue-virtual';
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

// Virtual scrolling configuration
const virtualizerOptions = computed(() => ({
  count: props.items.length,
  getScrollElement: () => parentRef.value,
  // Accurate size estimate reduces scroll jumps
  estimateSize: () => 100,
  // Balanced overscan for smooth scrolling without performance hit
  overscan: 4,
  // Stable keys for optimal Vue reconciliation
  getItemKey: index => props.items[index]?.uuid || index,
  // Wrap ResizeObserver in RAF to reduce layout thrashing
  useAnimationFrameWithResizeObserver: true,
  // Fix for backward scroll stutter
  shouldAdjustScrollPositionOnItemSizeChange: (item, delta, instance) => {
    return instance.scrollDirection === 'backward';
  },
}));

const rowVirtualizer = useVirtualizer(virtualizerOptions);

const virtualRows = computed(() => rowVirtualizer.value.getVirtualItems());
const totalSize = computed(() => rowVirtualizer.value.getTotalSize());

const measureElement = el => {
  if (!el) return;
  rowVirtualizer.value.measureElement(el);
};

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

  const allConversations = Array.from(
    parentRef.value.querySelectorAll('[data-index] > div')
  );

  if (allConversations.length === 0) return;

  const activeIndex = allConversations.findIndex(conv =>
    conv.classList.contains('active')
  );

  const delta = direction === 'previous' ? -1 : 1;
  const newIndex = activeIndex + delta;

  // Clamp index to valid range [0, length-1]
  const targetIndex = Math.max(
    0,
    Math.min(newIndex, allConversations.length - 1)
  );

  allConversations[targetIndex]?.click();
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
    class="conversation-list flex-1 w-full h-full px-2 touch-pan-y overscroll-contain [-webkit-overflow-scrolling:touch] [contain:strict] pt-2"
    :class="isContextMenuOpen ? 'overflow-hidden' : 'overflow-y-auto'"
  >
    <div class="relative w-full" :style="{ height: `${totalSize}px` }">
      <div
        v-for="virtualRow in virtualRows"
        :key="virtualRow.key"
        :ref="measureElement"
        :data-index="virtualRow.index"
        class="absolute top-0 ltr:left-0 rtl:right-0 w-full will-change-transform after:content-[''] after:absolute after:bottom-0 after:left-0 after:right-0 after:h-px after:bg-n-weak after:pointer-events-none after:transition-colors after:duration-150 hover:after:bg-n-surface-1 has-[.active]:after:bg-n-surface-1 has-[+_:hover]:after:bg-n-surface-1 has-[+_*_.active]:after:bg-n-surface-1"
        :style="{ transform: `translate3d(0, ${virtualRow.start}px, 0)` }"
      >
        <ConversationItem
          :source="items[virtualRow.index]"
          :label="label"
          :team-id="teamId"
          :folders-id="foldersId"
          :conversation-type="conversationType"
          :show-assignee="showAssignee"
          :is-expanded-layout="isExpandedLayout"
        />
      </div>
    </div>

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
