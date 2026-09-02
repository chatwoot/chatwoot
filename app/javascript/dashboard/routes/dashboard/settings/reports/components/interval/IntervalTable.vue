<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import format from 'date-fns/format';
import getDay from 'date-fns/getDay';

import { buildIntervalMatrix } from '../../helpers/intervalHelper';
import {
  DAY_LABEL_FORMAT,
  EMPTY_CELL,
  intensityClassFor,
  isWeekend,
} from '../../helpers/matrixCellHelper';

const props = defineProps({
  intervalData: {
    type: Array,
    default: () => [],
  },
});

const HOURS = Array.from(
  { length: 24 },
  (_, hour) => `${String(hour).padStart(2, '0')}:00`
);

const { t } = useI18n();

const matrix = computed(() => buildIntervalMatrix(props.intervalData));
const daysShort = computed(() => [
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.SUNDAY'),
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.MONDAY'),
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.TUESDAY'),
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.WEDNESDAY'),
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.THURSDAY'),
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.FRIDAY'),
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.SATURDAY'),
]);

// The reports API fills every hour in the range, using 0 for hours with no
// conversations, so an absent bucket and a zero bucket render the same way.
const getValue = (hour, dayKey) => matrix.value.values[dayKey]?.[hour] ?? 0;

const getCellClasses = (hour, day) => {
  const value = getValue(hour, day.key);
  if (!value) {
    return isWeekend(day.date)
      ? 'bg-n-slate-2 text-n-slate-11'
      : 'text-n-slate-11';
  }

  return intensityClassFor(value, matrix.value.maxValue);
};

const getConversationLabel = value => {
  if (!value) {
    return t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.NO_CONVERSATIONS');
  }

  return value === 1
    ? t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.CONVERSATION', { count: value })
    : t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.CONVERSATIONS', {
        count: value,
      });
};

const getCellTitle = (hour, day) => {
  const value = getValue(hour, day.key);
  return `${format(day.date, DAY_LABEL_FORMAT)} ${HOURS[hour]}: ${getConversationLabel(value)}`;
};
</script>

<template>
  <div
    class="w-full max-w-full overflow-x-auto rounded-lg border border-n-weak"
  >
    <table
      class="min-w-max border-separate border-spacing-0 text-sm"
      :aria-label="t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.ARIA_LABEL')"
    >
      <thead>
        <tr>
          <th
            scope="col"
            class="sticky start-0 z-20 min-w-20 border-b border-e border-n-weak bg-n-solid-2 px-3 py-2 text-start font-medium text-n-slate-11"
          >
            {{ t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.HOUR') }}
          </th>
          <th
            v-for="day in matrix.days"
            :key="day.key"
            scope="col"
            class="min-w-20 border-b border-e border-n-weak px-3 py-2 text-center font-medium text-n-slate-12"
            :class="isWeekend(day.date) ? 'bg-n-slate-2' : 'bg-n-solid-2'"
          >
            <span class="block text-xs text-n-slate-11">
              {{ daysShort[getDay(day.date)] }}
            </span>
            <span class="block tabular-nums">
              {{ format(day.date, DAY_LABEL_FORMAT) }}
            </span>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(hourLabel, hour) in HOURS" :key="hourLabel">
          <th
            scope="row"
            class="sticky start-0 z-10 min-w-20 border-b border-e border-n-weak bg-n-solid-2 px-3 py-2 text-start text-xs font-medium tabular-nums text-n-slate-11"
          >
            {{ hourLabel }}
          </th>
          <td
            v-for="day in matrix.days"
            :key="day.key"
            class="min-w-20 border-b border-e border-n-weak px-3 py-2 text-center font-medium tabular-nums"
            :class="getCellClasses(hour, day)"
            :title="getCellTitle(hour, day)"
          >
            <span v-if="!getValue(hour, day.key)" class="text-n-slate-10">
              {{ EMPTY_CELL }}
            </span>
            <template v-else>
              {{ getValue(hour, day.key) }}
            </template>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
