<script setup>
const emit = defineEmits(['click']);
</script>

<template>
  <button
    class="flex items-center justify-center size-9 rounded-lg text-n-slate-11 active:bg-n-alpha-2 transition-colors"
    @click="emit('click')"
  >
    <span class="i-lucide-chevron-left size-6" />
  </button>
</template>
