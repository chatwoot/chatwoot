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
      class="w-full px-5 py-4 text-xs font-bold capitalize text-start text-s-muted"
    >
      {{ $t('DATE_PICKER.DATE_RANGE_OPTIONS.TITLE') }}
    </h4>
    <div class="flex flex-col items-start w-full">
      <template v-for="range in dateRanges" :key="range.label">
        <div v-if="range.separator" class="w-full border-t border-s-border-strong" />
        <button
          class="w-full px-5 py-3 text-sm font-medium truncate border-none rounded-none text-start hover:bg-s-subtle dark:hover:bg-s-subtle"
          :class="
            range.value === selectedRange
              ? 'text-s-primary bg-s-subtle dark:bg-s-brand-soft'
              : 'text-s-primary'
          "
          @click="setDateRange(range)"
        >
          {{ $t(range.label) }}
        </button>
      </template>
    </div>
  </div>
</template>
