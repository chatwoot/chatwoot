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
          <div class="heatmap-tile__label">
            0
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
const asc = arr => arr.sort((a, b) => a - b);

const quantile = (arr, q) => {
  const sorted = asc(arr);
  const pos = (sorted.length - 1) * q;
  const base = Math.floor(pos);
  const rest = pos - base;
  if (sorted[base + 1] !== undefined) {
    return sorted[base] + rest * (sorted[base + 1] - sorted[base]);
  }
  return sorted[base];
};

import fromUnixTime from 'date-fns/fromUnixTime';
import startOfDay from 'date-fns/startOfDay';
import format from 'date-fns/format';
import getDay from 'date-fns/getDay';

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
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ];
      return days[dayIndex];
    },
    getDataLimits() {
      const flattendedData = this.heatData.map(data => data.value);
      this.quantileRange = [
        quantile(flattendedData, 0.2),
        quantile(flattendedData, 0.4),
        quantile(flattendedData, 0.6),
        quantile(flattendedData, 0.8),
        quantile(flattendedData, 0.95),
        quantile(flattendedData, 1),
      ];
    },
    processData() {
      this.processedData = this.heatData.reduce((acc, data) => {
        const date = fromUnixTime(data.timestamp);
        const mapKey = startOfDay(date).toISOString();
        const dataToAppend = {
          ...data,
          date: fromUnixTime(data.timestamp),
          hour: date.getHours(),
        };
        if (!acc.has(mapKey)) {
          acc.set(mapKey, []);
        }
        acc.get(mapKey).push(dataToAppend);
        return acc;
      }, new Map());
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

.heatmap-wrapper {
  display: flex;
  width: 100%;
  gap: 2rem;

  .heatamp-labels {
    flex-shrink: 0;
  }

  .heatamp-container {
    flex-shrink: 0;
    flex-grow: 1;
  }
}

.heatmap-labels {
  display: grid;
  grid-template-rows: repeat(7, 1fr);
  gap: 0.2rem;

  .heatmap-axis-label {
    height: 50px;
    min-width: 100px;
    font-size: 1.5rem;
    font-weight: 600;
    display: flex;
    flex-direction: column;
    align-items: start;
    justify-content: center;

    time {
      font-size: 1rem;
      font-weight: 400;
    }
  }
}

.heatmap-container {
  display: grid;
  grid-template-rows: repeat(7, 1fr);
  gap: 0.4rem;
  width: 100%;

  .heatmap-container-row {
    display: grid;
    gap: 0.4rem;
    grid-template-columns: repeat(24, 1fr);
  }

  .heatmap-tile {
    width: auto;
    height: 50px;
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
