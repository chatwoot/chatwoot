<template>
  <div class="column content-box">
    <report-filter-selector
      agents-filter
      :agents-filter-items-list="agentList"
      @date-range-change="onDateRangeChange"
      @agents-filter-change="onAgentsFilterChange"
    />
    <csat-metrics />
    <csat-table :page-index="pageIndex" @page-change="onPageNumberChange" />
  </div>
</template>
<script>
import CsatMetrics from './components/CsatMetrics';
import CsatTable from './components/CsatTable';
import ReportFilterSelector from './components/FilterSelector';
import { mapGetters } from 'vuex';

export default {
  name: 'CsatResponses',
  components: {
    CsatMetrics,
    CsatTable,
    ReportFilterSelector,
  },
  data() {
    return { pageIndex: 1, from: 0, to: 0, user_ids: [] };
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
        user_ids: this.user_ids,
      });
      this.getResponses();
    },
    getResponses() {
      this.$store.dispatch('csat/get', {
        page: this.pageIndex,
        from: this.from,
        to: this.to,
        user_ids: this.user_ids,
      });
    },
    onPageNumberChange(pageIndex) {
      this.pageIndex = pageIndex;
      this.getResponses();
    },
    onDateRangeChange({ from, to }) {
      this.from = from;
      this.to = to;
      this.getAllData();
    },
    onAgentsFilterChange(agents) {
      this.user_ids = agents.map(el => el.id);
      this.getAllData();
    },
  },
};
</script>
