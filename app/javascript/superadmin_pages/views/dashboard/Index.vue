<script setup>
/* eslint-disable vue/no-bare-strings-in-template */
import { computed, ref } from 'vue';
import BarChart from 'shared/components/charts/BarChart.vue';

const props = defineProps({
  componentData: {
    type: Object,
    default: () => ({}),
  },
});

const chartFilterOptions = [
  { value: '7', label: 'Last 7d' },
  { value: '30', label: 'Last 30d' },
];

const selectedChartFilter = ref(
  props.componentData.chartDays?.toString() || '7'
);

const onChartFilterChange = event => {
  const period = event.target.value;
  const url = new URL(window.location.href);
  url.searchParams.set('chart_period', period);
  window.location.href = url.toString();
};

const formatDate = dateString => {
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
};

const prepareData = sourceData => {
  const labels = [];
  const data = [];
  sourceData.forEach(item => {
    labels.push(formatDate(item[0]));
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
  <section class="flex flex-col w-full h-full">
    <header
      class="sticky top-0 z-10 bg-n-background border-b border-n-weak"
      role="banner"
    >
      <div
        class="flex items-center justify-between w-full h-16 mx-auto max-w-[60rem]"
      >
        <div class="flex items-center gap-3">
          <div class="border border-n-weak p-2 rounded-full text-n-slate-11">
            <svg width="24" height="24">
              <use xlink:href="#icon-layout-dashboard" />
            </svg>
          </div>
          <div class="flex flex-col justify-center">
            <h1
              id="page-title"
              class="text-base font-medium tracking-tight text-n-slate-12"
            >
              Admin Dashboard
            </h1>
            <p class="text-xs text-n-slate-11 m-0">
              Accounts, users, and conversation metrics
            </p>
          </div>
        </div>
      </div>
    </header>

    <main class="flex-1 px-6 overflow-y-auto">
      <div class="w-full mx-auto max-w-[60rem] py-8">
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          <div
            class="p-4 rounded-xl bg-n-solid-2 outline outline-1 outline-n-container shadow-sm"
          >
            <div class="text-3xl font-semibold text-n-slate-12">
              {{ accountsCount }}
            </div>
            <div class="text-sm text-n-slate-11">Accounts</div>
          </div>
          <div
            class="p-4 rounded-xl bg-n-solid-2 outline outline-1 outline-n-container shadow-sm"
          >
            <div class="text-3xl font-semibold text-n-slate-12">
              {{ usersCount }}
            </div>
            <div class="text-sm text-n-slate-11">Users</div>
          </div>
          <div
            class="p-4 rounded-xl bg-n-solid-2 outline outline-1 outline-n-container shadow-sm"
          >
            <div class="text-3xl font-semibold text-n-slate-12">
              {{ inboxesCount }}
            </div>
            <div class="text-sm text-n-slate-11">Inboxes</div>
          </div>
          <div
            class="p-4 rounded-xl bg-n-solid-2 outline outline-1 outline-n-container shadow-sm"
          >
            <div class="text-3xl font-semibold text-n-slate-12">
              {{ conversationsCount }}
            </div>
            <div class="text-sm text-n-slate-11">Conversations (30d)</div>
          </div>
        </div>

        <div
          class="px-6 pt-4 pb-6 rounded-xl bg-n-solid-2 outline outline-1 outline-n-container shadow-sm"
        >
          <div class="flex items-center justify-between mb-4">
            <div class="text-base font-semibold text-n-slate-12">
              Conversations
            </div>
            <select
              v-model="selectedChartFilter"
              class="w-auto px-3 py-1.5 text-sm rounded-lg border border-n-weak bg-n-background text-n-slate-12 cursor-pointer focus:outline-none focus:ring-2 focus:ring-n-brand"
              @change="onChartFilterChange"
            >
              <option
                v-for="option in chartFilterOptions"
                :key="option.value"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>
          </div>
          <div class="h-[300px]">
            <BarChart class="w-full h-full" :collection="chartData" />
          </div>
        </div>
      </div>
    </main>
  </section>
</template>
