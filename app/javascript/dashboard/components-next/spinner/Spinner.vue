<script setup>
defineProps({
  size: {
    type: Number,
    default: 24,
  },
});
</script>

<template>
  <svg
    xmlns="http://www.w3.org/2000/svg"
    :width="size"
    :height="size"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="8"
    strokeLinecap="round"
    strokeLinejoin="round"
    class="animate-spin"
  >
    <path d="M21 12a9 9 0 1 1-6.219-8.56" />
  </svg>
</template>
