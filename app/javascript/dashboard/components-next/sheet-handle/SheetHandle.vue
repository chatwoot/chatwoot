<script setup>
import { useTemplateRef } from 'vue';
import { useSwipe } from '@vueuse/core';

const emit = defineEmits(['close']);

// The sheet closes once it is dragged past this share of its own height.
const CLOSE_DISTANCE_RATIO = 0.3;
const SLIDE_DURATION_MS = 200;

const handleRef = useTemplateRef('handleRef');

// The handle is the first child of the sheet, so the sheet is its parent. The offset is dynamic,
// so it is written straight to the sheet's transform instead of a Tailwind class.
const getSheet = () => handleRef.value?.parentElement;

const moveSheet = (distance, animated) => {
  const sheet = getSheet();
  if (!sheet) return;
  sheet.style.transition = animated
    ? `transform ${SLIDE_DURATION_MS}ms ease-out`
    : 'none';
  sheet.style.transform = distance ? `translateY(${distance}px)` : '';
};

// Only the handle listens for the gesture, so scrolling the sheet content never closes it.
const { lengthY } = useSwipe(handleRef, {
  threshold: 10,
  onSwipe: () => moveSheet(Math.max(0, -lengthY.value), false),
  onSwipeEnd: () => {
    const sheet = getSheet();
    if (!sheet) return;
    const distance = Math.max(0, -lengthY.value);
    if (distance < sheet.offsetHeight * CLOSE_DISTANCE_RATIO) {
      moveSheet(0, true);
      return;
    }
    moveSheet(sheet.offsetHeight, true);
    setTimeout(() => emit('close'), SLIDE_DURATION_MS);
  },
});
</script>

<template>
  <div
    ref="handleRef"
    class="absolute inset-x-0 top-0 z-10 flex items-center justify-center h-6 sm:hidden touch-none"
  >
    <span class="w-10 h-1 rounded-full bg-n-slate-8" />
  </div>
</template>
