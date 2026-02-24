<script setup>
import { ref, defineEmits } from 'vue';
import { useIntersectionObserver } from '@vueuse/core';

const { options } = defineProps({
  options: {
    type: Object,
    default: () => ({ root: document, rootMargin: '100px 0 100px 0)' }),
  },
});

const emit = defineEmits(['observed']);
const observedElement = ref('');

useIntersectionObserver(
  observedElement,
  ([{ isIntersecting }]) => {
    if (isIntersecting) {
      emit('observed');
    }
  },
  options
);
</script>

<template>
  <div ref="observedElement" class="h-6 w-full" />
</template>
