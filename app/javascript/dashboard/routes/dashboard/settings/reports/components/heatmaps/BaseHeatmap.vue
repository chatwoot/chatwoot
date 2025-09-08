<script setup>
import { computed } from 'vue';
import { useMemoize } from '@vueuse/core';

import format from 'date-fns/format';
import getDay from 'date-fns/getDay';

import { getQuantileIntervals } from '@chatwoot/utils';

import { groupHeatmapByDay } from 'helpers/ReportsDataHelper';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  heatmapData: {
    type: Array,
    default: () => [],
  },
  numberOfRows: {
    type: Number,
    default: 7,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  colorScheme: {
    type: String,
    default: 'blue',
    validator: value => ['blue', 'green'].includes(value),
  },
});
const { t } = useI18n();
const processedData = computed(() => {
  return groupHeatmapByDay(props.heatmapData);
});

// Memoized rows - each row only re-computes if its data changes
const dataRows = computed(() => {
  return Array.from(processedData.value.keys()).map(dateKey => {
    const rowData = processedData.value.get(dateKey);
    return {
      dateKey,
      data: rowData,
      // Create a hash of the row data for memoization
      dataHash: rowData.map(d => d.value).join(','),
    };
  });
});

const quantileRange = computed(() => {
  const flattendedData = props.heatmapData.map(data => data.value);
  return getQuantileIntervals(flattendedData, [0.2, 0.4, 0.6, 0.8, 0.9, 0.99]);
});

// Stringify quantileRange only when it changes, not on every function call
const quantileRangeStr = computed(() => JSON.stringify(quantileRange.value));

function getCountTooltip(value) {
  if (!value) {
    return t('OVERVIEW_REPORTS.CONVERSATION_HEATMAP.NO_CONVERSATIONS');
  }

  if (value === 1) {
    return t('OVERVIEW_REPORTS.CONVERSATION_HEATMAP.CONVERSATION', {
      count: value,
    });
  }

  return t('OVERVIEW_REPORTS.CONVERSATION_HEATMAP.CONVERSATIONS', {
    count: value,
  });
}

function formatDate(dateString) {
  return format(new Date(dateString), 'MMM d, yyyy');
}

function getDayOfTheWeek(date) {
  const dayIndex = getDay(date);
  const days = [
    t('DAYS_OF_WEEK.SUNDAY'),
    t('DAYS_OF_WEEK.MONDAY'),
    t('DAYS_OF_WEEK.TUESDAY'),
    t('DAYS_OF_WEEK.WEDNESDAY'),
    t('DAYS_OF_WEEK.THURSDAY'),
    t('DAYS_OF_WEEK.FRIDAY'),
    t('DAYS_OF_WEEK.SATURDAY'),
  ];
  return days[dayIndex];
}
// Create the memoized function - depends on value, quantileRange, and colorScheme
const getHeatmapLevelClass = useMemoize(
  (value, quantileRangeString, colorScheme) => {
    if (!value) return 'outline-n-container bg-n-slate-2 dark:bg-n-slate-5/50';

    const quantileRangeArray = JSON.parse(quantileRangeString);
    let level = [...quantileRangeArray, Infinity].findIndex(
      range => value <= range && value > 0
    );

    if (level > 6) level = 5;

    if (level === 0) {
      return 'outline-n-container bg-n-slate-2 dark:bg-n-slate-5/50';
    }

    const colorSchemes = {
      blue: [
        'bg-n-blue-3 dark:outline-n-blue-4',
        'bg-n-blue-5 dark:outline-n-blue-6',
        'bg-n-blue-7 dark:outline-n-blue-8',
        'bg-n-blue-8 dark:outline-n-blue-9',
        'bg-n-blue-10 dark:outline-n-blue-8',
        'bg-n-blue-11 dark:outline-n-blue-10',
      ],
      green: [
        'bg-n-teal-3 dark:outline-n-teal-4',
        'bg-n-teal-5 dark:outline-n-teal-6',
        'bg-n-teal-7 dark:outline-n-teal-8',
        'bg-n-teal-8 dark:outline-n-teal-9',
        'bg-n-teal-10 dark:outline-n-teal-8',
        'bg-n-teal-11 dark:outline-n-teal-10',
      ],
    };

    return colorSchemes[colorScheme][level - 1];
  }
);

// Helper function to call the memoized version with current context
function getHeatmapClass(value) {
  return getHeatmapLevelClass(value, quantileRangeStr.value, props.colorScheme);
}
</script>

<template>
  <div
    class="grid relative w-full gap-x-4 gap-y-2.5 overflow-y-scroll md:overflow-visible grid-cols-[80px_1fr] min-h-72"
  >
    <template v-if="isLoading">
      <div class="grid gap-[5px] flex-shrink-0">
        <div
          v-for="ii in numberOfRows"
          :key="ii"
          class="w-full rounded-sm bg-n-slate-3 dark:bg-n-slate-1 animate-loader-pulse h-8 min-w-[70px]"
        />
      </div>
      <div class="grid gap-[5px] w-full min-w-[700px]">
        <div
          v-for="ii in numberOfRows"
          :key="ii"
          class="grid gap-[5px] grid-cols-[repeat(24,_1fr)]"
        >
          <div
            v-for="jj in 24"
            :key="jj"
            class="w-full h-8 rounded-sm bg-n-slate-3 dark:bg-n-slate-1 animate-loader-pulse"
          />
        </div>
      </div>
      <div />
      <div
        class="grid grid-cols-[repeat(24,_1fr)] gap-[5px] w-full text-[8px] font-semibold h-5 text-n-slate-11"
      >
        <div
          v-for="ii in 24"
          :key="ii"
          class="flex items-center justify-center"
        >
          {{ ii - 1 }}
        </div>
      </div>
    </template>
    <template v-else>
      <div class="grid gap-[5px] flex-shrink-0">
        <div
          v-for="row in dataRows"
          :key="row.dateKey"
          v-memo="[row.dateKey]"
          class="h-8 min-w-[70px] text-n-slate-12 text-[10px] font-semibold flex flex-col items-end justify-center"
        >
          {{ getDayOfTheWeek(new Date(row.dateKey)) }}
          <time class="font-normal text-n-slate-11">
            {{ formatDate(row.dateKey) }}
          </time>
        </div>
      </div>
      <div class="grid gap-[5px] w-full min-w-[700px]">
        <div
          v-for="row in dataRows"
          :key="row.dateKey"
          v-memo="[row.dataHash, colorScheme]"
          class="grid gap-[5px] grid-cols-[repeat(24,_1fr)]"
        >
          <div
            v-for="data in row.data"
            :key="data.timestamp"
            v-tooltip.top="getCountTooltip(data.value)"
            class="h-8 rounded-sm shadow-inner dark:outline dark:outline-1"
            :class="getHeatmapClass(data.value)"
          />
        </div>
      </div>
      <div />
      <div
        class="grid grid-cols-[repeat(24,_1fr)] gap-[5px] w-full text-[8px] font-semibold h-5 text-n-slate-12"
      >
        <div
          v-for="ii in 24"
          :key="ii"
          class="flex items-center justify-center"
        >
          {{ ii - 1 }}
        </div>
      </div>
    </template>
  </div>
</template>
