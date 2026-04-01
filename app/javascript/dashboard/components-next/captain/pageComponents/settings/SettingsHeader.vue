<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  heading: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <header class="flex flex-col gap-2">
    <div class="flex items-start gap-3">
      <Icon
        v-if="icon"
        :icon="icon"
        class="mt-0.5 size-5 shrink-0 text-secondary"
      />
      <div class="min-w-0 flex-1 space-y-1">
        <h2 class="text-lg font-semibold tracking-tight text-on-surface">
          {{ heading }}
        </h2>
        <p v-if="description" class="mb-0 text-sm text-on-surface-variant">
          {{ description }}
        </p>
      </div>
    </div>
  </header>
</template>
