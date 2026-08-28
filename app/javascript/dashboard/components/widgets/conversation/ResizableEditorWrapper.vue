<script setup>
import {
  ref,
  computed,
  provide,
  onMounted,
  onBeforeUnmount,
  useTemplateRef,
} from 'vue';
import { useEventListener } from '@vueuse/core';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

const props = defineProps({
  containerHeight: { type: Number, default: 0 },
});

const DEFAULT_HEIGHT = 120;
const MIN_HEIGHT = 80;
const MIN_MESSAGES_HEIGHT = 200;
const EXPAND_RATIO = 0.5;
const RESET_DELAY_MS = 120;

const wrapperRef = useTemplateRef('wrapperRef');
const surroundingHeight = ref(0);
const editorHeight = ref(DEFAULT_HEIGHT);
const isResizing = ref(false);
const startY = ref(0);
const startHeight = ref(0);
const requestedHeight = ref(0);
let resetTimeoutId = null;

const clamp = (val, min, max) => Math.min(Math.max(val, min), max);

const isContainerReady = computed(() => props.containerHeight > 0);

const sizeBounds = computed(() => {
  const h = props.containerHeight;
  const s = surroundingHeight.value;
  const max = Math.max(MIN_HEIGHT, h - MIN_MESSAGES_HEIGHT - s);
  const expanded = clamp(Math.floor(h * EXPAND_RATIO - s / 2), MIN_HEIGHT, max);
  return {
    min: MIN_HEIGHT,
    max: isContainerReady.value ? max : DEFAULT_HEIGHT,
    expanded,
    default: clamp(DEFAULT_HEIGHT, MIN_HEIGHT, max),
  };
});

const clampToBounds = val =>
  clamp(val, sizeBounds.value.min, sizeBounds.value.max);

// The dragged height always comes back, content can only ask the editor to grow
const appliedHeight = computed(() => {
  const requested = requestedHeight.value
    ? Math.max(requestedHeight.value, sizeBounds.value.default)
    : 0;
  return clampToBounds(Math.max(requested, editorHeight.value));
});

// Measure height of elements surrounding the editor (top panel, email fields, bottom panel)
const measureSurroundingHeight = () => {
  if (wrapperRef.value) {
    surroundingHeight.value = Math.max(
      0,
      wrapperRef.value.offsetHeight - appliedHeight.value
    );
  }
};

provide('requestEditorHeight', height => {
  // The bounds subtract the panels around the editor, so measure them before
  // the request is clamped, the drag and the toggle may not have run yet
  measureSurroundingHeight();
  requestedHeight.value = height;
});

const clearDragStyles = () => {
  Object.assign(document.body.style, { cursor: '', userSelect: '' });
};

const getClientY = e => (e.touches ? e.touches[0].clientY : e.clientY);

const onResizeStart = event => {
  measureSurroundingHeight();
  isResizing.value = true;
  startY.value = getClientY(event);
  startHeight.value = appliedHeight.value;
  editorHeight.value = startHeight.value;
  requestedHeight.value = 0;
  Object.assign(document.body.style, {
    cursor: 'row-resize',
    userSelect: 'none',
  });
};

const onResizeMove = event => {
  if (!isResizing.value) return;
  if (event.touches) event.preventDefault();
  editorHeight.value = clampToBounds(
    startHeight.value + startY.value - getClientY(event)
  );
};

const onResizeEnd = () => {
  if (!isResizing.value) return;
  isResizing.value = false;
  clearDragStyles();
};

const resetEditorHeight = () => {
  requestedHeight.value = 0;
  editorHeight.value = sizeBounds.value.default;
};

const toggleEditorExpand = () => {
  measureSurroundingHeight();
  const { expanded, max, default: defaultHeight } = sizeBounds.value;
  const isExpanded = appliedHeight.value > defaultHeight;
  requestedHeight.value = 0;
  // If expanded is too close to default, use max so the toggle is always noticeable
  const target = expanded - defaultHeight < 100 ? max : expanded;
  editorHeight.value = isExpanded ? defaultHeight : target;
};

const handleMessageSent = () => {
  clearTimeout(resetTimeoutId);
  resetTimeoutId = setTimeout(resetEditorHeight, RESET_DELAY_MS);
};

onMounted(() => {
  emitter.on(BUS_EVENTS.MESSAGE_SENT, handleMessageSent);
});

onBeforeUnmount(() => {
  emitter.off(BUS_EVENTS.MESSAGE_SENT, handleMessageSent);
  clearTimeout(resetTimeoutId);
  if (isResizing.value) {
    isResizing.value = false;
    clearDragStyles();
  }
});

useEventListener(document, 'mousemove', onResizeMove);
useEventListener(document, 'mouseup', onResizeEnd);
useEventListener(document, 'touchmove', onResizeMove, { passive: false });
useEventListener(document, 'touchend', onResizeEnd);
useEventListener(document, 'touchcancel', onResizeEnd);
useEventListener(window, 'blur', onResizeEnd);

defineExpose({ toggleEditorExpand, resetEditorHeight });
</script>

<template>
  <div
    ref="wrapperRef"
    class="relative resizable-editor-wrapper"
    :style="{
      '--editor-height': appliedHeight + 'px',
      '--editor-min-allowed': sizeBounds.min + 'px',
      '--editor-max-allowed': sizeBounds.max + 'px',
      '--editor-height-transition': isResizing
        ? '0s'
        : '200ms cubic-bezier(0.4, 0, 0.2, 1)',
    }"
  >
    <div
      class="group absolute inset-x-0 -top-4 z-10 flex h-4 cursor-row-resize select-none items-center justify-center bg-gradient-to-b from-transparent from-10% dark:to-n-surface-1/80 to-n-surface-1/90 backdrop-blur-[0.01875rem]"
      @mousedown="onResizeStart"
      @touchstart.prevent="onResizeStart"
      @dblclick="resetEditorHeight"
    >
      <div
        class="w-8 h-0.5 mt-1 rounded-full bg-n-slate-6 group-hover:bg-n-slate-8 transition-all duration-200 motion-safe:group-hover:animate-bounce"
        :class="{ 'bg-n-slate-8 animate-bounce': isResizing }"
      />
    </div>
    <slot />
  </div>
</template>

<style lang="scss">
.resizable-editor-wrapper {
  .resizable-editor-body {
    @apply overflow-auto;

    height: clamp(
      var(--editor-min-allowed, 5rem),
      var(--editor-height, 5rem),
      var(--editor-max-allowed, 7.5rem)
    );
    transition:
      height var(--editor-height-transition),
      opacity var(--editor-height-transition);
  }
}
</style>
