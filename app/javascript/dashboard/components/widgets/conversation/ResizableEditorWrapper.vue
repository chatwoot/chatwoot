<script setup>
import { ref, computed, onMounted, onBeforeUnmount, useTemplateRef } from 'vue';
import { useEventListener } from '@vueuse/core';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

const props = defineProps({
  containerHeight: {
    type: Number,
    default: 0,
  },
});

const DEFAULT_HEIGHT = 120;
const MIN_HEIGHT = 80;
const MIN_MESSAGES_HEIGHT = 200;
const EXPAND_HEIGHT_RATIO = 0.5;
const RESET_DELAY_MS = 120;

const wrapperRef = useTemplateRef('wrapperRef');
const surroundingHeight = ref(0);

const editorHeight = ref(DEFAULT_HEIGHT);

const clamp = (val, min, max) => Math.min(Math.max(val, min), max);

// Measure the height of elements surrounding the editor (top panel, email fields, bottom panel)
const measureSurroundingHeight = () => {
  if (wrapperRef.value) {
    surroundingHeight.value = Math.max(
      0,
      wrapperRef.value.offsetHeight - editorHeight.value
    );
  }
};

const sizeBounds = computed(() => {
  const h = props.containerHeight;
  const surrounding = surroundingHeight.value;
  const max = Math.max(MIN_HEIGHT, h - MIN_MESSAGES_HEIGHT - surrounding);
  const expanded = Math.max(
    MIN_HEIGHT,
    Math.floor(h * EXPAND_HEIGHT_RATIO) - surrounding
  );
  return {
    min: MIN_HEIGHT,
    max,
    expanded,
    default: clamp(DEFAULT_HEIGHT, MIN_HEIGHT, max),
  };
});

const clampToBounds = val =>
  clamp(val, sizeBounds.value.min, sizeBounds.value.max);

const isResizing = ref(false);
const startY = ref(0);
const startHeight = ref(0);

const getClientY = event =>
  event.touches ? event.touches[0].clientY : event.clientY;

const onResizeStart = event => {
  measureSurroundingHeight();
  isResizing.value = true;
  startY.value = getClientY(event);
  startHeight.value = clampToBounds(editorHeight.value);
  editorHeight.value = startHeight.value;
  Object.assign(document.body.style, {
    cursor: 'row-resize',
    userSelect: 'none',
  });
};

const onResizeMove = event => {
  if (!isResizing.value) return;
  if (event.touches) event.preventDefault();
  const dy = startY.value - getClientY(event);
  editorHeight.value = clampToBounds(startHeight.value + dy);
};

const onResizeEnd = () => {
  if (!isResizing.value) return;
  isResizing.value = false;
  Object.assign(document.body.style, { cursor: '', userSelect: '' });
};

const resetEditorHeight = () => {
  isResizing.value = false;
  Object.assign(document.body.style, { cursor: '', userSelect: '' });
  editorHeight.value = sizeBounds.value.default;
};

let resetTimeoutId = null;

const handleMessageSent = () => {
  if (resetTimeoutId) clearTimeout(resetTimeoutId);
  resetTimeoutId = setTimeout(() => {
    resetEditorHeight();
  }, RESET_DELAY_MS);
};

const toggleEditorExpand = () => {
  measureSurroundingHeight();
  isResizing.value = false;
  Object.assign(document.body.style, { cursor: '', userSelect: '' });
  const { expanded, default: defaultHeight } = sizeBounds.value;
  const clamped = clampToBounds(editorHeight.value);
  const isExpanded = Math.abs(clamped - expanded) < 2;
  editorHeight.value = isExpanded ? defaultHeight : expanded;
};

onMounted(() => {
  measureSurroundingHeight();
  editorHeight.value = sizeBounds.value.default;
  emitter.on(BUS_EVENTS.MESSAGE_SENT, handleMessageSent);
});

onBeforeUnmount(() => {
  emitter.off(BUS_EVENTS.MESSAGE_SENT, handleMessageSent);
  if (resetTimeoutId) clearTimeout(resetTimeoutId);

  // Ensure global drag styles are always cleaned up,
  isResizing.value = false;
  Object.assign(document.body.style, { cursor: '', userSelect: '' });
});

useEventListener(document, 'mousemove', onResizeMove);
useEventListener(document, 'mouseup', onResizeEnd);
useEventListener(document, 'touchmove', onResizeMove, { passive: false });
useEventListener(document, 'touchend', onResizeEnd);
useEventListener(document, 'touchcancel', onResizeEnd);

defineExpose({ toggleEditorExpand, resetEditorHeight });
</script>

<template>
  <div
    ref="wrapperRef"
    class="relative resizable-editor-wrapper"
    :style="{
      '--editor-height': editorHeight + 'px',
      '--editor-min-allowed': sizeBounds.min + 'px',
      '--editor-max-allowed': sizeBounds.max + 'px',
      '--editor-height-transition': isResizing ? 'none' : '180ms ease',
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
