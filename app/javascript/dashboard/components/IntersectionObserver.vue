<script setup>
import { ref, defineEmits } from 'vue';
import { useIntersectionObserver } from '@vueuse/core';

const { options } = defineProps({
  options: {
    type: Object,
    default: () => ({ root: null, rootMargin: '100px 0px 100px 0px' }),
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
