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
    <h2 class="text-s-primary text-base font-medium">{{ heading }}</h2>
    <p class="text-s-muted text-sm">{{ description }}</p>
  </header>
</template>
