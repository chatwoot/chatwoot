<script setup>
import { computed, ref, watch, useSlots, useTemplateRef } from 'vue';
import {
  useElementBounding,
  useResizeObserver,
  useWindowSize,
} from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useKeyboardNavigableList } from 'dashboard/composables/useKeyboardNavigableList';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import PreviewPicker from './PreviewPicker.vue';

const props = defineProps({
  caretPosition: {
    type: Object,
    default: null,
  },
  items: {
    type: Array,
    required: true,
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
  emptyLabel: {
    type: String,
    default: '',
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select', 'close', 'removeTrigger']);

const search = defineModel('search', { type: String, default: '' });

const MIN_HEIGHT = 200;
const MAX_HEIGHT = 360;
const MAX_WIDTH = 768;
const LIST_ONLY_MAX_WIDTH = 420;
const VIEWPORT_MARGIN = 16;
const GAP = 8;
const SIDE_PREVIEW_MIN_WIDTH = 480;
const STACKED_PREVIEW_MIN_HEIGHT = 280;

const slots = useSlots();

const hasPreview = computed(() => Boolean(slots.preview));

const caretAnchorRef = useTemplateRef('caretAnchorRef');
const pickerRef = useTemplateRef('pickerRef');
const selectedIndex = ref(0);

const caretAnchor = useElementBounding(caretAnchorRef);
const { width: windowWidth, height: windowHeight } = useWindowSize();
const isRTL = useMapGetter('accounts/isRTL');

const items = computed(() => props.items);

const caretAnchorStyle = computed(() => ({
  top: `${props.caretPosition?.top ?? 0}px`,
  height: `${props.caretPosition?.height ?? 0}px`,
}));

useResizeObserver(
  () => caretAnchorRef.value?.parentElement,
  caretAnchor.update
);

const placement = computed(() => {
  const above = caretAnchor.top.value - VIEWPORT_MARGIN - GAP;
  const below =
    windowHeight.value - caretAnchor.bottom.value - VIEWPORT_MARGIN - GAP;
  const placeAbove = above > below;

  return {
    placeAbove,
    height: Math.min(MAX_HEIGHT, Math.max(placeAbove ? above : below, 0)),
  };
});

const width = computed(() =>
  Math.min(
    caretAnchor.width.value,
    hasPreview.value ? MAX_WIDTH : LIST_ONLY_MAX_WIDTH,
    windowWidth.value - VIEWPORT_MARGIN * 2
  )
);

const previewLayout = computed(() => {
  if (!hasPreview.value) return 'none';
  if (width.value >= SIDE_PREVIEW_MIN_WIDTH) return 'side';
  if (placement.value.height >= STACKED_PREVIEW_MIN_HEIGHT) return 'stacked';
  return 'none';
});

// Measured from the editor's inline start, which is its right edge in RTL. The teleported
// card carries `dir`, so `inset-inline-start` resolves to the matching physical side.
const inlineStart = computed(() =>
  isRTL.value
    ? windowWidth.value - caretAnchor.right.value
    : caretAnchor.left.value
);

const pickerStyle = computed(() => {
  const { placeAbove, height } = placement.value;
  const showsPreview = previewLayout.value !== 'none';
  const start = Math.min(
    inlineStart.value,
    windowWidth.value - width.value - VIEWPORT_MARGIN
  );

  return {
    insetInlineStart: `${Math.max(VIEWPORT_MARGIN, start)}px`,
    width: `${width.value}px`,
    maxHeight: `${height}px`,
    minHeight: showsPreview ? `${Math.min(MIN_HEIGHT, height)}px` : null,
    ...(placeAbove
      ? { bottom: `${windowHeight.value - caretAnchor.top.value + GAP}px` }
      : { top: `${caretAnchor.bottom.value + GAP}px` }),
  };
});

const adjustScroll = () => pickerRef.value?.scrollSelectedIntoView();

const onSelect = () => {
  const item = items.value[selectedIndex.value];
  if (item) emit('select', item);
};

const { moveSelectionUp, moveSelectionDown } = useKeyboardNavigableList({
  items,
  onSelect,
  adjustScroll,
  selectedIndex,
});

const withPicker = action => ({
  action: event => {
    event.preventDefault();
    action();
  },
  allowOnFocusedInput: true,
});

useKeyboardEvents({
  Tab: withPicker(moveSelectionDown),
  'Shift+Tab': withPicker(moveSelectionUp),
  Escape: withPicker(() => emit('close')),
  Backspace: {
    action: event => {
      if (search.value) return;
      event.preventDefault();
      emit('removeTrigger');
    },
    allowOnFocusedInput: true,
  },
});

const onListItemSelection = index => {
  selectedIndex.value = index;
  onSelect();
};

watch(items, () => {
  selectedIndex.value = 0;
  adjustScroll();
});
</script>

<template>
  <div
    ref="caretAnchorRef"
    class="absolute inset-x-0 pointer-events-none"
    :style="caretAnchorStyle"
  />
  <TeleportWithDirection to="body">
    <PreviewPicker
      ref="pickerRef"
      v-model:selected-index="selectedIndex"
      v-model:search="search"
      v-on-click-outside="() => emit('close')"
      :items="items"
      :search-placeholder="searchPlaceholder"
      :empty-label="emptyLabel"
      :is-loading="isLoading"
      :preview-layout="previewLayout"
      data-popover-content
      class="fixed z-[9999]"
      :style="pickerStyle"
      @select="onListItemSelection"
    >
      <template v-if="$slots.leading" #leading="slotProps">
        <slot name="leading" v-bind="slotProps" />
      </template>
      <template v-if="$slots.filters" #filters>
        <slot name="filters" />
      </template>
      <template v-if="hasPreview" #preview="slotProps">
        <slot name="preview" v-bind="slotProps" />
      </template>
    </PreviewPicker>
  </TeleportWithDirection>
</template>
