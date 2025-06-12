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

const emit = defineEmits(['selectYear']);

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

const selectYear = year => {
  emit('selectYear', year);
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
        class="p-2 text-sm font-medium text-center text-n-slate-12 w-[144px] h-10 rounded-lg py-2.5 px-2"
        :class="{
          'bg-n-brand text-white hover:bg-n-blue-10': year === activeYear,
          'hover:bg-n-alpha-2 dark:hover:bg-n-solid-3': year !== activeYear,
        }"
        @click="selectYear(year)"
      >
        {{ year }}
      </button>
    </div>
  </div>
</template>
