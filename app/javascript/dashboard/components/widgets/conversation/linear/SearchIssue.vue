<script setup>
defineProps({
  title: {
    type: String,
    default: '',
  },
});
</script>
<template>
  <button
    class="inline-flex relative justify-between p-1.5 w-fit h-8 gap-1.5 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 active:bg-slate-75 dark:active:bg-slate-800"
    @click="$emit('click')"
  >
    <span
      class="text-sm font-medium truncate text-slate-900 dark:text-slate-50"
    >
      {{ title }}
    </span>
    <fluent-icon
      icon="chevron-down"
      size="18"
      class="flex-shrink-0 text-slate-900 dark:text-slate-50"
    />
    <slot name="dropdown" />
  </button>
</template>
