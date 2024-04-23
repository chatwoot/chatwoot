<script setup>
import { CALENDAR_PERIODS } from '../helpers/DatePickerHelper';

defineProps({
  calendarType: {
    type: String,
    default: 'start',
  },
  firstButtonLabel: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  viewMode: {
    type: String,
    default: '',
  },
});
const emit = defineEmits(['prev', 'next', 'set-view']);

const { YEAR } = CALENDAR_PERIODS;

const onClickPrev = type => {
  emit('prev', type);
};

const onClickNext = type => {
  emit('next', type);
};

const onClickSetView = (type, mode) => {
  emit('set-view', type, mode);
};
</script>

<template>
  <div class="flex items-start justify-between w-full h-9">
    <button
      class="p-1 rounded-lg hover:bg-slate-75 dark:hover:bg-slate-700/50 rtl:rotate-180"
      @click="onClickPrev(calendarType)"
    >
      <fluent-icon
        icon="chevron-left"
        size="14"
        class="text-slate-900 dark:text-slate-50"
      />
    </button>
    <div class="flex items-center gap-1">
      <button
        v-if="firstButtonLabel"
        class="p-0 text-sm font-medium text-center text-slate-800 dark:text-slate-50 hover:text-woot-600 dark:hover:text-woot-600"
        @click="onClickSetView(calendarType, viewMode)"
      >
        {{ firstButtonLabel }}
      </button>
      <button
        v-if="buttonLabel"
        class="p-0 text-sm font-medium text-center text-slate-800 dark:text-slate-50"
        :class="{ 'hover:text-woot-600 dark:hover:text-woot-600': viewMode }"
        @click="onClickSetView(calendarType, YEAR)"
      >
        {{ buttonLabel }}
      </button>
    </div>
    <button
      class="p-1 rounded-lg hover:bg-slate-75 dark:hover:bg-slate-700/50 rtl:rotate-180"
      @click="onClickNext(calendarType)"
    >
      <fluent-icon
        icon="chevron-right"
        size="14"
        class="text-slate-900 dark:text-slate-50"
      />
    </button>
  </div>
</template>
