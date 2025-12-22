<script setup>
import { computed } from 'vue';
import { useMemoize } from '@vueuse/core';

import format from 'date-fns/format';
import getDay from 'date-fns/getDay';

import { getQuantileIntervals } from '@chatwoot/utils';

import { groupHeatmapByDay } from 'helpers/ReportsDataHelper';
import { useI18n } from 'vue-i18n';
import { useHeatmapTooltip } from './composables/useHeatmapTooltip';
import HeatmapTooltip from './HeatmapTooltip.vue';

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

const dataRows = computed(() => {
  const groupedData = groupHeatmapByDay(props.heatmapData);
  return Array.from(groupedData.keys()).map(dateKey => {
    const rowData = groupedData.get(dateKey);
    return {
      dateKey,
      data: rowData,
      dataHash: rowData.map(d => d.value).join(','),
    };
  });
});

const quantileRange = computed(() => {
  const flattendedData = props.heatmapData.map(data => data.value);
  return getQuantileIntervals(flattendedData, [0.2, 0.4, 0.6, 0.8, 0.9, 0.99]);
});

function formatDate(dateString) {
  return format(new Date(dateString), 'MMM d, yyyy');
}

const DAYS_OF_WEEK = [
  t('DAYS_OF_WEEK.SUNDAY'),
  t('DAYS_OF_WEEK.MONDAY'),
  t('DAYS_OF_WEEK.TUESDAY'),
  t('DAYS_OF_WEEK.WEDNESDAY'),
  t('DAYS_OF_WEEK.THURSDAY'),
  t('DAYS_OF_WEEK.FRIDAY'),
  t('DAYS_OF_WEEK.SATURDAY'),
];

function getDayOfTheWeek(date) {
  const dayIndex = getDay(date);

  return DAYS_OF_WEEK[dayIndex];
}

const COLOR_SCHEMES = {
  blue: [
    'bg-n-blue-3 border border-n-blue-4/30',
    'bg-n-blue-5 border border-n-blue-6/30',
    'bg-n-blue-7 border border-n-blue-8/30',
    'bg-n-blue-8 border border-n-blue-9/30',
    'bg-n-blue-10 border border-n-blue-8/30',
    'bg-n-blue-11 border border-n-blue-10/30',
  ],
  green: [
    'bg-n-teal-3 border border-n-teal-4/30',
    'bg-n-teal-5 border border-n-teal-6/30',
    'bg-n-teal-7 border border-n-teal-8/30',
    'bg-n-teal-8 border border-n-teal-9/30',
    'bg-n-teal-10 border border-n-teal-8/30',
    'bg-n-teal-11 border border-n-teal-10/30',
  ],
};

// Memoized function to calculate CSS class for heatmap cell intensity levels
const getHeatmapLevelClass = useMemoize(
  (value, quantileRangeArray, colorScheme) => {
    if (!value)
      return 'border border-n-container bg-n-slate-2 dark:bg-n-slate-1/30';
    let level = [...quantileRangeArray, Infinity].findIndex(
      range => value <= range && value > 0
    );

    if (level > 6) level = 5;

    if (level === 0) {
      return 'border border-n-container bg-n-slate-2 dark:bg-n-slate-1/30';
    }

    return COLOR_SCHEMES[colorScheme][level - 1];
  }
);

function getHeatmapClass(value) {
  return getHeatmapLevelClass(value, quantileRange.value, props.colorScheme);
}

// Tooltip composable
const tooltip = useHeatmapTooltip();
</script>

<!-- eslint-disable vue/no-static-inline-styles -->
<template>
  <div
    class="grid relative w-full gap-x-4 gap-y-2.5 overflow-y-scroll md:overflow-visible grid-cols-[80px_1fr]"
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
      <div
        class="grid gap-[5px] w-full min-w-[700px]"
        style="content-visibility: auto"
      >
        <div
          v-for="row in dataRows"
          :key="row.dateKey"
          v-memo="[row.dataHash, colorScheme]"
          class="grid gap-[5px] grid-cols-[repeat(24,_1fr)]"
          style="content-visibility: auto"
        >
          <div
            v-for="data in row.data"
            :key="data.timestamp"
            class="h-8 rounded-sm cursor-pointer"
            :class="getHeatmapClass(data.value)"
            @mouseenter="tooltip.show($event, data.value)"
            @mouseleave="tooltip.hide"
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

    <HeatmapTooltip
      :visible="tooltip.visible.value"
      :x="tooltip.x.value"
      :y="tooltip.y.value"
      :value="tooltip.value.value"
    />
  </div>
</template>
