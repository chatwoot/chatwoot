<template>
  <div
    class="small-2 report-card"
    :class="{ active: selected }"
    @click="onClick(index)"
  >
    <h3 class="heading">
      {{ heading }}
    </h3>
    <div class="metric-wrap">
      <h4 class="metric">
        {{ point }}
      </h4>
      <span v-if="trend !== 0" :class="trendClass">{{ trendValue }}</span>
    </div>
    <p class="desc">
      {{ desc }}
    </p>
  </div>
</template>
<script>
export default {
  props: {
    heading: { type: String, default: '' },
    point: { type: [Number, String], default: '' },
    trend: { type: Number, default: null },
    index: { type: Number, default: null },
    desc: { type: String, default: '' },
    selected: Boolean,
    onClick: { type: Function, default: () => {} },
  },
  computed: {
    trendClass() {
      if (this.trend > 0) {
        return 'metric-trend metric-up';
      }

      return 'metric-trend metric-down';
    },
    trendValue() {
      if (this.trend > 0) {
        return `+${this.trend}%`;
      }

      return `${this.trend}%`;
    },
  },
};
</script>
