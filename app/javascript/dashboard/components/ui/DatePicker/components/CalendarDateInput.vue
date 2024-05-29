<script setup>
import { computed } from 'vue';
import { parse, isValid, isAfter, isBefore } from 'date-fns';
import {
  getIntlDateFormatForLocale,
  CALENDAR_TYPES,
} from '../helpers/DatePickerHelper';

const props = defineProps({
  calendarType: {
    type: String,
    default: '',
  },
  dateValue: Date,
  compareDate: Date,
  isDisabled: Boolean,
});

const emit = defineEmits(['update', 'validate', 'error']);

const { START_CALENDAR, END_CALENDAR } = CALENDAR_TYPES;

const dateFormat = computed(() => getIntlDateFormatForLocale()?.toUpperCase());

const localDateValue = computed({
  get: () => props.dateValue?.toLocaleDateString(navigator.language) || '',
  set: newValue => {
    const format = getIntlDateFormatForLocale();
    const parsedDate = parse(newValue, format, new Date());
    if (isValid(parsedDate)) {
      emit('update', parsedDate);
    }
  },
});

const validateDate = () => {
  if (!isValid(props.dateValue)) {
    emit('error', `Please enter the date in valid format: ${dateFormat.value}`);
    return;
  }

  const { calendarType, compareDate, dateValue } = props;
  const isStartCalendar = calendarType === START_CALENDAR;
  const isEndCalendar = calendarType === END_CALENDAR;

  if (compareDate && isStartCalendar && isAfter(dateValue, compareDate)) {
    emit('error', 'Start date must be before the end date.');
  } else if (compareDate && isEndCalendar && isBefore(dateValue, compareDate)) {
    emit('error', 'End date must be after the start date.');
  } else {
    emit('validate', dateValue);
  }
};
</script>

<template>
  <div class="h-[82px] flex flex-col items-start px-5 gap-1.5 pt-4 w-full">
    <span class="text-sm font-medium text-slate-800 dark:text-slate-50">
      {{
        calendarType === START_CALENDAR
          ? $t('DATE_PICKER.DATE_RANGE_INPUT.START')
          : $t('DATE_PICKER.DATE_RANGE_INPUT.END')
      }}
    </span>
    <input
      v-model="localDateValue"
      type="text"
      class="reset-base border bg-slate-25 dark:bg-slate-900 ring-offset-ash-900 border-slate-50 dark:border-slate-700/50 w-full disabled:text-slate-200 dark:disabled:text-slate-700 disabled:cursor-not-allowed text-slate-800 dark:text-slate-50 px-1.5 py-1 text-sm rounded-xl h-10"
      :placeholder="dateFormat"
      :disabled="isDisabled"
      @keypress.enter="validateDate"
    />
  </div>
</template>
