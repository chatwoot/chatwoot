<script setup>
import { computed } from 'vue';
import BarChart from 'shared/components/charts/BarChart.vue';
const props = defineProps({
  componentData: {
    type: Object,
    default: () => ({}),
  },
});

const prepareData = sourceData => {
  var labels = [];
  var data = [];
  sourceData.forEach(item => {
    labels.push(item[0]);
    data.push(item[1]);
  });
  return {
    labels,
    datasets: [
      {
        type: 'bar',
        backgroundColor: 'rgb(31, 147, 255)',
        yAxisID: 'y',
        label: 'Conversations',
        data: data,
      },
    ],
  };
};

const chartData = computed(() => {
  return prepareData(props.componentData.chartData);
});

const { accountsCount, usersCount, inboxesCount, conversationsCount } =
  props.componentData;
</script>

<template>
  <div class="w-full h-full">
    <header class="main-content__header" role="banner">
      <h1 id="page-title" class="main-content__page-title">
        <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
        {{ 'Admin Dashboard' }}
        <!-- eslint-enable-next-line @intlify/vue-i18n/no-raw-text -->
      </h1>
    </header>

    <section class="main-content__body main-content__body--flush">
      <div class="report--list">
        <div class="report-card">
          <div class="metric">{{ accountsCount }}</div>
          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
          <div>{{ 'Accounts' }}</div>
          <!-- eslint-enable-next-line @intlify/vue-i18n/no-raw-text -->
        </div>
        <div class="report-card">
          <div class="metric">{{ usersCount }}</div>
          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
          <div>{{ 'Users' }}</div>
          <!-- eslint-enable-next-line @intlify/vue-i18n/no-raw-text -->
        </div>
        <div class="report-card">
          <div class="metric">{{ inboxesCount }}</div>
          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
          <div>{{ 'Inboxes' }}</div>
          <!-- eslint-enable-next-line @intlify/vue-i18n/no-raw-text -->
        </div>
        <div class="report-card">
          <div class="metric">{{ conversationsCount }}</div>
          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
          <div>{{ 'Conversations' }}</div>
          <!-- eslint-enable-next-line @intlify/vue-i18n/no-raw-text -->
        </div>
      </div>
    </section>
    <!-- eslint-disable vue/no-static-inline-styles -->
    <BarChart
      class="p-8 w-full"
      :collection="chartData"
      style="max-height: 500px"
    />
  </div>
</template>
