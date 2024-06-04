<script setup>
import { ref, watch } from 'vue';
import {
  getActiveDateRange,
  moveCalendarDate,
  DATE_RANGE_TYPES,
  CALENDAR_TYPES,
  CALENDAR_PERIODS,
} from './helpers/DatePickerHelper';
import {
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
  isAfter,
} from 'date-fns';
import { useAlert } from 'dashboard/composables';
import DatePickerButton from './components/DatePickerButton.vue';
import CalendarDateInput from './components/CalendarDateInput.vue';
import CalendarDateRange from './components/CalendarDateRange.vue';
import CalendarYear from './components/CalendarYear.vue';
import CalendarMonth from './components/CalendarMonth.vue';
import CalendarWeek from './components/CalendarWeek.vue';
import CalendarFooter from './components/CalendarFooter.vue';

const { LAST_7_DAYS, LAST_30_DAYS, CUSTOM_RANGE } = DATE_RANGE_TYPES;
const { START_CALENDAR, END_CALENDAR } = CALENDAR_TYPES;
const { WEEK, MONTH, YEAR } = CALENDAR_PERIODS;

const showDatePicker = ref(false);
const calendarViews = ref({ start: WEEK, end: WEEK });
const currentDate = ref(new Date());
const selectedStartDate = ref(startOfDay(subDays(currentDate.value, 6))); // LAST_7_DAYS
const selectedEndDate = ref(endOfDay(currentDate.value));
// Setting the start and end calendar
const startCurrentDate = ref(startOfDay(selectedStartDate.value));
const endCurrentDate = ref(
  isSameMonth(selectedStartDate.value, selectedEndDate.value)
    ? startOfMonth(addMonths(selectedEndDate.value, 1)) // Moves to the start of the next month if dates are in the same month (Mounted case LAST_7_DAYS)
    : startOfMonth(selectedEndDate.value) // Always shows the month of the end date starting from the first (Mounted case LAST_7_DAYS)
);
const selectingEndDate = ref(false);
const selectedRange = ref(LAST_7_DAYS);
const hoveredEndDate = ref(null);

const manualStartDate = ref(selectedStartDate.value);
const manualEndDate = ref(selectedEndDate.value);

const emit = defineEmits(['change']);

// Watcher will set the start and end dates based on the selected range
watch(selectedRange, newRange => {
  if (newRange !== CUSTOM_RANGE) {
    // If selecting a range other than last 7 days or last 30 days, set the start and end dates to the selected start and end dates
    // If selecting last 7 days or last 30 days is, set the start date to the selected start date
    // and the end date to one month ahead of the start date if the start date and end date are in the same month
    // Otherwise set the end date to the selected end date
    const isLastSevenOrThirtyDays =
      newRange === LAST_7_DAYS || newRange === LAST_30_DAYS;
    startCurrentDate.value = selectedStartDate.value;
    endCurrentDate.value =
      isLastSevenOrThirtyDays &&
      isSameMonth(selectedStartDate.value, selectedEndDate.value)
        ? startOfMonth(addMonths(selectedStartDate.value, 1))
        : selectedEndDate.value;
    selectingEndDate.value = false;
  } else if (!selectingEndDate.value) {
    // If selecting a custom range and not selecting an end date, set the start date to the selected start date
    startCurrentDate.value = startOfDay(currentDate.value);
  }
});

// Watcher will set the input values based on the selected start and end dates
watch(
  [selectedStartDate, selectedEndDate],
  ([newStart, newEnd]) => {
    if (isValid(newStart)) {
      manualStartDate.value = newStart;
    } else {
      manualStartDate.value = selectedStartDate.value;
    }

    if (isValid(newEnd)) {
      manualEndDate.value = newEnd;
    } else {
      manualEndDate.value = selectedEndDate.value;
    }
  },
  { immediate: true }
);

// Watcher to ensure dates are always in logical order
// This watch is will ensure that the start date is always before the end date
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

const moveCalendar = (calendar, direction, period = MONTH) => {
  const { start, end } = moveCalendarDate(
    calendar,
    startCurrentDate.value,
    endCurrentDate.value,
    direction,
    period
  );
  startCurrentDate.value = start;
  endCurrentDate.value = end;
};

const selectDate = day => {
  selectedRange.value = CUSTOM_RANGE;
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
  selectedRange.value = CUSTOM_RANGE;
  calendarViews.value[calendar] = mode;
};

const openCalendar = (index, calendarType, period = MONTH) => {
  const current =
    calendarType === START_CALENDAR
      ? startCurrentDate.value
      : endCurrentDate.value;
  const newDate =
    period === MONTH
      ? setMonth(startOfMonth(current), index)
      : setYear(current, index);
  if (calendarType === START_CALENDAR) {
    startCurrentDate.value = newDate;
  } else {
    endCurrentDate.value = newDate;
  }
  setViewMode(calendarType, period === MONTH ? WEEK : MONTH);
};

const updateManualInput = (newDate, calendarType) => {
  if (calendarType === START_CALENDAR) {
    selectedStartDate.value = newDate;
    startCurrentDate.value = newDate;
  } else {
    selectedEndDate.value = newDate;
    endCurrentDate.value = newDate;
  }
  selectingEndDate.value = false;
};

const handleManualInputError = message => {
  useAlert(message);
};

const resetDatePicker = () => {
  startCurrentDate.value = startOfDay(currentDate.value); // Resets to today at start of the day
  endCurrentDate.value = addMonths(startOfDay(currentDate.value), 1); // Resets to one month ahead
  selectedStartDate.value = startOfDay(subDays(currentDate.value, 6));
  selectedEndDate.value = endOfDay(currentDate.value);
  selectingEndDate.value = false;
  selectedRange.value = LAST_7_DAYS;
  // Reset view modes if they are being used to toggle between different calendar views
  calendarViews.value = { start: WEEK, end: WEEK };
};

const emitDateRange = () => {
  if (!isValid(selectedStartDate.value) || !isValid(selectedEndDate.value)) {
    useAlert('Please select a valid time range');
  } else {
    showDatePicker.value = false;
    emit('dateRangeChanged', [selectedStartDate.value, selectedEndDate.value]);
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
            v-for="calendar in [START_CALENDAR, END_CALENDAR]"
            :key="`${calendar}-calendar`"
            class="flex flex-col items-center"
          >
            <CalendarDateInput
              :calendar-type="calendar"
              :date-value="
                calendar === START_CALENDAR ? manualStartDate : manualEndDate
              "
              :compare-date="
                calendar === START_CALENDAR ? manualEndDate : manualStartDate
              "
              :is-disabled="selectedRange !== CUSTOM_RANGE"
              @update="
                calendar === START_CALENDAR
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
                  calendar === START_CALENDAR &&
                  'ltr:border-r rtl:border-l border-slate-50 dark:border-slate-700/50'
                "
              >
                <CalendarYear
                  v-if="calendarViews[calendar] === YEAR"
                  :calendar-type="calendar"
                  :start-current-date="startCurrentDate"
                  :end-current-date="endCurrentDate"
                  @select-year="openCalendar($event, calendar, YEAR)"
                />
                <CalendarMonth
                  v-else-if="calendarViews[calendar] === MONTH"
                  :calendar-type="calendar"
                  :start-current-date="startCurrentDate"
                  :end-current-date="endCurrentDate"
                  @select-month="openCalendar($event, calendar)"
                  @set-view="setViewMode"
                  @prev="moveCalendar(calendar, 'prev', YEAR)"
                  @next="moveCalendar(calendar, 'next', YEAR)"
                />
                <CalendarWeek
                  v-else-if="calendarViews[calendar] === WEEK"
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
