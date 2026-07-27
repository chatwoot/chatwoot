<script setup>
defineProps({
  label: { type: String, default: '' },
});
</script>

<template>
  <div class="flex items-center gap-2 px-4">
    <div class="w-6 shrink-0" />
    <div
      class="inline-flex items-center gap-2 px-3.5 py-3 bg-cw-muted rounded-token rounded-bl-md"
    >
      <span class="flex gap-1">
        <span
          v-for="dot in 3"
          :key="dot"
          class="w-1.5 h-1.5 rounded-full bg-cw-text-faint animate-loader-pulse"
          :style="{ animationDelay: `${(dot - 1) * 0.2}s` }"
        />
      </span>
      <span v-if="label" class="text-xs text-cw-text-muted">{{ label }}</span>
    </div>
  </div>
</template>
