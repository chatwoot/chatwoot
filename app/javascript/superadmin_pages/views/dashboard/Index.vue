<script setup>
import BarChart from 'shared/components/charts/BarChart.vue';
const props = defineProps({
  componentData: {
    type: Object,
    default: () => ({}),
  },
});

const {
  accountsCount,
  usersCount,
  inboxesCount,
  conversationsCount,
  chartData,
} = props.componentData;

const prepareData = data => {
  var labels = [];
  var datasets = [];
  data.forEach(item => {
    labels.push(item[0]);
    datasets.push(item[1]);
  });
  return { labels, datasets };
};
</script>

<template>
  <div class="w-full h-full">
    <header class="main-content__header" role="banner">
      <h1 id="page-title" class="main-content__page-title">Admin Dashboard</h1>
    </header>

    <section class="main-content__body main-content__body--flush">
      <div class="report--list">
        <div class="report-card">
          <div class="metric">{{ accountsCount }}</div>
          <div>Accounts</div>
        </div>
        <div class="report-card">
          <div class="metric">{{ usersCount }}</div>
          <div>Users</div>
        </div>
        <div class="report-card">
          <div class="metric">{{ inboxesCount }}</div>
          <div>Inboxes</div>
        </div>
        <div class="report-card">
          <div class="metric">{{ conversationsCount }}</div>
          <div>Conversations</div>
        </div>
      </div>
    </section>
    <BarChart
      class="p-8 w-full"
      :collection="prepareData(chartData)"
      style="max-height: 500px"
    />
  </div>
</template>
