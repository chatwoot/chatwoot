<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

// Presentational shell for the "Created for you" rows. The owning component
// drives `ready` from its own lifecycle (widget polling, help-center events);
// row separation is handled by the parent's `divide-y`.
defineProps({
  ready: { type: Boolean, default: false },
  title: { type: String, required: true },
  description: { type: String, default: '' },
  status: { type: String, default: '' },
});
</script>

<template>
  <div class="flex items-center justify-between gap-3 px-3 py-3">
    <div class="flex items-center gap-2 min-w-0">
      <Icon
        v-if="ready"
        icon="i-lucide-check"
        class="size-4 text-n-teal-11 flex-shrink-0"
      />
      <Spinner v-else :size="16" class="text-n-slate-9 flex-shrink-0" />
      <span class="text-sm font-medium text-n-slate-12 flex-shrink-0">
        {{ title }}
      </span>
      <span class="w-px h-4 bg-n-weak flex-shrink-0" />
      <span class="text-sm text-n-slate-11 truncate">{{ description }}</span>
    </div>
    <span class="text-sm text-n-slate-11 flex-shrink-0">{{ status }}</span>
  </div>
</template>
