<template>
  <div
    class="rounded-lg border border-[#eaecf0] dark:border-[#4C5155] shadow-sm mt-6"
  >
    <div class="flex flex-col space-y-1.5 p-6">
      <div class="font-semibold tracking-tight text-lg">CSAT</div>
      <div class="text-sm text-muted">
        Customer satisfaction scores and feedback.
      </div>
    </div>
    <div class="p-6 pt-0">
      <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
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
        <csat-metric-card
          :label="'Avg. CSAT Score'"
          :value="averageCSATScore"
        />
        <div
          class="flex-col flex flex-wrap mx-0 bg-white dark:bg-slate-800 rounded-lg p-4 mb-5 border border-solid border-slate-75 dark:border-slate-700 col-span-1 sm:col-span-2 lg:col-span-4"
        >
          <div class="tracking-tight text-sm font-medium">
            {{ 'Satisfaction Breakdown' }}
          </div>
          <div
            v-if="metrics.total_count"
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
      </div>
    </div>
  </div>
</template>
<script>
import CsatMetricCard from './ReportMetricCard.vue';
import { CSAT_RATINGS } from 'shared/constants/messages';

export default {
  components: {
    CsatMetricCard,
  },
  props: {
    // metrics: {
    //   type: Object,
    //   required: true,
    // },
  },
  data() {
    return {
      csatRatings: CSAT_RATINGS,
      metrics: {
        total_count: 12,
        ratings_count: {
          2: 1,
          3: 1,
          4: 3,
          5: 7,
        },
        total_sent_messages_count: 41,
      },
    };
  },
  computed: {
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
    ratingPercentage() {
      if (!this.metrics.total_count || !this.metrics.ratings_count) {
        return { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
      }
      return {
        1: this.computeDistribution(
          this.getRatingCount(1),
          this.metrics.total_count
        ),
        2: this.computeDistribution(
          this.getRatingCount(2),
          this.metrics.total_count
        ),
        3: this.computeDistribution(
          this.getRatingCount(3),
          this.metrics.total_count
        ),
        4: this.computeDistribution(
          this.getRatingCount(4),
          this.metrics.total_count
        ),
        5: this.computeDistribution(
          this.getRatingCount(5),
          this.metrics.total_count
        ),
      };
    },
    satisfactionScore() {
      if (!this.metrics.total_count || !this.metrics.ratings_count) {
        return 0;
      }
      const rating4Count = this.getRatingCount(4);
      const rating5Count = this.getRatingCount(5);
      return this.computeDistribution(
        rating4Count + rating5Count,
        this.metrics.total_count
      );
    },
    responseRate() {
      if (
        !this.metrics.total_sent_messages_count ||
        !this.metrics.total_count
      ) {
        return 0;
      }
      return this.computeDistribution(
        this.metrics.total_count,
        this.metrics.total_sent_messages_count
      );
    },
    responseCount() {
      return this.metrics.total_count
        ? this.metrics.total_count.toLocaleString()
        : '--';
    },
    averageCSATScore() {
      let totalScore = 0;
      let totalResponses = 0;

      Object.entries(this.metrics.ratings_count).forEach(([rating, count]) => {
        totalScore += parseInt(rating, 10) * count;
        totalResponses += count;
      });

      if (totalResponses === 0) {
        return 0;
      }

      const averageCSAT = (totalScore / totalResponses).toFixed(2);
      return averageCSAT;
    },
  },
  methods: {
    getRatingCount(rating) {
      // Safely get rating count with fallback to 0
      return this.metrics.ratings_count && this.metrics.ratings_count[rating]
        ? this.metrics.ratings_count[rating]
        : 0;
    },
    computeDistribution(value, total) {
      // Add validation to prevent NaN
      if (!value || !total || total === 0) {
        return 0;
      }
      const result = (value * 100) / total;
      return Number.isNaN(result) ? 0 : parseFloat(result.toFixed(2));
    },
    formatToPercent(value) {
      if (value === null || value === undefined || Number.isNaN(value)) {
        return '--';
      }
      return `${value}%`;
    },
    ratingToEmoji(value) {
      return CSAT_RATINGS.find(rating => rating.value === Number(value)).emoji;
    },
  },
};
</script>
