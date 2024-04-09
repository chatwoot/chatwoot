<script setup>
import { format, fromUnixTime } from 'date-fns';

defineProps({
  label: {
    type: String,
    required: true,
  },
  showLabel: {
    type: Boolean,
    default: true,
  },
  createdAt: {
    type: Number,
    required: true,
  },
});
const formatDate = timestamp =>
  format(fromUnixTime(timestamp), 'MMM dd, yyyy, hh:mm a');
</script>
<template>
  <div class="flex items-center justify-between w-full">
    <div class="w-1/2">
      <span
        v-if="showLabel"
        class="text-sm font-normal tracking-[-0.6%] w-[140px] truncate text-slate-500 dark:text-slate-200"
      >
        {{ label }}
      </span>
    </div>
    <div class="w-1/2 text-right">
      <span
        class="text-sm font-normal tracking-[-0.6%] text-slate-900 dark:text-slate-50"
      >
        {{ formatDate(createdAt) }}
      </span>
    </div>
  </div>
</template>
