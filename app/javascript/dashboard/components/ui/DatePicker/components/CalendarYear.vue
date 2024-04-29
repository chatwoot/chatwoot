<script setup>
import { ref, computed } from 'vue';
import { getYear, addYears, subYears } from 'date-fns';
import { CALENDAR_TYPES } from '../helpers/DatePickerHelper';

import CalendarAction from './CalendarAction.vue';

const props = defineProps({
  calendarType: {
    type: String,
    default: 'start',
  },
  startCurrentDate: Date,
  endCurrentDate: Date,
});

const { START_CALENDAR } = CALENDAR_TYPES;

const calculateStartYear = date => {
  const year = getYear(date);
  return year - (year % 10); // Align with the beginning of a decade
};

const startYear = ref(
  calculateStartYear(
    props.calendarType === START_CALENDAR
      ? props.startCurrentDate
      : props.endCurrentDate
  )
);

const years = computed(() =>
  Array.from({ length: 10 }, (_, i) => startYear.value + i)
);

const firstYear = computed(() => years.value[0]);
const lastYear = computed(() => years.value[years.value.length - 1]);

const activeYear = computed(() => {
  const date =
    props.calendarType === START_CALENDAR
      ? props.startCurrentDate
      : props.endCurrentDate;
  return getYear(date);
});

const onClickPrev = () => {
  startYear.value = subYears(new Date(startYear.value, 0, 1), 10).getFullYear();
};

const onClickNext = () => {
  startYear.value = addYears(new Date(startYear.value, 0, 1), 10).getFullYear();
};

const emit = defineEmits(['select-year']);

const selectYear = year => {
  emit('select-year', year);
};
</script>

<template>
  <div class="flex flex-col w-full gap-2 max-h-[312px]">
    <CalendarAction
      :calendar-type="calendarType"
      :button-label="`${firstYear} - ${lastYear}`"
      @prev="onClickPrev"
      @next="onClickNext"
    />

    <div class="grid grid-cols-2 gap-x-3 gap-y-2 w-full auto-rows-[47px]">
      <button
        v-for="year in years"
        :key="year"
        class="p-2 text-sm font-medium text-center text-slate-800 dark:text-slate-50 w-[144px] h-10 rounded-lg py-2.5 px-2 hover:bg-slate-75 dark:hover:bg-slate-700"
        :class="{
          'bg-woot-600 dark:bg-woot-600 text-white dark:text-white hover:bg-woot-500 dark:hover:bg-woot-700':
            year === activeYear,
        }"
        @click="selectYear(year)"
      >
        {{ year }}
      </button>
    </div>
  </div>
</template>
