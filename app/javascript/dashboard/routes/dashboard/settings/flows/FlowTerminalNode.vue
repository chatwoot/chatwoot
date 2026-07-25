<script setup>
import { Handle, Position } from '@vue-flow/core';
import { computed } from 'vue';

const props = defineProps({
  data: { type: Object, required: true },
});

const chipClass = computed(() => {
  if (props.data.kind === 'handoff') {
    return 'bg-n-ruby-2 text-n-ruby-11 dark:bg-n-solid-ruby';
  }
  return 'bg-n-solid-blue text-n-blue-11';
});
</script>

<template>
  <div
    class="rounded-md px-2.5 py-1.5 text-xs font-medium shadow-sm outline outline-1 outline-n-weak"
    :class="chipClass"
  >
    <Handle
      id="in"
      type="target"
      :position="Position.Top"
      class="!bg-n-slate-9 !size-2 !border-0"
    />
    {{ data.label }}
  </div>
</template>
