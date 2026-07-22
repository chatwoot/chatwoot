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
  <span class="inline-flex items-center gap-1 max-w-full">
    <span class="whitespace-nowrap leading-snug">{{ label }}</span>
    <span
      v-if="help"
      v-tooltip.top="help"
      class="i-lucide-info flex flex-shrink-0 text-n-slate-10 size-3.5"
    />
  </span>
</template>
