<template>
  <div class="column overflow-auto">
    <metric-card :is-live="false" header="All inboxes overview">
      <woot-summary-reports
        key="inbox-view-reports"
        class="!p-0"
        type="inbox"
        getter-key="inboxes/getInboxes"
        action-key="summaryReports/fetchInboxSummaryReports"
        summary-key="summaryReports/getInboxSummaryReports"
        :download-button-label="$t('INBOX_REPORTS.DOWNLOAD_INBOX_REPORTS')"
      />
    </metric-card>
    <metric-card
      :is-live="false"
      header="Inbox-wise reports"
      class="overflow-visible"
    >
      <woot-reports
        key="inbox-reports"
        :show-download-button="false"
        class="!p-0"
        type="inbox"
        getter-key="inboxes/getInboxes"
        action-key="inboxes/get"
      />
    </metric-card>
  </div>
</template>

<script>
import WootSummaryReports from './components/WootSummaryReports.vue';
import MetricCard from './components/overview/MetricCard.vue';
import WootReports from './components/WootReports.vue';

export default {
  components: {
    WootReports,
    MetricCard,
    WootSummaryReports,
  },
  mounted() {
    this.$store.dispatch('agents/get');
  },
};
</script>
