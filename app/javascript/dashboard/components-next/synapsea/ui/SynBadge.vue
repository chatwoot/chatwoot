<script setup>
defineProps({
  label: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <span
    class="inline-flex rounded-full bg-n-slate-3 px-2 py-0.5 text-xs text-n-slate-12"
  >
    <slot>{{ label }}</slot>
  </span>
</template>
