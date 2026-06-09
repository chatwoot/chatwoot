<script setup>
import { dateRanges } from '../helpers/DatePickerHelper';

defineProps({
  selectedRange: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['setRange']);

const setDateRange = range => {
  emit('setRange', range);
};
</script>

<template>
  <div class="w-[200px] flex flex-col items-start">
    <h4
      class="w-full px-5 py-4 text-xs font-bold capitalize text-start text-n-slate-10"
    >
      {{ $t('DATE_PICKER.DATE_RANGE_OPTIONS.TITLE') }}
    </h4>
    <div class="flex flex-col items-start w-full">
      <template v-for="range in dateRanges" :key="range.label">
        <div v-if="range.separator" class="w-full border-t border-n-strong" />
        <button
          class="w-full px-5 py-3 text-sm font-medium truncate border-none rounded-none text-start hover:bg-n-alpha-2 dark:hover:bg-n-solid-3"
          :class="
            range.value === selectedRange
              ? 'text-n-slate-12 bg-n-alpha-1 dark:bg-n-solid-active'
              : 'text-n-slate-12'
          "
          @click="setDateRange(range)"
        >
          {{ $t(range.label) }}
        </button>
      </template>
    </div>
  </div>
</template>
