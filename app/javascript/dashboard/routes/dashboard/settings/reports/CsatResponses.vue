<template>
  <div class="column content-box">
    <csat-metrics />
    <csat-table :page-index="pageIndex" @page-change="onPageNumberChange" />
  </div>
</template>
<script>
import CsatMetrics from './components/CsatMetrics';
import CsatTable from './components/CsatTable';
export default {
  name: 'CsatResponses',
  components: {
    CsatMetrics,
    CsatTable,
  },
  data() {
    return { pageIndex: 1 };
  },
  mounted() {
    this.$store.dispatch('csat/getMetrics');
    this.getData();
  },
  methods: {
    getData() {
      this.$store.dispatch('csat/get', { page: this.pageIndex });
    },
    onPageNumberChange(pageIndex) {
      this.pageIndex = pageIndex;
      this.getData();
    },
  },
};
</script>
