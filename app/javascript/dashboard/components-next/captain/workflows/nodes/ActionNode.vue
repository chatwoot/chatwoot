<script setup>
import { Handle, Position } from '@vue-flow/core';

defineProps({
  data: { type: Object, default: () => ({}) },
});
</script>

<template>
  <div
    class="flex w-52 rounded-xl bg-n-solid-2 outline outline-1 -outline-offset-1 outline-n-container shadow-sm overflow-hidden"
  >
    <Handle type="target" :position="Position.Top" class="!bg-n-blue-9" />
    <div class="w-1 shrink-0 bg-n-blue-9" />
    <div class="flex flex-col gap-1 px-3 py-2.5 min-w-0">
      <div class="flex items-center gap-2">
        <span class="i-lucide-play text-n-blue-11 size-3.5 shrink-0" />
        <span class="text-xs font-medium text-n-slate-12 truncate">
          {{ data.label || 'Action' }}
        </span>
      </div>
      <span
        v-if="data.description"
        class="text-[11px] text-n-slate-10 leading-tight truncate"
      >
        {{ data.description }}
      </span>
    </div>
    <Handle type="source" :position="Position.Bottom" class="!bg-n-blue-9" />
  </div>
</template>
