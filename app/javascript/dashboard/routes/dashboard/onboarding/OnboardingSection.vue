<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  title: { type: String, required: true },
  icon: { type: String, required: true },
});
</script>

<template>
  <div class="mb-5">
    <!-- Section header with icon + triangles -->
    <div class="flex items-center gap-4 mb-3 -ms-12">
      <div class="flex flex-col items-center z-10 flex-shrink-0">
        <svg
          width="6"
          height="5"
          viewBox="0 0 6 5"
          fill="none"
          class="text-n-slate-5"
        >
          <path d="M3 0L6 5H0L3 0Z" fill="currentColor" />
        </svg>
        <div
          class="flex items-center justify-center w-8 h-8 rounded-lg bg-n-solid-1 border border-n-weak"
        >
          <Icon :icon="icon" class="size-4 text-n-slate-11" />
        </div>
        <svg
          width="6"
          height="5"
          viewBox="0 0 6 5"
          fill="none"
          class="text-n-slate-5"
        >
          <path d="M3 5L0 0H6L3 5Z" fill="currentColor" />
        </svg>
      </div>
      <span class="text-heading-3 text-n-slate-12">
        {{ title }}
      </span>
    </div>

    <!-- Card -->
    <div class="border border-n-weak rounded-xl overflow-hidden bg-n-surface-1">
      <slot />
    </div>
  </div>
</template>
