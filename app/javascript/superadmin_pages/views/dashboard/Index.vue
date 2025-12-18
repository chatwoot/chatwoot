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
  <section class="flex flex-col w-full h-full">
    <header
      class="sticky top-0 z-10 bg-n-background border-b border-n-weak"
      role="banner"
    >
      <div
        class="flex items-center justify-between w-full h-20 mx-auto max-w-[60rem]"
      >
        <div class="flex items-center gap-3">
          <div
            class="border border-n-weak p-2 rounded-full text-n-slate-11"
          >
            <svg width="24" height="24">
              <use xlink:href="#icon-dashboard-line" />
            </svg>
          </div>
          <div class="flex flex-col justify-center">
            <h1 id="page-title" class="text-base font-medium tracking-tight text-n-slate-12">
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
      <div class="w-full mx-auto max-w-[60rem] py-4">
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
            <div class="text-sm text-n-slate-11">Conversations</div>
          </div>
        </div>

        <div
          class="p-6 rounded-xl bg-n-solid-2 outline outline-1 outline-n-container shadow-sm"
        >
          <BarChart class="w-full max-h-[500px]" :collection="chartData" />
        </div>
      </div>
    </main>
  </section>
</template>
