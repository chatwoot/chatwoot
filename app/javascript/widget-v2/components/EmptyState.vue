<script setup>
defineProps({
  icon: { type: String, default: 'i-lucide-inbox' },
  title: { type: String, required: true },
  description: { type: String, default: '' },
});
</script>

<template>
  <div
    class="flex flex-col items-center justify-center gap-2 px-8 py-12 text-center"
  >
    <span
      class="flex items-center justify-center w-12 h-12 mb-1 rounded-full bg-cw-muted text-cw-text-faint"
    >
      <span :class="icon" class="text-2xl" />
    </span>
    <h2 class="text-sm font-semibold text-cw-text">{{ title }}</h2>
    <p v-if="description" class="text-xs text-cw-text-muted max-w-56">
      {{ description }}
    </p>
    <slot />
  </div>
</template>
