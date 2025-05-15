<template>
  <div class="column overflow-auto flex-1 pt-4">
    <metric-card
      :is-live="false"
      header="All Labels overview"
      :is-loading="uiFlags.isLabelConversationStatesReportsLoading"
      loading-message="Loading metrics"
    >
      <woot-summary-reports
        key="labels-reports"
        class="!p-0"
        type="label"
        getter-key="labels/getLabels"
        action-key="summaryReports/fetchCustomLabelConversationStatesReports"
        summary-key="summaryReports/getCustomLabelConversationStatesReports"
      />
    </metric-card>
    <woot-reports
      key="label-reports"
      type="label"
      getter-key="labels/getLabels"
      action-key="labels/get"
      :download-button-label="$t('LABEL_REPORTS.DOWNLOAD_LABEL_REPORTS')"
    />
  </div>
</template>

<script>
import WootReports from './components/WootReports.vue';
import WootSummaryReports from './components/WootSummaryReports.vue';
import MetricCard from './components/overview/MetricCard.vue';
import { mapGetters } from 'vuex';

export default {
  components: {
    WootReports,
    WootSummaryReports,
    MetricCard,
  },
  computed: {
    ...mapGetters({
      uiFlags: 'summaryReports/getUiFlags',
    }),
  },
};
</script>
