<script setup>
import { Handle, Position } from '@vue-flow/core';

defineProps({
  data: { type: Object, default: () => ({}) },
});
</script>

<template>
  <div
    class="flex rounded-lg bg-n-solid-2 outline outline-1 -outline-offset-1 outline-n-container shadow-sm"
  >
    <Handle type="target" :position="Position.Top" class="!bg-n-violet-9" />
    <div class="w-0.5 shrink-0 bg-n-violet-9" />
    <div class="flex items-center gap-1 px-1.5 py-1 min-w-0">
      <span
        class="i-lucide-message-circle-question text-n-violet-11 size-2.5 shrink-0"
      />
      <span
        class="text-[11px] leading-none font-medium text-n-slate-12 truncate"
      >
        {{ data.label || 'Collect Input' }}
      </span>
    </div>
    <Handle type="source" :position="Position.Bottom" class="!bg-n-violet-9" />
  </div>
</template>
