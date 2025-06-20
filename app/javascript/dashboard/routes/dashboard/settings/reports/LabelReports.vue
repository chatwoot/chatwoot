<template>
  <div class="column overflow-auto flex-1 pt-4">
    <metric-card
      :is-live="false"
      header="All Labels overview"
      :show-download-button="true"
      :download-filters="filters"
      :download-type="'labelOverview'"
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
        :download-button-label="$t('LABEL_REPORTS.DOWNLOAD_LABEL_REPORTS')"
        :show-advanced-filters="true"
        @filter-change="handleFilterChange"
      />
    </metric-card>
    <metric-card
      :is-live="false"
      header="Label wise conversation states"
      :show-download-button="true"
      :download-filters="filters"
      :download-type="'labelConversationStates'"
      :is-loading="uiFlags.isLabelConversationStatesReportsLoading"
      loading-message="Loading metrics"
    >
      <woot-summary-reports
        key="label-reports"
        class="!p-0"
        type="label"
        getter-key="labels/getLabels"
        action-key="summaryReports/fetchCustomLabelConversationStatesReports"
        summary-key="summaryReports/getCustomLabelConversationStatesReports"
        :download-button-label="$t('LABEL_REPORTS.DOWNLOAD_LABEL_REPORTS')"
        :show-advanced-filters="true"
        @filter-change="handleFilterChange"
      />
    </metric-card>
  </div>
</template>

<script>
import WootSummaryReports from './components/WootSummaryReports.vue';
import MetricCard from './components/overview/MetricCard.vue';
import { mapGetters } from 'vuex';

export default {
  components: {
    WootSummaryReports,
    MetricCard,
  },
  data() {
    return {
      filters: {},
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'summaryReports/getUiFlags',
    }),
  },
  methods: {
    handleFilterChange(filter) {
      this.filters = filter;
    },
  },
};
</script>
