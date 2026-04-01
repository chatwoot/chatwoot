<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  content: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div
    class="flex flex-col gap-2 rounded-lg border border-outline-variant/15 bg-surface-container-low/80 p-3 transition-colors duration-200 hover:border-outline-variant/25 hover:bg-surface-container"
  >
    <div class="flex items-start gap-2">
      <Icon
        icon="i-lucide-sparkles"
        class="mt-0.5 size-4 shrink-0 text-secondary"
      />
      <div class="text-sm text-on-surface">
        {{ content }}
      </div>
    </div>
  </div>
</template>
