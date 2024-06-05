<template>
  <div class="flex-1 overflow-auto p-4">
    <div class="row">
      <metric-card
        :is-live="false"
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
    ...mapGetters({}),
    conversationMetrics() {
      return {
        'Total de disparos': 0,
        'Disparos enviados': 0,
        'Disparos pendentes': 0,
      };
    },
  },
  mounted() {
    this.fetchAllData();
  },
  methods: {
    fetchAllData() {
      // eslint-disable-next-line no-console
      console.log('fetchAllData');
    },
  },
};
</script>
