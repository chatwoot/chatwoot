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
          <h3 class="heading">
            {{ name }}
          </h3>
          <p class="metric">{{ metric }}</p>
        </div>
      </metric-card>
    </div>
    <div class="row">
      <metric-card header="Gráfico"> sdksjd </metric-card>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { TRIGGERS_METRICS } from './constants';
import MetricCard from './components/overview/MetricCard.vue';

export default {
  name: 'TriggerReports',
  components: {
    MetricCard,
  },
  data() {
    return {};
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
  mounted() {
    this.fetchAllData();
  },
  methods: {
    fetchAllData() {
      this.fetchTriggersMetric();
    },
    fetchTriggersMetric() {
      this.$store.dispatch('fetchTriggersMetric');
    },
  },
};
</script>
