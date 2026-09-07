<script setup>
import { computed, onMounted, ref } from 'vue';
import format from 'date-fns/format';
import parseISO from 'date-fns/parseISO';
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

const chartAriaLabel = 'Conversations created by day';

const chartData = computed(() => {
  const sourceData = stats.value?.chartData || [];
  return {
    categories: sourceData.map(([label]) => format(parseISO(label), 'dd-MMM')),
    series: [
      {
        id: 'conversations',
        label: 'Conversations',
        color: '#1f93ff',
        data: sourceData.map(([, value]) => value),
      },
    ],
  };
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
    <div
      v-if="loading"
      class="p-8 mx-8 h-64 rounded bg-woot-100 animate-pulse"
    />
    <div v-else-if="!failed" class="p-8 w-full min-w-0">
      <BarChart
        :data="chartData"
        :height="500"
        timeseries
        :aria-label="chartAriaLabel"
      />
    </div>
  </div>
</template>
