<template>
  <div class="flex-1 overflow-auto p-4">
    <div class="row">
      <div class="column small-12 medium-8 conversation-metric">
        <metric-card
          header="Relatório de Disparos"
          :is-loading="uiFlags.isFetchingAccountConversationMetric"
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
    </div>
    <div class="row">
      <metric-card header="Relatório de Disparos">
        <report-heatmap
          :heat-data="accountConversationHeatmap"
          :is-loading="uiFlags.isFetchingAccountConversationsHeatmap"
        />
      </metric-card>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
export default {
  name: 'TriggerReports',
  components: {},
  data() {
    return {};
  },
  computed: {
    ...mapGetters({
      uiFlags: 'agents/uiFlags',
      conversationMetrics: 'agents/conversationMetrics',
      accountConversationHeatmap: 'agents/accountConversationHeatmap',
    }),
  },
  mounted() {
    this.$store.dispatch('agents/get');
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
