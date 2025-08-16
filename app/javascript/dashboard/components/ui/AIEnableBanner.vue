<script setup>
defineProps({
  aiEnable: Boolean,
});
const emit = defineEmits(['toggle-ai']);
</script>

<template>
  <button
    class="relative h-8 w-8 rounded-full mt-1 inline-flex items-center justify-center hover:scale-[1.3] transition-all duration-300"
    :class="aiEnable ? 'bg-n-brand' : 'bg-n-inactive'"
    @click="emit('toggle-ai')"
  >
    <span class="i-lucide-bot scale-[1.8]" />

    <span
      v-if="!aiEnable"
      class="pointer-events-none absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 i-lucide-ban size-8 z-10"
    />
  </button>
</template>
