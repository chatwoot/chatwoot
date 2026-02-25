<script setup>
import { format, fromUnixTime } from 'date-fns';

defineProps({
  label: {
    type: String,
    required: true,
  },
  items: {
    type: Array,
    required: true,
  },
});
const formatDate = timestamp =>
  format(fromUnixTime(timestamp), 'MMM dd, yyyy, hh:mm a');
</script>

<template>
  <div class="flex justify-between w-full">
    <span
      class="text-sm sticky top-0 h-fit font-normal tracking-[-0.6%] min-w-[140px] truncate text-n-slate-11"
    >
      {{ label }}
    </span>
    <div class="flex flex-col w-full gap-2">
      <span
        v-for="item in items"
        :key="item.id"
        class="text-sm font-normal text-n-slate-12 text-right tabular-nums"
      >
        {{ formatDate(item.created_at) }}
      </span>
      <slot name="showMore" />
    </div>
  </div>
</template>
