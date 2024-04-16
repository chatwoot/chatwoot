<script setup>
import { ref, watch } from 'vue';
import { getActiveDateRange } from './helpers/DatePickerHelper';
import {
  startOfMonth,
  subDays,
  startOfDay,
  endOfDay,
  subMonths,
  addMonths,
  isSameMonth,
  differenceInCalendarMonths,
  setMonth,
  setYear,
  subYears,
  addYears,
} from 'date-fns';

import CalendarDateRange from './components/CalendarDateRange.vue';
import CalendarYear from './components/CalendarYear.vue';
import CalendarMonth from './components/CalendarMonth.vue';
import CalendarWeek from './components/CalendarWeek.vue';
import CalendarFooter from './components/CalendarFooter.vue';

const calendarViews = ref({
  start: 'week',
  end: 'week',
});
const currentDate = ref(new Date());
const startCurrentDate = ref(startOfDay(new Date())); // Today's date at the start of the day (starts the current month)
const endCurrentDate = ref(addMonths(startOfDay(new Date()), 1)); // One month ahead of today at the start of the day (starts the next month)
const selectedStartDate = ref(startOfDay(subDays(new Date(), 6)));
const selectedEndDate = ref(endOfDay(new Date()));
const selectingEndDate = ref(false);
const selectedRange = ref('last7days');
const hoveredEndDate = ref(null);

watch(selectedRange, newRange => {
  if (newRange !== 'custom') {
    startCurrentDate.value = selectedStartDate.value;
    endCurrentDate.value = selectedEndDate.value;
    selectingEndDate.value = false;
  }
});

const setDateRange = range => {
  selectedRange.value = range.value;
  const { start, end } = getActiveDateRange(range.value, currentDate.value);
  if (isSameMonth(start, end)) {
    endCurrentDate.value = startOfMonth(addMonths(start, 1));
  }
  selectedStartDate.value = start;
  selectedEndDate.value = end;
};

const previousMonth = calendar => {
  // If adjusting the start calendar, move both calendars back one month.
  if (calendar === 'start') {
    startCurrentDate.value = subMonths(startCurrentDate.value, 1);
    endCurrentDate.value = subMonths(endCurrentDate.value, 1);
  }
  // If adjusting the end calendar, check the relationship between start and end calendar months.
  else if (
    differenceInCalendarMonths(endCurrentDate.value, startCurrentDate.value) > 1
  ) {
    // Move only the end calendar back if it's more than one month ahead of the start calendar.
    endCurrentDate.value = subMonths(endCurrentDate.value, 1);
  } else {
    // Move both calendars back if the end calendar is just one month ahead of the start calendar.
    startCurrentDate.value = subMonths(startCurrentDate.value, 1);
    endCurrentDate.value = subMonths(endCurrentDate.value, 1);
  }
};

const nextMonth = calendar => {
  // If adjusting the start calendar forward, only do so if it's not the month immediately before the end calendar.
  if (
    calendar === 'start' &&
    differenceInCalendarMonths(endCurrentDate.value, startCurrentDate.value) > 1
  ) {
    startCurrentDate.value = addMonths(startCurrentDate.value, 1);
  }
  // Move both calendars forward if the start calendar is just one month behind the end calendar.
  else if (calendar === 'start') {
    startCurrentDate.value = addMonths(startCurrentDate.value, 1);
    endCurrentDate.value = addMonths(endCurrentDate.value, 1);
  }
  // If adjusting the end calendar, move it forward one month.
  else if (calendar === 'end') {
    endCurrentDate.value = addMonths(endCurrentDate.value, 1);
  }
};

const previousYear = calendarType => {
  const current =
    calendarType === 'start' ? startCurrentDate.value : endCurrentDate.value;
  const newDate = subYears(current, 1);
  if (calendarType === 'start') {
    startCurrentDate.value = newDate;
  } else {
    endCurrentDate.value = newDate;
  }
};

const nextYear = calendarType => {
  const current =
    calendarType === 'start' ? startCurrentDate.value : endCurrentDate.value;
  const newDate = addYears(current, 1);
  if (calendarType === 'start') {
    startCurrentDate.value = newDate;
  } else {
    endCurrentDate.value = newDate;
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

const openMonth = (monthIndex, calenderType) => {
  const current =
    calenderType === 'start' ? startCurrentDate.value : endCurrentDate.value;
  const newDate = setMonth(startOfMonth(current), monthIndex);
  if (calenderType === 'start') {
    startCurrentDate.value = newDate;
  } else {
    endCurrentDate.value = newDate;
  }
  setViewMode(calenderType, 'week');
};

const openYear = (year, calenderType) => {
  const current =
    calenderType === 'start' ? startCurrentDate.value : endCurrentDate.value;
  const newDate = setYear(current, year);
  if (calenderType === 'start') {
    startCurrentDate.value = newDate;
  } else {
    endCurrentDate.value = newDate;
  }
  setViewMode(calenderType, 'month');
};

const resetDatePicker = () => {
  // Reset the start and end dates to default values
  startCurrentDate.value = startOfDay(new Date()); // Resets to today at start of the day
  endCurrentDate.value = addMonths(startOfDay(new Date()), 1); // Resets to one month ahead

  // Reset selected start and end dates
  selectedStartDate.value = startOfDay(subDays(new Date(), 6));
  selectedEndDate.value = endOfDay(new Date());

  // Resetting selectingEndDate and any other flags
  selectingEndDate.value = false;

  // Reset selected range
  selectedRange.value = 'last7days';

  // Reset view modes if they are being used to toggle between different calendar views
  calendarViews.value.start = 'week';
  calendarViews.value.end = 'week';
};
</script>

<template>
  <div
    class="flex absolute top-32 z-30 shadow-md select-none max-w-[880px] h-full w-full max-h-[490px] divide-x divide-slate-50 dark:divide-slate-700/50 font-inter rounded-2xl border border-slate-50 dark:border-slate-800 bg-white dark:bg-slate-800"
  >
    <!-- Custom date range picker to the left -->
    <CalendarDateRange
      :selected-range="selectedRange"
      @set-range="setDateRange"
    />
    <div class="flex flex-col w-[680px]">
      <div class="h-[82px] w-full" />
      <div
        class="flex justify-around py-5 border-b divide-x h-fit divide-slate-50 dark:divide-slate-700/50 border-slate-50 dark:border-slate-700/50"
      >
        <!-- Calendars for Start and End Dates -->
        <div
          v-for="calendar in ['start', 'end']"
          :key="calendar + '-calendar'"
          class="flex flex-col items-center gap-2 px-5 min-w-[340px] max-h-[352px]"
        >
          <CalendarYear
            v-if="calendarViews[calendar] === 'year'"
            :calendar-type="calendar"
            :start-current-date="startCurrentDate"
            :end-current-date="endCurrentDate"
            @select-year="openYear"
          />
          <CalendarMonth
            v-else-if="calendarViews[calendar] === 'month'"
            :calendar-type="calendar"
            :start-current-date="startCurrentDate"
            :end-current-date="endCurrentDate"
            @select-month="openMonth"
            @set-view="setViewMode"
            @prev="previousYear"
            @next="nextYear"
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
            @prev="previousMonth"
            @next="nextMonth"
          />
        </div>
      </div>
      <CalendarFooter @clear="resetDatePicker" />
    </div>
  </div>
</template>
