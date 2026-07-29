<script setup>
import { computed, onMounted, ref } from 'vue';
import BarChart from 'shared/components/charts/BarChart.vue';

const stats = ref(null);
const failed = ref(false);

const loading = computed(() => !stats.value && !failed.value);

onMounted(async () => {
  try {
    const response = await fetch(window.location.pathname, {
      headers: { Accept: 'application/json' },
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    stats.value = await response.json();
  } catch {
    failed.value = true;
  }
});

const metrics = computed(() => [
  { label: 'Accounts', value: stats.value?.accountsCount },
  { label: 'Users', value: stats.value?.usersCount },
  { label: 'Inboxes', value: stats.value?.inboxesCount },
  { label: 'Conversations', value: stats.value?.conversationsCount },
]);

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
  return prepareData(stats.value?.chartData || []);
});
</script>

<template>
  <div class="w-full h-full">
    <header class="main-content__header" role="banner">
      <h1 id="page-title" class="main-content__page-title">
        {{ 'Admin Dashboard' }}
      </h1>
    </header>

    <section class="main-content__body main-content__body--flush">
      <div class="report--list">
        <div v-for="item in metrics" :key="item.label" class="report-card">
          <div class="metric">
            <span
              v-if="loading"
              class="inline-block w-20 h-8 rounded bg-woot-100 animate-pulse"
            />
            <template v-else>{{ item.value || 'N/A' }}</template>
          </div>
          <div>{{ item.label }}</div>
        </div>
      </div>
    </section>
    <!-- eslint-disable vue/no-static-inline-styles -->
    <div
      v-if="loading"
      class="p-8 mx-8 h-64 rounded bg-woot-100 animate-pulse"
    />
    <BarChart
      v-else-if="!failed"
      class="p-8 w-full"
      :collection="chartData"
      style="max-height: 500px"
    />
  </div>
</template>
