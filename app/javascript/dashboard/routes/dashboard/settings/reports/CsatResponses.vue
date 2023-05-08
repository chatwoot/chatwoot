<template>
  <div class="column content-box">
    <report-filter-selector
      :show-agents-filter="true"
      :agents-filter-items-list="agentList"
      :show-business-hours-switch="false"
      @filter-change="onFilterChange"
    />
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="arrow-download"
      @click="downloadReports"
    >
      {{ $t('CSAT_REPORTS.DOWNLOAD') }}
    </woot-button>
    <csat-metrics />
    <csat-table :page-index="pageIndex" @page-change="onPageNumberChange" />
  </div>
</template>
<script>
import CsatMetrics from './components/CsatMetrics';
import CsatTable from './components/CsatTable';
import ReportFilterSelector from './components/FilterSelector';
import { mapGetters } from 'vuex';
import { generateFileName } from '../../../../helper/downloadHelper';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';

export default {
  name: 'CsatResponses',
  components: {
    CsatMetrics,
    CsatTable,
    ReportFilterSelector,
  },
  data() {
    return { pageIndex: 1, from: 0, to: 0, userIds: [] };
  },
  computed: {
    ...mapGetters({
      agentList: 'agents/getAgents',
    }),
  },
  mounted() {
    this.$store.dispatch('agents/get');
  },
  methods: {
    getAllData() {
      this.$store.dispatch('csat/getMetrics', {
        from: this.from,
        to: this.to,
        user_ids: this.userIds,
      });
      this.getResponses();
    },
    getResponses() {
      this.$store.dispatch('csat/get', {
        page: this.pageIndex,
        from: this.from,
        to: this.to,
        user_ids: this.userIds,
      });
    },
    onPageNumberChange(pageIndex) {
      this.pageIndex = pageIndex;
      this.getResponses();
    },
    onFilterChange({ from, to, selectedAgents }) {
      // do not track filter change on inital load
      if (this.from !== 0 && this.to !== 0) {
        this.$track(REPORTS_EVENTS.FILTER_REPORT, {
          filterType: 'date',
          reportType: 'csat',
        });
      }

      this.from = from;
      this.to = to;
      this.userIds = selectedAgents.map(el => el.id);
      this.getAllData();
    },
    downloadReports() {
      const type = 'csat';
      this.$store.dispatch('csat/downloadCSATReports', {
        from: this.from,
        to: this.to,
        user_ids: this.userIds,
        fileName: generateFileName({ type, to: this.to }),
      });
    },
  },
};
</script>
