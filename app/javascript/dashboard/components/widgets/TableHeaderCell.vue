<script setup>
import { computed } from 'vue';
const props = defineProps({
  span: {
    type: Number,
    required: true,
  },
  label: {
    type: String,
    required: true,
    default: '',
  },
});

const spanClass = computed(() => {
  if (props.span === 1) return 'col-span-1';
  if (props.span === 2) return 'col-span-2';
  if (props.span === 3) return 'col-span-3';
  if (props.span === 4) return 'col-span-4';
  if (props.span === 5) return 'col-span-5';
  if (props.span === 6) return 'col-span-6';
  if (props.span === 7) return 'col-span-7';
  if (props.span === 8) return 'col-span-8';
  if (props.span === 9) return 'col-span-9';
  if (props.span === 10) return 'col-span-10';

  return 'col-span-1';
});
</script>
<template>
  <div
    class="flex items-center px-0 py-2 text-xs font-medium text-left uppercase text-slate-700 dark:text-slate-100 rtl:text-right"
    :class="spanClass"
  >
    <slot>
      {{ label }}
    </slot>
  </div>
</template>
