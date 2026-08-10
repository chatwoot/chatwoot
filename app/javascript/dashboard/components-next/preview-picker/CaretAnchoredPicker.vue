<script setup>
import { computed, ref, watch, useTemplateRef } from 'vue';
import {
  useElementBounding,
  useResizeObserver,
  useWindowSize,
} from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
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
});

const emit = defineEmits(['select', 'close']);

const search = defineModel('search', { type: String, default: '' });

const MIN_HEIGHT = 200;
const MAX_HEIGHT = 300;
const MAX_WIDTH = 768;
const VIEWPORT_MARGIN = 16;
const GAP = 8;
const SIDE_PREVIEW_MIN_WIDTH = 480;
const STACKED_PREVIEW_MIN_HEIGHT = 260;

const caretAnchorRef = useTemplateRef('caretAnchorRef');
const pickerRef = useTemplateRef('pickerRef');
const selectedIndex = ref(0);

const caretAnchor = useElementBounding(caretAnchorRef);
const { width: windowWidth, height: windowHeight } = useWindowSize();

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

const previewLayout = computed(() => {
  if (caretAnchor.width.value >= SIDE_PREVIEW_MIN_WIDTH) return 'side';
  if (placement.value.height >= STACKED_PREVIEW_MIN_HEIGHT) return 'stacked';
  return 'none';
});

const pickerStyle = computed(() => {
  const { placeAbove, height } = placement.value;
  const showsPreview = previewLayout.value !== 'none';
  const width = Math.min(caretAnchor.width.value, MAX_WIDTH);
  const left = Math.min(
    caretAnchor.left.value,
    windowWidth.value - width - VIEWPORT_MARGIN
  );

  return {
    left: `${Math.max(VIEWPORT_MARGIN, left)}px`,
    width: `${width}px`,
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
      :preview-layout="previewLayout"
      data-popover-content
      class="fixed z-[9999]"
      :style="pickerStyle"
      @select="onListItemSelection"
    >
      <template v-if="$slots.leading" #leading="slotProps">
        <slot name="leading" v-bind="slotProps" />
      </template>
      <template #preview="slotProps">
        <slot name="preview" v-bind="slotProps" />
      </template>
    </PreviewPicker>
  </TeleportWithDirection>
</template>
