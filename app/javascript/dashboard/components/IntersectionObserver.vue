<script setup>
import { ref } from 'vue';
import { useIntersectionObserver } from '@vueuse/core';

const { options } = defineProps({
  options: {
    type: Object,
    default: () => ({ root: document, rootMargin: '100px 0 100px 0)' }),
  },
});

const emit = defineEmits(['observed']);
const observedElement = ref('');

let isThrottled = false;

useIntersectionObserver(
  observedElement,
  ([{ isIntersecting }]) => {
    if (isIntersecting && !isThrottled) {
      isThrottled = true;
      emit('observed');
      // Throttle next emit to avoid infinite loop on rapid failures (e.g. 401)
      setTimeout(() => {
        isThrottled = false;
      }, 500);
    }
  },
  options
);
</script>

<template>
  <div ref="observedElement" class="h-6 w-full" />
</template>
