<script setup>
import { dateRanges } from '../helpers/DatePickerHelper';

defineProps({
  selectedRange: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['set-range']);

const setDateRange = range => {
  emit('set-range', range);
};
</script>

<template>
  <div class="w-[200px] flex flex-col">
    <h4
      class="px-5 py-4 text-sm font-medium capitalize text-slate-600 dark:text-slate-200"
    >
      DATE RANGE
    </h4>
    <ul>
      <li
        v-for="range in dateRanges"
        :key="range.label"
        class="px-5 py-3 text-sm font-medium list-none cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-700"
        :class="
          range.value === selectedRange
            ? 'text-slate-800 dark:text-slate-50 bg-slate-50 dark:bg-slate-700'
            : 'text-slate-600 dark:text-slate-200'
        "
        @click="setDateRange(range)"
      >
        {{ range.label }}
      </li>
    </ul>
  </div>
</template>
