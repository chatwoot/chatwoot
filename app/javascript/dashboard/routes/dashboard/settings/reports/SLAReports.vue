<template>
  <div class="flex flex-col flex-1 overflow-auto p-4 font-inter gap-6">
    <SLAMetrics />
    <SLATable />
  </div>
</template>
<script>
import SLAMetrics from './SLAMetrics.vue';
import SLATable from './SLATable.vue';
export default {
  name: 'SLAReports',
  components: {
    SLAMetrics,
    SLATable,
  },
};
</script>
