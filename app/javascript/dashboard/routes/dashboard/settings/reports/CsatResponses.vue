<template>
  <div class="column content-box">
    <report-date-range-selector @date-range-change="onDateRangeChange" />
    <csat-metrics />
    <csat-table :page-index="pageIndex" @page-change="onPageNumberChange" />
  </div>
</template>
<script>
import CsatMetrics from './components/CsatMetrics';
import CsatTable from './components/CsatTable';
import ReportDateRangeSelector from './components/DateRangeSelector';

export default {
  name: 'CsatResponses',
  components: {
    CsatMetrics,
    CsatTable,
    ReportDateRangeSelector,
  },
  data() {
    return { pageIndex: 1, from: 0, to: 0 };
  },
  methods: {
    getAllData() {
      this.$store.dispatch('csat/getMetrics', { from: this.from, to: this.to });
      this.getResponses();
    },
    getResponses() {
      this.$store.dispatch('csat/get', {
        page: this.pageIndex,
        from: this.from,
        to: this.to,
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
  },
};
</script>
