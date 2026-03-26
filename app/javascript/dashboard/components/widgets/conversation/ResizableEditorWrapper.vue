<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import { useBreakpoints, useEventListener, useWindowSize } from '@vueuse/core';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

const DEFAULT_HEIGHT = 120;
const SMALL_SCREEN_DEFAULT_HEIGHT = 96;
const MIN_HEIGHT = 80;
const SMALL_SCREEN_MIN_HEIGHT = 72;
const MAX_HEIGHT = 500;
const SMALL_SCREEN_MAX_HEIGHT = 170;
const SMALL_SCREEN_BREAKPOINT = 768;
const SAFE_TOP_OFFSET = 320;
const RESET_DELAY_MS = 120;
const { height: windowHeight } = useWindowSize();
const breakpoints = useBreakpoints({ sm: SMALL_SCREEN_BREAKPOINT });
const isSmallScreen = breakpoints.smaller('sm');

const clamp = (val, min, max) => Math.min(Math.max(val, min), max);

const sizeBounds = computed(() => {
  const isSmall = isSmallScreen.value;
  const min = isSmall ? SMALL_SCREEN_MIN_HEIGHT : MIN_HEIGHT;
  const defaultSize = isSmall ? SMALL_SCREEN_DEFAULT_HEIGHT : DEFAULT_HEIGHT;
  const max = Math.max(
    min,
    Math.min(
      isSmall ? SMALL_SCREEN_MAX_HEIGHT : MAX_HEIGHT,
      windowHeight.value - SAFE_TOP_OFFSET
    )
  );
  return {
    min,
    max,
    default: clamp(defaultSize, min, max),
  };
});
const clampToBounds = val =>
  clamp(val, sizeBounds.value.min, sizeBounds.value.max);

const editorHeight = ref(clampToBounds(sizeBounds.value.default));

const isResizing = ref(false);
const startY = ref(0);
const startHeight = ref(0);

const getClientY = event =>
  event.touches ? event.touches[0].clientY : event.clientY;

const onResizeStart = event => {
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
  isResizing.value = false;
  Object.assign(document.body.style, { cursor: '', userSelect: '' });
  const { max, default: defaultHeight } = sizeBounds.value;
  const isExpanded = Math.abs(editorHeight.value - max) < 2;
  editorHeight.value = isExpanded ? defaultHeight : max;
};

onMounted(() => {
  emitter.on(BUS_EVENTS.MESSAGE_SENT, handleMessageSent);
});

onBeforeUnmount(() => {
  emitter.off(BUS_EVENTS.MESSAGE_SENT, handleMessageSent);
  if (resetTimeoutId) clearTimeout(resetTimeoutId);
});

useEventListener(document, 'mousemove', onResizeMove);
useEventListener(document, 'mouseup', onResizeEnd);
useEventListener(document, 'touchmove', onResizeMove, { passive: false });
useEventListener(document, 'touchend', onResizeEnd);

defineExpose({ toggleEditorExpand, resetEditorHeight });
</script>

<template>
  <div
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
