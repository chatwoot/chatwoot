<script setup>
defineProps({
  title: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="flex flex-col items-center justify-center gap-2 text-center">
    <div
      class="flex items-center justify-center w-12 h-12 rounded-xl bg-n-slate-3"
    >
      <span class="i-lucide-calendar-clock text-xl text-n-slate-11" />
    </div>
    <h3 class="text-sm font-semibold text-n-slate-12">{{ title }}</h3>
    <p class="text-xs text-n-slate-11 max-w-md">{{ subtitle }}</p>
  </div>
</template>
