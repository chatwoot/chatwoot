<script setup>
import { ref, computed } from 'vue';
import {
  startOfMonth,
  addMonths,
  subMonths,
  startOfDay,
  isSameDay,
  addHours,
  addYears,
  subYears,
  setMonth,
  setYear,
} from 'date-fns';
import { CALENDAR_PERIODS } from './helpers/DatePickerHelper';
import CalendarYear from './components/CalendarYear.vue';
import CalendarMonth from './components/CalendarMonth.vue';
import CalendarWeek from './components/CalendarWeek.vue';
import CalendarFooter from './components/CalendarFooter.vue';
import TimePicker from './components/TimePicker.vue';

const props = defineProps({
  minDate: {
    type: Date,
    default: null,
  },
});

const emit = defineEmits(['apply', 'clear']);

const { WEEK, MONTH, YEAR } = CALENDAR_PERIODS;

const currentDate = ref(new Date());
const selectedDate = ref(null);

const getCurrentTime = () => {
  const now = new Date();
  return {
    hour: now.getHours(),
    minute: now.getMinutes(),
    second: now.getSeconds(),
  };
};

const selectedTime = ref(getCurrentTime());
const calendarView = ref(WEEK);
const calendarDate = ref(startOfMonth(currentDate.value));

const getMinTimeForToday = () => addHours(new Date(), 1);

const effectiveMinDate = computed(() => {
  const thresholdDay = startOfDay(getMinTimeForToday());
  if (!props.minDate) return thresholdDay;
  const propDay = startOfDay(props.minDate);
  return propDay > thresholdDay ? propDay : thresholdDay;
});

const minTime = computed(() => {
  if (!selectedDate.value) return null;
  if (!isSameDay(selectedDate.value, effectiveMinDate.value)) return null;
  return getMinTimeForToday();
});

const selectedDateTime = computed(() => {
  if (!selectedDate.value) return null;
  const date = new Date(selectedDate.value);
  date.setHours(
    selectedTime.value.hour,
    selectedTime.value.minute,
    selectedTime.value.second,
    0
  );
  return date;
});

const selectDate = day => {
  selectedDate.value = startOfDay(day);
  if (isSameDay(day, effectiveMinDate.value)) {
    const threshold = getMinTimeForToday();
    selectedTime.value = {
      hour: threshold.getHours(),
      minute: threshold.getMinutes(),
      second: 0,
    };
  } else {
    selectedTime.value = { hour: 0, minute: 0, second: 0 };
  }
};

const moveCalendar = (direction, period = MONTH) => {
  const adjust =
    period === YEAR
      ? { prev: subYears, next: addYears }
      : { prev: subMonths, next: addMonths };
  calendarDate.value = adjust[direction](calendarDate.value, 1);
};

const setViewMode = (_type, mode) => {
  calendarView.value = mode;
};

const openCalendar = (index, _type, period = MONTH) => {
  calendarDate.value =
    period === MONTH
      ? setMonth(startOfMonth(calendarDate.value), index)
      : setYear(calendarDate.value, index);
  calendarView.value = period === MONTH ? WEEK : MONTH;
};

const onApply = () => {
  if (selectedDateTime.value) {
    emit('apply', selectedDateTime.value);
  }
};

const isDefaultState = computed(
  () => !selectedDate.value && calendarView.value === WEEK
);

const resetState = () => {
  selectedDate.value = null;
  selectedTime.value = getCurrentTime();
  calendarDate.value = startOfMonth(currentDate.value);
  calendarView.value = WEEK;
};

const onClear = () => {
  if (isDefaultState.value) {
    emit('clear');
    return;
  }
  resetState();
};

defineExpose({ resetState });
</script>

<template>
  <div class="flex flex-col select-none font-inter">
    <div class="flex w-full gap-3 justify-between">
      <div class="flex justify-center py-5">
        <div class="flex flex-col items-center gap-2 min-w-[300px]">
          <CalendarYear
            v-if="calendarView === YEAR"
            :start-current-date="calendarDate"
            @select-year="openCalendar($event, null, YEAR)"
          />
          <CalendarMonth
            v-else-if="calendarView === MONTH"
            :start-current-date="calendarDate"
            @select-month="openCalendar($event)"
            @set-view="setViewMode"
            @prev="moveCalendar('prev', YEAR)"
            @next="moveCalendar('next', YEAR)"
          />
          <CalendarWeek
            v-else
            :current-date="currentDate"
            :start-current-date="calendarDate"
            :selected-start-date="selectedDate"
            :selected-end-date="selectedDate"
            :min-date="effectiveMinDate"
            @select-date="selectDate"
            @set-view="setViewMode"
            @prev="moveCalendar('prev')"
            @next="moveCalendar('next')"
          />
        </div>
      </div>
      <div
        class="flex justify-center py-2 w-full transition-opacity ltr:border-l rtl:border-r border-n-strong"
        :class="selectedDate ? 'opacity-100' : 'opacity-40 pointer-events-none'"
      >
        <TimePicker v-model="selectedTime" :min-time="minTime" />
      </div>
    </div>
    <div class="border-t border-n-strong">
      <CalendarFooter @change="onApply" @clear="onClear" />
    </div>
  </div>
</template>
