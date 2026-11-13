<script setup>
import { computed, onBeforeUnmount, useTemplateRef } from 'vue';
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

// The sheet closes once it is dragged past this share of its own height (or this distance, if larger).
const CLOSE_DISTANCE_RATIO = 0.3;
const MIN_CLOSE_DISTANCE_PX = 64;
const SLIDE_DURATION_MS = 200;
const SLIDE_KEYFRAMES = [
  { transform: 'translateY(0)' },
  { transform: 'translateY(100%)' },
];

const HIDE_FROM_CLASSES = { sm: 'sm:hidden', lg: 'lg:hidden' };
const hideClass = computed(() => HIDE_FROM_CLASSES[props.hideFrom]);

const handleRef = useTemplateRef('handleRef');

// The handle is the first child of the sheet, so the sheet is its parent.
const getSheet = () => handleRef.value?.parentElement;

const close = () => emit('close');

// The slide is a paused Web Animation scrubbed by the drag, so no style attribute is written on the sheet.
let slide = null;

const cancelSlide = () => {
  slide?.cancel();
  slide = null;
};

const createSlide = (sheet, paused) => {
  cancelSlide();
  slide = sheet.animate(SLIDE_KEYFRAMES, {
    duration: SLIDE_DURATION_MS,
    easing: 'linear',
    fill: 'both',
  });
  if (paused) slide.pause();
  return slide;
};

const slideOutAndClose = sheet => {
  const animation = slide || createSlide(sheet, false);
  animation.onfinish = () => {
    close();
    cancelSlide();
  };
  animation.playbackRate = 1;
  animation.play();
};

const snapBack = () => {
  const animation = slide;
  if (!animation) return;
  animation.onfinish = cancelSlide;
  animation.reverse();
};

// Tapping the handle (no drag) closes the sheet as well.
const onTap = () => {
  const sheet = getSheet();
  if (!sheet || typeof sheet.animate !== 'function') {
    close();
    return;
  }
  slideOutAndClose(sheet);
};

// Only the handle listens for the gesture, so scrolling the sheet content never closes it.
const { lengthY } = useSwipe(handleRef, {
  threshold: 10,
  // lengthY is negative while swiping down: the sheet follows the finger
  onSwipe: () => {
    const sheet = getSheet();
    if (!sheet || typeof sheet.animate !== 'function') return;
    const distance = Math.max(0, -lengthY.value);
    const progress = Math.min(1, distance / (sheet.offsetHeight || 1));
    (slide || createSlide(sheet, true)).currentTime =
      progress * SLIDE_DURATION_MS;
  },
  onSwipeEnd: () => {
    const sheet = getSheet();
    if (!sheet || !slide) return;
    const distance = Math.max(0, -lengthY.value);
    const closeDistance = Math.max(
      MIN_CLOSE_DISTANCE_PX,
      sheet.offsetHeight * CLOSE_DISTANCE_RATIO
    );
    if (distance >= closeDistance) {
      slideOutAndClose(sheet);
    } else {
      snapBack();
    }
  },
});

onBeforeUnmount(cancelSlide);
</script>

<template>
  <div
    ref="handleRef"
    class="absolute inset-x-0 top-0 z-10 flex items-center justify-center h-6 touch-none"
    :class="hideClass"
    @click="onTap"
  >
    <span class="w-10 h-1 rounded-full bg-n-slate-8" />
  </div>
</template>
