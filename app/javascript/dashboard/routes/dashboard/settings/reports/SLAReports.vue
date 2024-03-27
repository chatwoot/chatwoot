<template>
  <div class="flex flex-col flex-1 gap-6 p-4 overflow-auto font-inter">
    <SLAMetrics :hit-rate="`12%`" :no-of-breaches="5" />
    <SLATable />
  </div>
</template>
<script>
import SLAMetrics from './components/SLA/SLAMetrics.vue';
import SLATable from './components/SLA/SLATable.vue';
export default {
  name: 'SLAReports',
  components: {
    SLAMetrics,
    SLATable,
  },
};
</script>
