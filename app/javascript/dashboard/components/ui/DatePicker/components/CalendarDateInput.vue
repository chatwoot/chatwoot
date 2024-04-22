<script setup>
import { parseDateFromDMY } from '../helpers/DatePickerHelper';

import { isValid, startOfDay, endOfDay, isBefore, isAfter } from 'date-fns';

const props = defineProps({
  calendarType: {
    type: String,
    default: '',
  },
  dateValue: {
    type: String,
    default: '',
  },
  compareDate: {
    type: String,
    default: '',
  },
  isDisabled: Boolean,
});

const emit = defineEmits(['update', 'validate', 'error']);

const updateDate = newValue => {
  emit('update', newValue);
};

const validateDate = dateString => {
  const parsedDate = parseDateFromDMY(dateString);

  if (!isValid(parsedDate)) {
    emit('error', 'Please select a valid time range');
    return;
  }

  if (props.calendarType === 'start') {
    if (
      props.compareDate &&
      isAfter(parsedDate, parseDateFromDMY(props.compareDate))
    ) {
      emit('error', 'Start date must be before end date');
    } else {
      emit('validate', startOfDay(parsedDate));
    }
  } else if (
    props.compareDate &&
    isBefore(parsedDate, parseDateFromDMY(props.compareDate))
  ) {
    emit('error', 'End date must be after start date');
  } else {
    emit('validate', endOfDay(parsedDate));
  }
};
</script>

<template>
  <div class="h-[82px] flex flex-col items-start px-5 gap-1.5 pt-4 w-full">
    <span class="text-sm font-medium text-slate-800 dark:text-slate-50">
      {{
        calendarType === 'start'
          ? $t('DATE_PICKER.DATE_RANGE_INPUT.START')
          : $t('DATE_PICKER.DATE_RANGE_INPUT.END')
      }}
    </span>
    <input
      type="text"
      :value="dateValue"
      class="reset-base border bg-slate-25 dark:bg-slate-900 border-slate-50 dark:border-slate-700/50 w-full disabled:text-slate-200 dark:disabled:text-slate-700 disabled:cursor-not-allowed text-slate-800 dark:text-slate-50 px-1.5 py-1 text-sm rounded-xl h-10"
      placeholder="DD/MM/YYYY"
      :disabled="isDisabled"
      @input="updateDate($event.target.value)"
      @change="validateDate($event.target.value)"
    />
  </div>
</template>
