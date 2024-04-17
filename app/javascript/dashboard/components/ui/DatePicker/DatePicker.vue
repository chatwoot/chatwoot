<script setup>
import { ref, watch } from 'vue';
import { getActiveDateRange } from './helpers/DatePickerHelper';
import {
  format,
  isValid,
  startOfMonth,
  subDays,
  startOfDay,
  endOfDay,
  isBefore,
  subMonths,
  addMonths,
  isSameMonth,
  differenceInCalendarMonths,
  setMonth,
  setYear,
  subYears,
  addYears,
  isAfter,
} from 'date-fns';

import DatePickerButton from './components/DatePickerButton.vue';
import CalendarDateInput from './components/CalendarDateInput.vue';
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

const manualStartDate = ref('');
const manualEndDate = ref('');

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
  }
});

watch(
  [selectedStartDate, selectedEndDate],
  ([newStart, newEnd]) => {
    if (isValid(newStart)) {
      manualStartDate.value = format(newStart, 'dd/MM/yyyy');
    } else {
      manualStartDate.value = '';
    }

    if (isValid(newEnd)) {
      manualEndDate.value = format(newEnd, 'dd/MM/yyyy');
    } else {
      manualEndDate.value = '';
    }
  },
  { immediate: true }
);

// Watcher to ensure dates are always in logical order
watch(
  [startCurrentDate, endCurrentDate],
  ([newStart, newEnd], [oldStart, oldEnd]) => {
    const monthDifference = differenceInCalendarMonths(newEnd, newStart);

    if (newStart !== oldStart) {
      if (isAfter(newStart, newEnd) || monthDifference === 0) {
        // Adjust the end date forward if the start date is adjusted and is after the end date or in the same month
        endCurrentDate.value = addMonths(newStart, 1);
      }
    }
    if (newEnd !== oldEnd) {
      if (isBefore(newEnd, newStart) || monthDifference === 0) {
        // Adjust the start date backward if the end date is adjusted and is before the start date or in the same month
        startCurrentDate.value = subMonths(newEnd, 1);
      }
    }
  },
  { immediate: true, deep: true }
);

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
  if (calendar === 'start') {
    startCurrentDate.value = adjust(startCurrentDate.value, 1);
  } else if (calendar === 'end') {
    endCurrentDate.value = adjust(endCurrentDate.value, 1);
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
  selectedRange.value = 'custom';
  calendarViews.value[calendar] = mode;
};

const openCalendar = (index, calendarType, period = 'month') => {
  const current =
    calendarType === 'start' ? startCurrentDate.value : endCurrentDate.value;
  const newDate =
    period === 'month'
      ? setMonth(startOfMonth(current), index)
      : setYear(current, index);
  if (calendarType === 'start') {
    startCurrentDate.value = newDate;
  } else {
    endCurrentDate.value = newDate;
  }
  setViewMode(calendarType, period === 'month' ? 'week' : 'month');
};

const updateManualInput = (newDate, calendarType) => {
  if (calendarType === 'start') {
    selectedStartDate.value = newDate;
    startCurrentDate.value = newDate;
  } else {
    selectedEndDate.value = newDate;
    endCurrentDate.value = newDate;
  }
};

const handleManualInputError = message => {
  bus.$emit('newToastMessage', message);
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
    bus.$emit('newToastMessage', 'Please select a valid time range');
  } else {
    showDatePicker.value = false;
    emit('change', [selectedStartDate.value, selectedEndDate.value]);
  }
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
      class="flex absolute top-9 ltr:left-0 rtl:right-0 z-30 shadow-md select-none w-[880px] h-[490px] rounded-2xl border border-slate-50 dark:border-slate-800 bg-white dark:bg-slate-800"
    >
      <CalendarDateRange
        :selected-range="selectedRange"
        @set-range="setDateRange"
      />
      <div
        class="flex flex-col w-[680px] ltr:border-l rtl:border-r border-slate-50 dark:border-slate-700/50"
      >
        <div class="flex justify-around h-fit">
          <!-- Calendars for Start and End Dates -->
          <div
            v-for="calendar in ['start', 'end']"
            :key="`${calendar}-calendar`"
            class="flex flex-col items-center"
          >
            <CalendarDateInput
              :calendar-type="calendar"
              :date-value="
                calendar === 'start' ? manualStartDate : manualEndDate
              "
              :compare-date="
                calendar === 'start' ? manualEndDate : manualStartDate
              "
              :is-disabled="selectedRange !== 'custom'"
              @update="
                calendar === 'start'
                  ? (manualStartDate = $event)
                  : (manualEndDate = $event)
              "
              @validate="updateManualInput($event, calendar)"
              @error="handleManualInputError($event)"
            />
            <div class="py-5 border-b border-slate-50 dark:border-slate-700/50">
              <div
                class="flex flex-col items-center gap-2 px-5 min-w-[340px] max-h-[352px]"
                :class="
                  calendar === 'start' &&
                  'ltr:border-r rtl:border-l border-slate-50 dark:border-slate-700/50'
                "
              >
                <CalendarYear
                  v-if="calendarViews[calendar] === 'year'"
                  :calendar-type="calendar"
                  :start-current-date="startCurrentDate"
                  :end-current-date="endCurrentDate"
                  @select-year="openCalendar($event, calendar, 'year')"
                />
                <CalendarMonth
                  v-else-if="calendarViews[calendar] === 'month'"
                  :calendar-type="calendar"
                  :start-current-date="startCurrentDate"
                  :end-current-date="endCurrentDate"
                  @select-month="openCalendar($event, calendar)"
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
          </div>
        </div>
        <CalendarFooter @change="emitDateRange" @clear="resetDatePicker" />
      </div>
    </div>
  </div>
</template>
