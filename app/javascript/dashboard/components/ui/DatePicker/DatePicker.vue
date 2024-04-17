<script setup>
import { ref, watch } from 'vue';
import { getActiveDateRange } from './helpers/DatePickerHelper';
import {
  isValid,
  startOfMonth,
  subDays,
  startOfDay,
  endOfDay,
  subMonths,
  addMonths,
  isSameMonth,
  differenceInCalendarMonths,
  differenceInCalendarYears,
  setMonth,
  setYear,
  subYears,
  addYears,
} from 'date-fns';

import DatePickerButton from './components/DatePickerButton.vue';
import CalendarDateRange from './components/CalendarDateRange.vue';
import CalendarYear from './components/CalendarYear.vue';
import CalendarMonth from './components/CalendarMonth.vue';
import CalendarWeek from './components/CalendarWeek.vue';
import CalendarFooter from './components/CalendarFooter.vue';

const showDatePicker = ref(false);
const calendarViews = ref({ start: 'week', end: 'week' });
const currentDate = ref(new Date());

const startCurrentDate = ref(startOfDay(currentDate.value)); // Today's date at the start of the day (starts the current month)
const endCurrentDate = ref(addMonths(startOfDay(currentDate.value), 1)); // One month ahead of today at the start of the day (starts the next month)
const selectedStartDate = ref(startOfDay(subDays(currentDate.value, 6)));
const selectedEndDate = ref(endOfDay(currentDate.value));
const selectingEndDate = ref(false);
const selectedRange = ref('last7days');
const hoveredEndDate = ref(null);

const emit = defineEmits(['change']);

watch(selectedRange, newRange => {
  if (newRange !== 'custom') {
    const isLast7days = newRange === 'last7days';
    startCurrentDate.value = selectedStartDate.value;
    endCurrentDate.value =
      isLast7days && isSameMonth(selectedStartDate.value, selectedEndDate.value)
        ? startOfMonth(addMonths(selectedStartDate.value, 1))
        : selectedEndDate.value;
    selectingEndDate.value = false;
  } else if (!selectingEndDate.value) {
    startCurrentDate.value = startOfDay(currentDate.value);
    endCurrentDate.value = addMonths(startOfDay(currentDate.value), 1);
  }
});

const setDateRange = range => {
  selectedRange.value = range.value;
  const { start, end } = getActiveDateRange(range.value, currentDate.value);
  selectedStartDate.value = start;
  selectedEndDate.value = end;
};

const moveCalendar = (calendar, direction, period = 'month') => {
  const adjustFunctions = {
    month: { prev: subMonths, next: addMonths },
    year: { prev: subYears, next: addYears },
  };

  const adjust = adjustFunctions[period][direction];
  const differenceFn =
    period === 'month' ? differenceInCalendarMonths : differenceInCalendarYears;

  const difference = differenceFn(endCurrentDate.value, startCurrentDate.value);

  if (calendar === 'start') {
    startCurrentDate.value = adjust(startCurrentDate.value, 1);
    if (direction === 'next' && difference <= 1) {
      endCurrentDate.value = adjust(
        endCurrentDate.value,
        difference === 0 ? 2 : 1
      );
    }
  } else if (calendar === 'end') {
    endCurrentDate.value = adjust(endCurrentDate.value, 1);
    if (direction === 'prev' && difference <= 1) {
      startCurrentDate.value = adjust(
        startCurrentDate.value,
        difference === 0 ? 2 : 1
      );
    }
  }
};

const selectDate = day => {
  selectedRange.value = 'custom';
  if (!selectingEndDate.value || day < selectedStartDate.value) {
    selectedStartDate.value = day;
    selectedEndDate.value = null;
    selectingEndDate.value = true;
  } else {
    selectedEndDate.value = day;
    selectingEndDate.value = false;
  }
};

const setViewMode = (calendar, mode) => {
  calendarViews.value[calendar] = mode;
};

const openCalender = (index, calenderType, period = 'month') => {
  const current =
    calenderType === 'start' ? startCurrentDate.value : endCurrentDate.value;
  const isPeriodMonth = period === 'month';
  const newDate = isPeriodMonth
    ? setMonth(startOfMonth(current), index)
    : setYear(current, index);
  const viewMode = isPeriodMonth ? 'week' : 'month';

  if (calenderType === 'start') {
    startCurrentDate.value = newDate;
  } else {
    endCurrentDate.value = newDate;
  }
  setViewMode(calenderType, viewMode);
};

const resetDatePicker = () => {
  startCurrentDate.value = startOfDay(currentDate.value); // Resets to today at start of the day
  endCurrentDate.value = addMonths(startOfDay(currentDate.value), 1); // Resets to one month ahead
  selectedStartDate.value = startOfDay(subDays(currentDate.value, 6));
  selectedEndDate.value = endOfDay(currentDate.value);
  selectingEndDate.value = false;
  selectedRange.value = 'last7days';
  // Reset view modes if they are being used to toggle between different calendar views
  calendarViews.value = { start: 'week', end: 'week' };
};

const emitDateRange = () => {
  if (!isValid(selectedStartDate.value) || !isValid(selectedEndDate.value)) {
    return bus.$emit('newToastMessage', 'Please select a valid time range');
  }
  showDatePicker.value = false;
  return emit('change', [selectedStartDate.value, selectedEndDate.value]);
};
</script>

<template>
  <div class="relative font-inter">
    <DatePickerButton
      :selected-start-date="selectedStartDate"
      :selected-end-date="selectedEndDate"
      :selected-range="selectedRange"
      @open="showDatePicker = !showDatePicker"
    />
    <div
      v-if="showDatePicker"
      class="flex absolute top-9 left-0 z-30 shadow-md select-none w-[880px] h-[408px] divide-x divide-slate-50 dark:divide-slate-700/50 rounded-2xl border border-slate-50 dark:border-slate-800 bg-white dark:bg-slate-800"
    >
      <CalendarDateRange
        :selected-range="selectedRange"
        @set-range="setDateRange"
      />
      <div class="flex flex-col w-[680px]">
        <!-- <div class="h-[82px] w-full"  h-[490px] wrapper add input/> -->
        <div
          class="flex justify-around py-5 border-b divide-x h-fit divide-slate-50 dark:divide-slate-700/50 border-slate-50 dark:border-slate-700/50"
        >
          <!-- Calendars for Start and End Dates -->
          <div
            v-for="calendar in ['start', 'end']"
            :key="`${calendar}-calendar`"
            class="flex flex-col items-center gap-2 px-5 min-w-[340px] max-h-[352px]"
          >
            <CalendarYear
              v-if="calendarViews[calendar] === 'year'"
              :calendar-type="calendar"
              :start-current-date="startCurrentDate"
              :end-current-date="endCurrentDate"
              @select-year="openCalender($event, calendar, 'year')"
            />
            <CalendarMonth
              v-else-if="calendarViews[calendar] === 'month'"
              :calendar-type="calendar"
              :start-current-date="startCurrentDate"
              :end-current-date="endCurrentDate"
              @select-month="openCalender($event, calendar)"
              @set-view="setViewMode"
              @prev="moveCalendar(calendar, 'prev', 'year')"
              @next="moveCalendar(calendar, 'next', 'year')"
            />
            <CalendarWeek
              v-else-if="calendarViews[calendar] === 'week'"
              :calendar-type="calendar"
              :current-date="currentDate"
              :start-current-date="startCurrentDate"
              :end-current-date="endCurrentDate"
              :selected-start-date="selectedStartDate"
              :selected-end-date="selectedEndDate"
              :selecting-end-date="selectingEndDate"
              :hovered-end-date="hoveredEndDate"
              @update-hovered-end-date="hoveredEndDate = $event"
              @select-date="selectDate"
              @set-view="setViewMode"
              @prev="moveCalendar(calendar, 'prev')"
              @next="moveCalendar(calendar, 'next')"
            />
          </div>
        </div>
        <CalendarFooter @change="emitDateRange" @clear="resetDatePicker" />
      </div>
    </div>
  </div>
</template>
