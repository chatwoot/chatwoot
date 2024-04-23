<template>
  <div class="heatmap-container">
    <template v-if="isLoading">
      <div class="heatmap-labels">
        <div
          v-for="ii in 7"
          :key="ii"
          class="loading-cell heatmap-axis-label"
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
            class="h-8 heatmap-tile animate-loader-pulse"
          >
            <div class="heatmap-tile__label animate-loader-pulse" />
          </div>
        </div>
      </div>
      <div class="heatmap-timeline" />
      <div class="heatmap-markers">
        <div v-for="ii in 24" :key="ii">{{ ii - 1 }} – {{ ii }}</div>
      </div>
    </template>
    <template v-else>
      <div class="heatmap-labels">
        <div
          v-for="dateKey in processedData.keys()"
          :key="dateKey"
          class="heatmap-axis-label"
        >
          {{ getDayOfTheWeek(new Date(dateKey)) }}
          <time>{{ formatDate(dateKey) }}</time>
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
          >
            <div class="heatmap-tile__label" />
          </div>
        </div>
      </div>
      <div class="heatmap-timeline" />
      <div class="heatmap-markers">
        <div v-for="ii in 24" :key="ii">{{ ii - 1 }} – {{ ii }}</div>
      </div>
    </template>
  </div>
</template>
<script>
import { getQuantileIntervals } from '@chatwoot/utils';
import format from 'date-fns/format';
import getDay from 'date-fns/getDay';

import { groupHeatmapByDay } from 'helpers/ReportsDataHelper';

export default {
  name: 'Heatmap',
  props: {
    heatData: {
      type: Array,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    processedData() {
      return groupHeatmapByDay(this.heatData);
    },
    quantileRange() {
      const flattendedData = this.heatData.map(data => data.value);
      return getQuantileIntervals(
        flattendedData,
        [0.2, 0.4, 0.6, 0.8, 0.9, 0.99]
      );
    },
  },
  methods: {
    getCountTooltip(value) {
      if (!value) {
        return this.$t(
          'OVERVIEW_REPORTS.CONVERSATION_HEATMAP.NO_CONVERSATIONS'
        );
      }

      if (value === 1) {
        return this.$t('OVERVIEW_REPORTS.CONVERSATION_HEATMAP.CONVERSATION', {
          count: value,
        });
      }

      return this.$t('OVERVIEW_REPORTS.CONVERSATION_HEATMAP.CONVERSATIONS', {
        count: value,
      });
    },
    formatDate(dateString) {
      return format(new Date(dateString), 'MMM d, yyyy');
    },
    getDayOfTheWeek(date) {
      const dayIndex = getDay(date);
      const days = [
        this.$t('DAYS_OF_WEEK.SUNDAY'),
        this.$t('DAYS_OF_WEEK.MONDAY'),
        this.$t('DAYS_OF_WEEK.TUESDAY'),
        this.$t('DAYS_OF_WEEK.WEDNESDAY'),
        this.$t('DAYS_OF_WEEK.THURSDAY'),
        this.$t('DAYS_OF_WEEK.FRIDAY'),
        this.$t('DAYS_OF_WEEK.SATURDAY'),
      ];
      return days[dayIndex];
    },
    getHeatmapLevelClass(value) {
      if (!value)
        return 'outline-slate-100 dark:outline-slate-700 dark:bg-slate-700/40 bg-slate-50/50';

      let level = [...this.quantileRange, Infinity].findIndex(
        range => value <= range && value > 0
      );

      if (level > 6) level = 5;

      if (level === 0) {
        return 'outline-slate-100 dark:outline-slate-700 dark:bg-slate-700/40 bg-slate-50/50';
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
    },
  },
};
</script>

<style scoped lang="scss">
$tile-height: 1.875rem;
$tile-gap: var(--space-smaller);
$container-gap-row: var(--space-one);
$container-gap-column: var(--space-two);
$marker-height: var(--space-two);

@media screen and (max-width: 768px) {
  .heatmap-container {
    overflow-y: auto;
  }
}

.heatmap-container {
  display: grid;
  position: relative;
  width: 100%;
  gap: $container-gap-row $container-gap-column;
  grid-template-columns: 80px 1fr;
  min-height: calc(
    7 * #{$tile-height} + 6 * #{$tile-gap} + #{$container-gap-row} + #{$marker-height}
  );
}

.heatmap-labels {
  display: grid;
  grid-template-rows: 1fr;
  gap: $tile-gap;
  flex-shrink: 0;

  .heatmap-axis-label {
    height: $tile-height;
    min-width: 70px;
    font-size: var(--font-size-micro);
    font-weight: var(--font-weight-bold);
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    justify-content: center;
    @apply text-slate-800 dark:text-slate-200;

    time {
      font-size: var(--font-size-micro);
      font-weight: var(--font-weight-normal);
      @apply text-slate-700 dark:text-slate-200;
    }
  }
}

.heatmap-markers {
  display: grid;
  grid-template-columns: repeat(24, 1fr);
  gap: $tile-gap;
  width: 100%;
  font-size: var(--font-size-nano);
  font-weight: var(--font-weight-bold);
  height: $marker-height;
  color: var(--color-body);
  @apply text-slate-800 dark:text-slate-200;

  div {
    display: flex;
    align-items: center;
    justify-content: center;
  }
}
</style>
