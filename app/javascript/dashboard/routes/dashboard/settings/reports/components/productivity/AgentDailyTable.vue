<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import format from 'date-fns/format';
import getDay from 'date-fns/getDay';
import parseISO from 'date-fns/parseISO';

import {
  DAY_LABEL_FORMAT,
  EMPTY_CELL,
  intensityClassFor,
  isWeekend,
} from '../../helpers/matrixCellHelper';

const props = defineProps({
  agents: {
    type: Array,
    default: () => [],
  },
  days: {
    type: Array,
    default: () => [],
  },
  matrix: {
    type: Array,
    default: () => [],
  },
});

const { t } = useI18n();

const parsedDays = computed(() =>
  props.days.map(day => ({ key: day, date: parseISO(day) }))
);
const maxValue = computed(() => Math.max(0, ...props.matrix.flat()));
const daysShort = computed(() => [
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.SUNDAY'),
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.MONDAY'),
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.TUESDAY'),
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.WEDNESDAY'),
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.THURSDAY'),
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.FRIDAY'),
  t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.DAYS_SHORT.SATURDAY'),
]);

const getValue = (agentIndex, dayIndex) =>
  props.matrix[agentIndex]?.[dayIndex] ?? 0;

const getCellClasses = (agentIndex, dayIndex, day) => {
  const value = getValue(agentIndex, dayIndex);
  if (!value) {
    return isWeekend(day.date)
      ? 'bg-n-slate-2 text-n-slate-11'
      : 'text-n-slate-11';
  }

  return intensityClassFor(value, maxValue.value);
};

const getCellTitle = (agent, day, value) =>
  `${agent.name} · ${day.key} · ${value}`;
</script>

<template>
  <div
    class="w-full max-w-full overflow-auto rounded-lg border border-n-weak max-h-[30rem]"
    tabindex="0"
    role="region"
    :aria-label="t('OVERVIEW_REPORTS.AGENT_DAILY.ARIA_LABEL')"
  >
    <table
      class="min-w-max border-separate border-spacing-0 text-sm"
      :aria-label="t('OVERVIEW_REPORTS.AGENT_DAILY.ARIA_LABEL')"
    >
      <thead>
        <tr>
          <th
            scope="col"
            class="sticky start-0 top-0 z-30 min-w-48 border-b border-e border-n-weak bg-n-solid-2 px-3 py-2 text-start font-medium text-n-slate-11"
          >
            {{ t('OVERVIEW_REPORTS.AGENT_DAILY.AGENT') }}
          </th>
          <th
            v-for="day in parsedDays"
            :key="day.key"
            scope="col"
            class="sticky top-0 z-20 min-w-20 border-b border-e border-n-weak px-3 py-2 text-center font-medium text-n-slate-12"
            :class="isWeekend(day.date) ? 'bg-n-slate-2' : 'bg-n-solid-2'"
          >
            <span class="block text-xs text-n-slate-11">
              {{ daysShort[getDay(day.date)] }}
            </span>
            <span class="block tabular-nums">
              {{ format(day.date, DAY_LABEL_FORMAT) }}
            </span>
          </th>
          <th
            scope="col"
            class="sticky end-0 top-0 z-30 min-w-20 border-b border-s border-n-weak bg-n-solid-2 px-3 py-2 text-end font-semibold text-n-slate-12"
          >
            {{ t('OVERVIEW_REPORTS.AGENT_DAILY.TOTAL') }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-if="!agents.length">
          <td
            :colspan="days.length + 2"
            class="px-3 py-8 text-center text-n-slate-11"
          >
            {{ t('OVERVIEW_REPORTS.AGENT_DAILY.NO_AGENTS') }}
          </td>
        </tr>
        <template v-else>
          <tr v-for="(agent, agentIndex) in agents" :key="agent.id">
            <th
              scope="row"
              class="sticky start-0 z-10 min-w-48 border-b border-e border-n-weak bg-n-solid-2 px-3 py-2 text-start font-medium text-n-slate-12"
            >
              {{ agent.name }}
            </th>
            <td
              v-for="(day, dayIndex) in parsedDays"
              :key="day.key"
              class="min-w-20 border-b border-e border-n-weak px-3 py-2 text-center font-medium tabular-nums"
              :class="getCellClasses(agentIndex, dayIndex, day)"
              :title="getCellTitle(agent, day, getValue(agentIndex, dayIndex))"
            >
              <span
                v-if="!getValue(agentIndex, dayIndex)"
                class="text-n-slate-10"
              >
                {{ EMPTY_CELL }}
              </span>
              <template v-else>
                {{ getValue(agentIndex, dayIndex) }}
              </template>
            </td>
            <td
              class="sticky end-0 z-10 min-w-20 border-b border-s border-n-weak bg-n-solid-2 px-3 py-2 text-end font-semibold tabular-nums text-n-slate-12"
            >
              {{ agent.total }}
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>
