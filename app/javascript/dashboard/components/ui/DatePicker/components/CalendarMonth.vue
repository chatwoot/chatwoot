<script setup>
import { computed } from 'vue';
import { format, getMonth, setMonth, startOfMonth } from 'date-fns';
import {
  yearName,
  CALENDAR_TYPES,
  CALENDAR_PERIODS,
} from '../helpers/DatePickerHelper';

import CalendarAction from './CalendarAction.vue';

const props = defineProps({
  calendarType: {
    type: String,
    default: 'start',
  },
  startCurrentDate: Date,
  endCurrentDate: Date,
});

const emit = defineEmits(['selectMonth', 'prev', 'next', 'setView']);
const { START_CALENDAR } = CALENDAR_TYPES;
const { MONTH, YEAR } = CALENDAR_PERIODS;

const months = Array.from({ length: 12 }, (_, index) =>
  format(setMonth(startOfMonth(new Date()), index), 'MMM')
);

const activeMonthIndex = computed(() => {
  const date =
    props.calendarType === START_CALENDAR
      ? props.startCurrentDate
      : props.endCurrentDate;
  return getMonth(date);
});

const setViewMode = (type, mode) => {
  emit('setView', type, mode);
};

const onClickPrev = () => {
  emit('prev');
};

const onClickNext = () => {
  emit('next');
};

const selectMonth = index => {
  emit('selectMonth', index);
};
</script>

<template>
  <div class="flex flex-col w-full gap-2 max-h-[312px]">
    <CalendarAction
      :view-mode="YEAR"
      :calendar-type="calendarType"
      :button-label="
        yearName(
          calendarType === START_CALENDAR ? startCurrentDate : endCurrentDate,
          MONTH
        )
      "
      @set-view="setViewMode"
      @prev="onClickPrev"
      @next="onClickNext"
    />

    <div class="grid w-full grid-cols-3 gap-x-3 gap-y-2 auto-rows-[61px]">
      <button
        v-for="(month, index) in months"
        :key="index"
        class="p-2 text-sm font-medium text-center text-slate-800 dark:text-slate-50 w-[92px] h-10 rounded-lg py-2.5 px-2 hover:bg-slate-75 dark:hover:bg-slate-700"
        :class="{
          'bg-woot-600 dark:bg-woot-600 text-white dark:text-white hover:bg-woot-500 dark:bg-woot-700':
            index === activeMonthIndex,
        }"
        @click="selectMonth(index)"
      >
        {{ month }}
      </button>
    </div>
  </div>
</template>
