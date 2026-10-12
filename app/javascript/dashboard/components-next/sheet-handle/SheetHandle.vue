<script setup>
import { computed, useTemplateRef } from 'vue';
import { useSwipe } from '@vueuse/core';

const props = defineProps({
  // Breakpoint from which the sheet turns into a popover and the handle disappears.
  hideFrom: {
    type: String,
    default: 'sm',
    validator: value => ['sm', 'lg'].includes(value),
  },
});

const emit = defineEmits(['close']);

// A downward swipe longer than this closes the sheet.
const CLOSE_DISTANCE_PX = 64;
const SLIDE_DURATION_MS = 200;
const SLIDE_CLASSES = [
  'translate-y-full',
  'transition-transform',
  'duration-200',
  'ease-out',
];

const HIDE_FROM_CLASSES = { sm: 'sm:hidden', lg: 'lg:hidden' };
const hideClass = computed(() => HIDE_FROM_CLASSES[props.hideFrom]);

const handleRef = useTemplateRef('handleRef');

// The handle is the first child of the sheet, so the sheet is its parent.
const getSheet = () => handleRef.value?.parentElement;

const close = () => emit('close');

const slideDownAndClose = () => {
  const sheet = getSheet();
  if (!sheet) {
    close();
    return;
  }
  sheet.classList.add(...SLIDE_CLASSES);
  setTimeout(() => {
    close();
    sheet.classList.remove(...SLIDE_CLASSES);
  }, SLIDE_DURATION_MS);
};

// Only the handle listens for the gesture, so scrolling the sheet content never closes it.
const { lengthY } = useSwipe(handleRef, {
  threshold: 10,
  onSwipeEnd: () => {
    // lengthY is negative while swiping down
    if (-lengthY.value >= CLOSE_DISTANCE_PX) slideDownAndClose();
  },
});
</script>

<template>
  <div
    ref="handleRef"
    class="absolute inset-x-0 top-0 z-10 flex items-center justify-center h-6 touch-none"
    :class="hideClass"
    @click="close"
  >
    <span class="w-10 h-1 rounded-full bg-n-slate-8" />
  </div>
</template>
