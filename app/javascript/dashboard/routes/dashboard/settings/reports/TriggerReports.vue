<template>
  <div class="flex-1 overflow-auto p-4">
    <div class="row">
      <metric-card
        :is-live="false"
        :is-loading="triggersMetric.isFetching"
        header="Relatório de Disparos"
        loading-message="carregando..."
      >
        <div
          v-for="(metric, name, index) in conversationMetrics"
          :key="index"
          class="metric-content column"
        >
          <h3 class="heading">{{ name }}</h3>
          <p class="metric">{{ metric }}</p>
        </div>
      </metric-card>
    </div>
    <div class="row">
      <metric-card header="Gráfico">
        <div class="metric-content column">
          <woot-loading-state
            v-if="triggersMetric.isFetching"
            class="text-xs"
            :message="$t('REPORT.LOADING_CHART')"
          />
          <div v-else class="flex items-center justify-center">
            <woot-bar
              v-if="chartData.datasets.length"
              :collection="chartData"
              class="w-full"
            />
            <span v-else class="text-sm text-slate-600">
              {{ $t('REPORT.NO_ENOUGH_DATA') }}
            </span>
          </div>
        </div>
      </metric-card>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { TRIGGERS_METRICS } from './constants';
import MetricCard from './components/overview/MetricCard.vue';
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';

export default {
  name: 'TriggerReports',
  components: {
    MetricCard,
  },
  data() {
    return {
      chartData: {
        labels: [],
        datasets: [],
      },
    };
  },
  computed: {
    ...mapGetters({
      triggersMetric: 'getTriggersReport',
    }),
    conversationMetrics() {
      let metric = {};
      Object.keys(this.triggersMetric.metrics).forEach(key => {
        const metricName = TRIGGERS_METRICS[key]; // TODO: change to translate correctly
        metric[metricName] = this.triggersMetric.metrics[key];
      });
      return metric;
    },
  },
  watch: {
    triggersMetric: {
      immediate: true,
      handler(newVal) {
        if (!newVal.isFetching && newVal.data.length) {
          this.prepareChartData();
        }
      },
    },
  },
  mounted() {
    this.fetchAllData();
  },
  methods: {
    prepareChartData() {
      const data = this.triggersMetric.data;
      const labels = data.map(item =>
        format(
          fromUnixTime(new Date(item.createdAt).getTime() / 1000),
          'dd-MMM'
        )
      );
      const values = data.map(item => item.id);

      this.chartData = {
        labels,
        datasets: [
          {
            label: 'Número de Disparos',
            data: values,
            backgroundColor: 'rgba(75, 192, 192, 0.2)',
            borderColor: 'rgba(75, 192, 192, 1)',
            borderWidth: 1,
          },
        ],
      };
    },
    fetchAllData() {
      this.$store.dispatch('fetchTriggersMetric', {
        from: '2020-01-01',
        to: '2020-12-31',
      });
    },
  },
};
</script>
