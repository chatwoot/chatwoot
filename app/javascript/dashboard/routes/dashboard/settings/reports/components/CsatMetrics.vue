<template>
  <div
    class="flex-col lg:flex-row flex flex-wrap mx-0 bg-white dark:bg-slate-800 rounded-[4px] p-4 mb-5 border border-solid border-slate-75 dark:border-slate-700"
  >
    <csat-metric-card
      :label="$t('CSAT_REPORTS.METRIC.TOTAL_RESPONSES.LABEL')"
      :info-text="$t('CSAT_REPORTS.METRIC.TOTAL_RESPONSES.TOOLTIP')"
      :value="responseCount"
      class="xs:w-full sm:max-w-[50%] lg:w-1/6 lg:max-w-[16%]"
    />
    <csat-metric-card
      :disabled="ratingFilterEnabled"
      :label="$t('CSAT_REPORTS.METRIC.SATISFACTION_SCORE.LABEL')"
      :info-text="$t('CSAT_REPORTS.METRIC.SATISFACTION_SCORE.TOOLTIP')"
      :value="ratingFilterEnabled ? '--' : formatToPercent(satisfactionScore)"
      class="xs:w-full sm:max-w-[50%] lg:w-1/6 lg:max-w-[16%]"
    />
    <csat-metric-card
      :label="$t('CSAT_REPORTS.METRIC.RESPONSE_RATE.LABEL')"
      :info-text="$t('CSAT_REPORTS.METRIC.RESPONSE_RATE.TOOLTIP')"
      :value="formatToPercent(responseRate)"
      class="xs:w-full sm:max-w-[50%] lg:w-1/6 lg:max-w-[16%]"
    />

    <div
      v-if="metrics.totalResponseCount && !ratingFilterEnabled"
      ref="csatHorizontalBarChart"
      class="w-full md:w-1/2 md:max-w-[50%] flex-1 rtl:[direction:initial] p-4"
    >
      <h3
        class="flex items-center text-xs md:text-sm font-medium m-0 text-slate-800 dark:text-slate-100"
      >
        <div class="flex justify-end flex-row-reverse">
          <div
            v-for="(rating, key, index) in ratingPercentage"
            :key="rating + key + index"
            class="ltr:pr-4 rtl:pl-4"
          >
            <span class="my-0 mx-0.5">{{ ratingToEmoji(key) }}</span>
            <span>{{ formatToPercent(rating) }}</span>
          </div>
        </div>
      </h3>
      <div class="mt-2">
        <woot-horizontal-bar :collection="chartData" :height="24" />
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import CsatMetricCard from './ReportMetricCard.vue';
import { CSAT_RATINGS } from 'shared/constants/messages';

export default {
  components: {
    CsatMetricCard,
  },
  props: {
    filters: {
      type: Object,
      required: true,
    },
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
    ratingFilterEnabled() {
      return Boolean(this.filters.rating);
    },
    chartData() {
      const sortedRatings = [...CSAT_RATINGS].sort((a, b) => b.value - a.value);
      return {
        labels: ['Rating'],
        datasets: sortedRatings.map(rating => ({
          label: rating.emoji,
          data: [this.ratingPercentage[rating.value]],
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
    ratingToEmoji(value) {
      return CSAT_RATINGS.find(rating => rating.value === Number(value)).emoji;
    },
  },
};
</script>
