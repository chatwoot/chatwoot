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
  <div class="w-[200px] flex flex-col items-start">
    <h4
      class="w-full px-5 py-4 text-sm font-medium capitalize text-start text-slate-600 dark:text-slate-200"
    >
      DATE RANGE
    </h4>
    <div class="flex flex-col items-start w-full">
      <button
        v-for="range in dateRanges"
        :key="range.label"
        class="w-full px-5 py-3 text-sm font-medium border-none rounded-none text-start hover:bg-slate-50 dark:hover:bg-slate-700"
        :class="
          range.value === selectedRange
            ? 'text-slate-800 dark:text-slate-50 bg-slate-50 dark:bg-slate-700'
            : 'text-slate-600 dark:text-slate-200'
        "
        @click="setDateRange(range)"
      >
        {{ range.label }}
      </button>
    </div>
  </div>
</template>
