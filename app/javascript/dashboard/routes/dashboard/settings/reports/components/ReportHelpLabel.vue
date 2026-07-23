<script setup>
defineProps({
  label: {
    type: String,
    required: true,
  },
  help: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <span
    v-if="help"
    v-tooltip.top="help"
    class="whitespace-nowrap leading-snug cursor-help border-b border-dotted border-n-slate-8"
  >
    {{ label }}
  </span>
  <span v-else class="whitespace-nowrap leading-snug">
    {{ label }}
  </span>
</template>
