<script setup>
import { onMounted } from 'vue';
import TestimonialCard from './TestimonialCard.vue';

const emit = defineEmits(['resizeContainers']);

const reviewContent =
  "Chatwoot has transformed the way we engage with our customers. It's omni-channel feature allows us to manage conversations simultaneously across multiple channels.\n\nI've used Chatwoot at my previous companies and continue to rely on it today at Converso. After years as a happy customer, I can confidently say it's an indispensable tool for any customer-focused business.";

onMounted(() => {
  emit('resizeContainers', true);
});
</script>

<template>
  <div
    class="relative flex-1 flex flex-col items-start justify-center bg-n-alpha-black2 dark:bg-n-solid-3 px-12 py-14 rounded-e-lg"
  >
    <TestimonialCard
      :review-content="reviewContent"
      author-name="Ariel Lambrecht"
      author-designation="Founder of 99 - Brazil's first unicorn and Converso"
    />
    <div class="absolute bottom-8 right-8 grid grid-cols-3 gap-1.5">
      <span class="w-2 h-2 rounded-full bg-n-slate-7" />
      <span class="w-2 h-2 rounded-full bg-n-slate-7" />
      <span class="w-2 h-2 rounded-full bg-n-slate-7" />
      <span class="w-2 h-2 rounded-full bg-n-slate-7" />
      <span class="w-2 h-2 rounded-full bg-n-slate-7" />
      <span class="w-2 h-2 rounded-full bg-n-slate-7" />
    </div>
  </div>
</template>
