<template>
  <div class="row csat--metrics-container">
    <csat-metric-card
      :label="$t('CSAT_REPORTS.METRIC.TOTAL_RESPONSES.LABEL')"
      :info-text="$t('CSAT_REPORTS.METRIC.TOTAL_RESPONSES.TOOLTIP')"
      :value="responseCount"
    />
    <csat-metric-card
      :label="$t('CSAT_REPORTS.METRIC.SATISFACTION_SCORE.LABEL')"
      :info-text="$t('CSAT_REPORTS.METRIC.SATISFACTION_SCORE.TOOLTIP')"
      :value="formatToPercent(satisfactionScore)"
    />
    <csat-metric-card
      :label="$t('CSAT_REPORTS.METRIC.RESPONSE_RATE.LABEL')"
      :info-text="$t('CSAT_REPORTS.METRIC.RESPONSE_RATE.TOOLTIP')"
      :value="formatToPercent(responseRate)"
    />
    <div v-if="metrics.totalResponseCount" class="medium-6 report-card">
      <h3 class="heading">
        <div class="emoji--distribution">
          <div
            v-for="(rating, key, index) in ratingPercentage"
            :key="rating + key + index"
            class="emoji--distribution-item"
          >
            <span class="emoji--distribution-key">{{
              csatRatings[key - 1].emoji
            }}</span>
            <span>{{ formatToPercent(rating) }}</span>
          </div>
        </div>
      </h3>
      <div class="emoji--distribution-chart">
        <woot-horizontal-bar :collection="chartData" :height="24" />
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import CsatMetricCard from './CsatMetricCard';
import { CSAT_RATINGS } from 'shared/constants/messages';

export default {
  components: {
    CsatMetricCard,
  },
  data() {
    return {
      csatRatings: CSAT_RATINGS,
    };
  },
  computed: {
    ...mapGetters({
      metrics: 'csat/getMetrics',
      ratingPercentage: 'csat/getRatingPercentage',
      satisfactionScore: 'csat/getSatisfactionScore',
      responseRate: 'csat/getResponseRate',
    }),
    chartData() {
      return {
        labels: ['Rating'],
        datasets: CSAT_RATINGS.map((rating, index) => ({
          label: rating.emoji,
          data: [this.ratingPercentage[index + 1]],
          backgroundColor: rating.color,
        })),
      };
    },
    responseCount() {
      return this.metrics.totalResponseCount
        ? this.metrics.totalResponseCount.toLocaleString()
        : '--';
    },
  },
  methods: {
    formatToPercent(value) {
      return value ? `${value}%` : '--';
    },
  },
};
</script>
<style lang="scss" scoped>
.csat--metrics-container {
  background: var(--white);
  margin-bottom: var(--space-two);
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--color-border);
  padding: var(--space-normal);
}

.emoji--distribution {
  display: flex;
  justify-content: flex-end;

  .emoji--distribution-item {
    padding-left: var(--space-normal);
  }
}

.emoji--distribution-chart {
  margin-top: var(--space-small);
}

.emoji--distribution-key {
  margin-right: var(--space-micro);
}
</style>
