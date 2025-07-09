<script setup>
defineProps({
  heading: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <header class="flex flex-col items-start gap-2">
    <h2 class="text-n-slate-12 text-base font-medium">{{ heading }}</h2>
    <p class="text-n-slate-11 text-sm">{{ description }}</p>
  </header>
</template>
