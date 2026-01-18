<script setup>
import { computed } from 'vue';
import BarChart from 'shared/components/charts/BarChart.vue';

const props = defineProps({
  componentData: {
    type: Object,
    default: () => ({}),
  },
});

const prepareChartData = sourceData => {
  const labels = [];
  const data = [];
  sourceData.forEach(item => {
    labels.push(item[0]);
    data.push(item[1]);
  });
  return {
    labels,
    datasets: [
      {
        type: 'bar',
        backgroundColor: 'rgb(147, 51, 234)',
        yAxisID: 'y',
        label: 'AI Traces',
        data: data,
      },
    ],
  };
};

const chartData = computed(() => {
  return prepareChartData(props.componentData.chartData || []);
});

const stats = computed(() => props.componentData.stats || {});
</script>

<template>
  <div class="w-full h-full">
    <header
      class="flex px-8 py-4 items-center border-b border-n-weak"
      role="banner"
    >
      <div class="border border-n-weak mr-4 p-2 rounded-full">
        <svg width="24" height="24">
          <use xlink:href="#icon-sparkles" />
        </svg>
      </div>
      <div class="flex flex-col h-14 justify-center">
        <h1
          id="page-title"
          class="text-base font-medium leading-6 text-n-slate-12"
        >
          {{ 'Aloo AI Analytics' }}
        </h1>
        <p class="text-sm font-normal leading-5 text-slate-500 m-0">
          {{ 'Monitor AI usage, token consumption, and performance metrics' }}
        </p>
      </div>
    </header>

    <section class="main-content__body px-8 py-6">
      <!-- Stats Grid -->
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4 mb-8">
        <div
          class="bg-white p-4 rounded-lg shadow-sm border border-slate-100 outline outline-1 outline-n-container"
        >
          <div class="text-2xl font-bold text-purple-600">
            {{ stats.assistants_count || '0' }}
          </div>
          <div class="text-sm text-slate-600">{{ 'Assistants' }}</div>
        </div>
        <div
          class="bg-white p-4 rounded-lg shadow-sm border border-slate-100 outline outline-1 outline-n-container"
        >
          <div class="text-2xl font-bold text-blue-600">
            {{ stats.total_conversations || '0' }}
          </div>
          <div class="text-sm text-slate-600">{{ 'AI Conversations' }}</div>
        </div>
        <div
          class="bg-white p-4 rounded-lg shadow-sm border border-slate-100 outline outline-1 outline-n-container"
        >
          <div class="text-2xl font-bold text-green-600">
            {{ stats.documents_count || '0' }}
          </div>
          <div class="text-sm text-slate-600">{{ 'Documents' }}</div>
        </div>
        <div
          class="bg-white p-4 rounded-lg shadow-sm border border-slate-100 outline outline-1 outline-n-container"
        >
          <div class="text-2xl font-bold text-orange-600">
            {{ stats.embeddings_count || '0' }}
          </div>
          <div class="text-sm text-slate-600">{{ 'Embeddings' }}</div>
        </div>
        <div
          class="bg-white p-4 rounded-lg shadow-sm border border-slate-100 outline outline-1 outline-n-container"
        >
          <div class="text-2xl font-bold text-pink-600">
            {{ stats.memories_count || '0' }}
          </div>
          <div class="text-sm text-slate-600">{{ 'Memories' }}</div>
        </div>
      </div>

      <!-- Token Usage Section -->
      <div class="mb-8">
        <h3 class="text-lg font-medium text-slate-800 mb-4">
          {{ 'Token Usage' }}
        </h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div
            class="bg-white p-4 rounded-lg shadow-sm border border-slate-100 outline outline-1 outline-n-container"
          >
            <div class="flex items-center justify-between">
              <div>
                <div class="text-2xl font-bold text-indigo-600">
                  {{ stats.total_input_tokens || '0' }}
                </div>
                <div class="text-sm text-slate-600">{{ 'Input Tokens' }}</div>
              </div>
              <div
                class="w-10 h-10 bg-indigo-100 rounded-full flex items-center justify-center"
              >
                <svg
                  class="w-5 h-5 text-indigo-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M7 16l-4-4m0 0l4-4m-4 4h18"
                  />
                </svg>
              </div>
            </div>
          </div>
          <div
            class="bg-white p-4 rounded-lg shadow-sm border border-slate-100 outline outline-1 outline-n-container"
          >
            <div class="flex items-center justify-between">
              <div>
                <div class="text-2xl font-bold text-teal-600">
                  {{ stats.total_output_tokens || '0' }}
                </div>
                <div class="text-sm text-slate-600">{{ 'Output Tokens' }}</div>
              </div>
              <div
                class="w-10 h-10 bg-teal-100 rounded-full flex items-center justify-center"
              >
                <svg
                  class="w-5 h-5 text-teal-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M17 8l4 4m0 0l-4 4m4-4H3"
                  />
                </svg>
              </div>
            </div>
          </div>
          <div
            class="bg-white p-4 rounded-lg shadow-sm border border-slate-100 outline outline-1 outline-n-container"
          >
            <div class="flex items-center justify-between">
              <div>
                <div class="text-2xl font-bold text-emerald-600">
                  {{ stats.success_rate || '0%' }}
                </div>
                <div class="text-sm text-slate-600">
                  {{ 'Success Rate (30d)' }}
                </div>
              </div>
              <div
                class="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center"
              >
                <svg
                  class="w-5 h-5 text-emerald-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Performance Section -->
      <div class="mb-8">
        <h3 class="text-lg font-medium text-slate-800 mb-4">
          {{ 'Performance (Last 30 Days)' }}
        </h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div
            class="bg-white p-4 rounded-lg shadow-sm border border-slate-100 outline outline-1 outline-n-container"
          >
            <div class="flex items-center justify-between">
              <div>
                <div class="text-2xl font-bold text-slate-700">
                  {{ stats.traces_count || '0' }}
                </div>
                <div class="text-sm text-slate-600">
                  {{ 'Total AI Traces' }}
                </div>
              </div>
              <div
                class="w-10 h-10 bg-slate-100 rounded-full flex items-center justify-center"
              >
                <svg
                  class="w-5 h-5 text-slate-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                  />
                </svg>
              </div>
            </div>
          </div>
          <div
            class="bg-white p-4 rounded-lg shadow-sm border border-slate-100 outline outline-1 outline-n-container"
          >
            <div class="flex items-center justify-between">
              <div>
                <div class="text-2xl font-bold text-red-600">
                  {{ stats.failed_traces_count || '0' }}
                </div>
                <div class="text-sm text-slate-600">{{ 'Failed Traces' }}</div>
              </div>
              <div
                class="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center"
              >
                <svg
                  class="w-5 h-5 text-red-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Chart Section -->
      <div
        v-if="chartData.labels && chartData.labels.length > 0"
        class="bg-white p-6 rounded-lg shadow-sm border border-slate-100 outline outline-1 outline-n-container"
      >
        <h3 class="text-lg font-medium text-slate-800 mb-4">
          {{ 'AI Traces Over Time' }}
        </h3>
        <!-- eslint-disable vue/no-static-inline-styles -->
        <BarChart
          class="w-full"
          :collection="chartData"
          style="max-height: 400px"
        />
      </div>
      <div
        v-else
        class="bg-white p-6 rounded-lg shadow-sm border border-slate-100 outline outline-1 outline-n-container text-center text-slate-500"
      >
        <p>
          {{
            'No trace data available yet. AI traces will appear here once Aloo AI is configured and in use.'
          }}
        </p>
      </div>
    </section>
  </div>
</template>
