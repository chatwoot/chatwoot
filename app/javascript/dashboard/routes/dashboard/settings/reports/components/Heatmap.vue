<template>
  <div class="heatmap-wrapper">
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
    <div class="heatmap-container">
      <div
        v-for="dateKey in processedData.keys()"
        :key="dateKey"
        class="heatmap-container-row"
      >
        <div
          v-for="data in processedData.get(dateKey)"
          :key="data.timestamp"
          v-tooltip.top="`${data.value} conversations`"
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
  </div>
</template>
<script>
import { getQuantileIntervals } from '@chatwoot/utils';
import format from 'date-fns/format';
import getDay from 'date-fns/getDay';

import { groupHeatmapByDay } from 'helpers/HeatmapHelper';

export default {
  name: 'Heatmap',
  props: {
    heatData: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      processedData: new Map(),
      quantileRange: [],
    };
  },
  mounted() {
    this.processData();
    this.getDataLimits();
  },
  methods: {
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
    getDataLimits() {
      const flattendedData = this.heatData.map(data => data.value);
      this.quantileRange = getQuantileIntervals(flattendedData, [
        0.2,
        0.4,
        0.6,
        0.8,
        0.95,
        1,
      ]);
    },
    processData() {
      this.processedData = groupHeatmapByDay(this.heatData);
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

$heatmap-level-1: #daf0ff;
$heatmap-level-2: #90d7ff;
$heatmap-level-3: #5cbffe;
$heatmap-level-4: #36a1fb;
$heatmap-level-5: #186cdd;
$heatmap-level-6: #1b4c8d;

$tile-height: 30px;

.heatmap-wrapper {
  display: grid;
  position: relative;
  width: 100%;
  gap: 2rem;
  grid-template-columns: 80px 1fr;

  .heatamp-labels {
    flex-shrink: 0;
  }
  .hover-tile {
    position: absolute;
  }

  .heatamp-container {
    flex-shrink: 0;
    flex-grow: 1;
  }

  .heatmap-timeline {
    visibility: invisible;
  }

  .heatmap-markers {
    display: grid;
    grid-template-columns: repeat(24, 1fr);
    gap: 0.4rem;
    width: 100%;
    font-size: 0.8rem;
    font-weight: 600;
    color: $color-light-gray;

    div {
      display: flex;
      align-items: center;
      justify-content: center;
    }
  }
}

.heatmap-labels {
  display: grid;
  grid-template-rows: 1fr;
  gap: 0.4rem;

  .heatmap-axis-label {
    height: $tile-height;
    min-width: 70px;
    font-size: 1rem;
    font-weight: 600;
    display: flex;
    flex-direction: column;
    align-items: end;
    justify-content: center;

    time {
      font-size: 1rem;
      font-weight: 400;
    }
  }
}

.heatmap-container {
  display: grid;
  grid-template-rows: 1fr;
  gap: 0.4rem;
  width: 100%;

  .heatmap-container-row {
    display: grid;
    gap: 0.4rem;
    grid-template-columns: repeat(24, 1fr);
  }

  .heatmap-tile {
    width: auto;
    height: $tile-height;
    border-radius: 0.4rem;

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
        border: 1px solid $color-border-light;
      }
    }

    &.l1 {
      background-color: $heatmap-level-1;
      &:hover {
        border: 1px solid lighten($heatmap-level-1, 2%);
      }
    }

    &.l2 {
      background-color: $heatmap-level-2;
      &:hover {
        border: 1px solid lighten($heatmap-level-2, 10%);
      }
    }

    &.l3 {
      background-color: $heatmap-level-3;
      &:hover {
        border: 1px solid lighten($heatmap-level-3, 10%);
      }
    }

    &.l4 {
      background-color: $heatmap-level-4;
      &:hover {
        border: 1px solid lighten($heatmap-level-4, 10%);
      }
    }

    &.l5 {
      background-color: $heatmap-level-5;
      &:hover {
        border: 1px solid lighten($heatmap-level-5, 10%);
      }
    }

    &.l6 {
      background-color: $heatmap-level-6;
      &:hover {
        border: 1px solid lighten($heatmap-level-6, 10%);
      }
    }

    .heatmap-tile__label {
      visibility: hidden;
    }
  }
}
</style>
