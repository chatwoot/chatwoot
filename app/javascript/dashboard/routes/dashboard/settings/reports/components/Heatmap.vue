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
      <div class="heatmap-grid">
        <div v-for="ii in 7" :key="ii" class="heatmap-grid-row">
          <div v-for="jj in 24" :key="jj" class="heatmap-tile loading-cell">
            <div class="heatmap-tile__label loading-cell" />
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
      <div class="heatmap-grid">
        <div
          v-for="dateKey in processedData.keys()"
          :key="dateKey"
          class="heatmap-grid-row"
        >
          <div
            v-for="data in processedData.get(dateKey)"
            :key="data.timestamp"
            v-tooltip.top="getCountTooltip(data.value)"
            class="heatmap-tile"
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
      return getQuantileIntervals(flattendedData, [
        0.2,
        0.4,
        0.6,
        0.8,
        0.95,
        1,
      ]);
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
      if (!value) return '';

      const level = this.quantileRange.findIndex(
        range => value <= range && value > 0
      );

      return `l${level + 1}`;
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';

$heatmap-colors: (
  level-1: #daf0ff,
  level-2: #90d7ff,
  level-3: #5cbffe,
  level-4: #36a1fb,
  level-5: #186cdd,
  level-6: #1b4c8d,
);

$tile-height: 3rem;
$tile-gap: var(--space-smaller);
$container-gap-row: var(--space-one);
$container-gap-column: var(--space-two);
$marker-height: var(--space-two);

@mixin heatmap-level($level) {
  $color: map-get($heatmap-colors, 'level-#{$level}');
  background-color: $color;
  &:hover {
    border: 1px solid lighten($color, 10%);
  }
}

@media screen and (max-width: 768px) {
  .heatmap-container {
    overflow-y: auto;
  }
}

.loading-cell {
  background-color: $color-background-light;
  border: 0px;

  animation: loading-pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes loading-pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0;
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
    font-weight: 600;
    display: flex;
    flex-direction: column;
    align-items: end;
    justify-content: center;

    time {
      font-size: var(--font-size-micro);
      font-weight: var(--font-weight-normal);
    }
  }
}

.heatmap-grid {
  display: grid;
  grid-template-rows: 1fr;
  gap: $tile-gap;
  min-width: 700px;
  width: 100%;

  .heatmap-grid-row {
    display: grid;
    gap: $tile-gap;
    grid-template-columns: repeat(24, 1fr);
  }

  .heatmap-tile {
    width: auto;
    height: $tile-height;
    border-radius: var(--border-radius-normal);

    &:hover {
      box-shadow: 0 10px 15px -3px rgb(0 0 0 / 0.1),
        0 4px 6px -4px rgb(0 0 0 / 0.1), 0 25px 50px -12px rgb(0 0 0 / 0.25);

      transform: translateY(-2px);
      transition: transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
    }

    &:not(.l1):not(.l2):not(.l3):not(.l4):not(.l5):not(.l6) {
      background-color: $color-background-light;
      border: 1px solid $color-border-light;

      &:hover {
        transform: translateY(0);
        box-shadow: none;
        border: 1px solid var(--color-border-light);
      }
    }

    &.l1 {
      @include heatmap-level(1);
    }
    &.l2 {
      @include heatmap-level(2);
    }
    &.l3 {
      @include heatmap-level(3);
    }
    &.l4 {
      @include heatmap-level(4);
    }
    &.l5 {
      @include heatmap-level(5);
    }
    &.l6 {
      @include heatmap-level(6);
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
  color: $color-light-gray;

  div {
    display: flex;
    align-items: center;
    justify-content: center;
  }
}
</style>
