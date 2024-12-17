<script setup>
import { computed } from 'vue';

import format from 'date-fns/format';
import getDay from 'date-fns/getDay';

import { getQuantileIntervals } from '@chatwoot/utils';

import { groupHeatmapByDay } from 'helpers/ReportsDataHelper';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  heatData: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});
const { t } = useI18n();
const processedData = computed(() => {
  return groupHeatmapByDay(props.heatData);
});

const quantileRange = computed(() => {
  const flattendedData = props.heatData.map(data => data.value);
  return getQuantileIntervals(flattendedData, [0.2, 0.4, 0.6, 0.8, 0.9, 0.99]);
});

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
function getHeatmapLevelClass(value) {
  if (!value) return 'outline-n-container dark:bg-slate-700/40 bg-slate-50/50';

  let level = [...quantileRange.value, Infinity].findIndex(
    range => value <= range && value > 0
  );

  if (level > 6) level = 5;

  if (level === 0) {
    return 'outline-n-container dark:bg-slate-700/40 bg-slate-50/50';
  }

  const classes = [
    'bg-woot-50 dark:bg-woot-800/40 dark:outline-woot-800/80',
    'bg-woot-100 dark:bg-woot-800/30 dark:outline-woot-800/80',
    'bg-woot-200 dark:bg-woot-500/40 dark:outline-woot-700/80',
    'bg-woot-300 dark:bg-woot-500/60 dark:outline-woot-600/80',
    'bg-woot-600 dark:bg-woot-500/80 dark:outline-woot-500/80',
    'bg-woot-800 dark:bg-woot-500 dark:outline-woot-400/80',
  ];

  return classes[level - 1];
}
</script>

<template>
  <div
    class="grid relative w-full gap-x-4 gap-y-2.5 overflow-y-scroll md:overflow-visible grid-cols-[80px_1fr] min-h-72"
  >
    <template v-if="isLoading">
      <div class="grid gap-[5px] flex-shrink-0">
        <div
          v-for="ii in 7"
          :key="ii"
          class="w-full rounded-sm bg-slate-100 dark:bg-slate-900 animate-loader-pulse h-8 min-w-[70px]"
        />
      </div>
      <div class="grid gap-[5px] w-full min-w-[700px]">
        <div
          v-for="ii in 7"
          :key="ii"
          class="grid gap-[5px] grid-cols-[repeat(24,_1fr)]"
        >
          <div
            v-for="jj in 24"
            :key="jj"
            class="w-full h-8 rounded-sm bg-slate-100 dark:bg-slate-900 animate-loader-pulse"
          />
        </div>
      </div>
      <div />
      <div
        class="grid grid-cols-[repeat(24,_1fr)] gap-[5px] w-full text-[8px] font-semibold h-5 text-slate-800 dark:text-slate-200"
      >
        <div
          v-for="ii in 24"
          :key="ii"
          class="flex items-center justify-center"
        >
          {{ ii - 1 }} – {{ ii }}
        </div>
      </div>
    </template>
    <template v-else>
      <div class="grid gap-[5px] flex-shrink-0">
        <div
          v-for="dateKey in processedData.keys()"
          :key="dateKey"
          class="h-8 min-w-[70px] text-slate-800 dark:text-slate-200 text-[10px] font-semibold flex flex-col items-end justify-center"
        >
          {{ getDayOfTheWeek(new Date(dateKey)) }}
          <time class="font-normal text-slate-700 dark:text-slate-200">
            {{ formatDate(dateKey) }}
          </time>
        </div>
      </div>
      <div class="grid gap-[5px] w-full min-w-[700px]">
        <div
          v-for="dateKey in processedData.keys()"
          :key="dateKey"
          class="grid gap-[5px] grid-cols-[repeat(24,_1fr)]"
        >
          <div
            v-for="data in processedData.get(dateKey)"
            :key="data.timestamp"
            v-tooltip.top="getCountTooltip(data.value)"
            class="h-8 rounded-sm shadow-inner dark:outline dark:outline-1 shadow-black"
            :class="getHeatmapLevelClass(data.value)"
          />
        </div>
      </div>
      <div />
      <div
        class="grid grid-cols-[repeat(24,_1fr)] gap-[5px] w-full text-[8px] font-semibold h-5 text-slate-800 dark:text-slate-200"
      >
        <div
          v-for="ii in 24"
          :key="ii"
          class="flex items-center justify-center"
        >
          {{ ii - 1 }} – {{ ii }}
        </div>
      </div>
    </template>
  </div>
</template>
