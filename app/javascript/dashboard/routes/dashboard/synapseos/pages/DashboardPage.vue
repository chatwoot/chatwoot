<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import axios from 'axios';
import Card from 'primevue/card';
import Chart from 'primevue/chart';
import SelectButton from 'primevue/selectbutton';

const { t } = useI18n();
const route = useRoute();

const periodOptions = [
  { label: '7d', value: 7 },
  { label: '30d', value: 30 },
  { label: '90d', value: 90 },
];

const period = ref(30);
const summary = ref(null);
const loading = ref(true);
const refreshTimer = ref(null);

const fetchSummary = async () => {
  const accountId = route.params.accountId;
  loading.value = true;
  try {
    const { data } = await axios.get(
      `/api/v1/accounts/${accountId}/synapseos/dashboard/summary`,
      { params: { days: period.value } }
    );
    summary.value = data;
  } finally {
    loading.value = false;
  }
};

const formatCurrency = value => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(value || 0);
};

const formatNumber = value => {
  return new Intl.NumberFormat('pt-BR').format(value || 0);
};

const formatPercent = value => `${(value || 0).toFixed(1)}%`;

const kpiCards = computed(() => {
  const k = summary.value?.kpis || {};
  return [
    { key: 'leads', label: t('SYNAPSEOS.DASHBOARD.KPI.LEADS'), value: formatNumber(k.leads), icon: 'i-lucide-target', accent: 'text-n-blue-9' },
    { key: 'deals_won', label: t('SYNAPSEOS.DASHBOARD.KPI.DEALS_WON'), value: formatNumber(k.deals_won), icon: 'i-lucide-trophy', accent: 'text-n-teal-9' },
    { key: 'revenue', label: t('SYNAPSEOS.DASHBOARD.KPI.REVENUE'), value: formatCurrency(k.revenue), icon: 'i-lucide-dollar-sign', accent: 'text-n-teal-9' },
    { key: 'conversion_rate', label: t('SYNAPSEOS.DASHBOARD.KPI.CONVERSION_RATE'), value: formatPercent(k.conversion_rate), icon: 'i-lucide-trending-up', accent: 'text-n-blue-9' },
    { key: 'messages_received', label: t('SYNAPSEOS.DASHBOARD.KPI.MESSAGES_RECEIVED'), value: formatNumber(k.messages_received), icon: 'i-lucide-message-square', accent: 'text-n-slate-11' },
    { key: 'messages_sent', label: t('SYNAPSEOS.DASHBOARD.KPI.MESSAGES_SENT'), value: formatNumber(k.messages_sent), icon: 'i-lucide-send', accent: 'text-n-slate-11' },
    { key: 'ai_responses', label: t('SYNAPSEOS.DASHBOARD.KPI.AI_RESPONSES'), value: formatNumber(k.ai_responses), icon: 'i-lucide-sparkles', accent: 'text-n-violet-9' },
    { key: 'appointments', label: t('SYNAPSEOS.DASHBOARD.KPI.APPOINTMENTS'), value: formatNumber(k.appointments), icon: 'i-lucide-calendar-check', accent: 'text-n-amber-9' },
  ];
});

const operationalCards = computed(() => {
  const k = summary.value?.kpis || {};
  return [
    { key: 'bot_takeovers', label: t('SYNAPSEOS.DASHBOARD.KPI.BOT_TAKEOVERS'), value: formatNumber(k.bot_takeovers), tone: 'warning' },
    { key: 'human_rescues', label: t('SYNAPSEOS.DASHBOARD.KPI.HUMAN_RESCUES'), value: formatNumber(k.human_rescues), tone: 'critical' },
    { key: 'deals_lost', label: t('SYNAPSEOS.DASHBOARD.KPI.DEALS_LOST'), value: formatNumber(k.deals_lost), tone: 'neutral' },
  ];
});

const chartData = computed(() => {
  const days = summary.value?.daily || [];
  return {
    labels: days.map(d => d.date.slice(5)),
    datasets: [
      {
        label: t('SYNAPSEOS.DASHBOARD.CHART.MESSAGES_RECEIVED'),
        data: days.map(d => d.messages_received),
        borderColor: 'rgb(33, 150, 243)',
        backgroundColor: 'rgba(33, 150, 243, 0.15)',
        fill: true,
        tension: 0.35,
      },
      {
        label: t('SYNAPSEOS.DASHBOARD.CHART.MESSAGES_SENT'),
        data: days.map(d => d.messages_sent),
        borderColor: 'rgb(13, 71, 161)',
        backgroundColor: 'rgba(13, 71, 161, 0.10)',
        fill: true,
        tension: 0.35,
      },
      {
        label: t('SYNAPSEOS.DASHBOARD.CHART.AI_RESPONSES'),
        data: days.map(d => d.ai_responses),
        borderColor: 'rgb(124, 58, 237)',
        backgroundColor: 'rgba(124, 58, 237, 0.10)',
        fill: false,
        tension: 0.35,
      },
      {
        label: t('SYNAPSEOS.DASHBOARD.CHART.BOT_TAKEOVERS'),
        data: days.map(d => d.bot_takeovers),
        borderColor: 'rgb(245, 158, 11)',
        backgroundColor: 'rgba(245, 158, 11, 0.08)',
        fill: false,
        tension: 0.35,
      },
    ],
  };
});

const chartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  interaction: { mode: 'index', intersect: false },
  plugins: {
    legend: { position: 'bottom', labels: { boxWidth: 12, padding: 16 } },
    tooltip: { backgroundColor: 'rgba(15, 23, 42, 0.95)', padding: 12 },
  },
  scales: {
    x: { grid: { display: false } },
    y: { beginAtZero: true, grid: { color: 'rgba(148, 163, 184, 0.15)' } },
  },
}));

watch(period, fetchSummary);

onMounted(() => {
  fetchSummary();
  refreshTimer.value = setInterval(fetchSummary, 30000);
});

onBeforeUnmount(() => {
  if (refreshTimer.value) clearInterval(refreshTimer.value);
});
</script>

<template>
  <div class="flex flex-col gap-6 p-6 h-full overflow-auto">
    <header class="flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 class="text-2xl font-semibold text-n-slate-12">
          {{ t('SYNAPSEOS.DASHBOARD.TITLE') }}
        </h1>
        <p class="text-sm text-n-slate-11">
          {{ t('SYNAPSEOS.DASHBOARD.SUBTITLE', { days: period }) }}
        </p>
      </div>
      <SelectButton
        v-model="period"
        :options="periodOptions"
        option-label="label"
        option-value="value"
        :allow-empty="false"
      />
    </header>

    <section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <Card v-for="kpi in kpiCards" :key="kpi.key" class="!shadow-none border border-n-weak">
        <template #content>
          <div class="flex items-start justify-between">
            <div class="flex flex-col gap-1">
              <span class="text-xs uppercase tracking-wide text-n-slate-10">{{ kpi.label }}</span>
              <span class="text-2xl font-semibold text-n-slate-12">{{ kpi.value }}</span>
            </div>
            <i :class="['size-9 inline-block', kpi.icon, kpi.accent]" />
          </div>
        </template>
      </Card>
    </section>

    <section class="grid grid-cols-1 lg:grid-cols-3 gap-4">
      <Card v-for="op in operationalCards" :key="op.key" class="!shadow-none border border-n-weak">
        <template #content>
          <div class="flex flex-col gap-1">
            <span class="text-xs uppercase tracking-wide text-n-slate-10">{{ op.label }}</span>
            <span
              class="text-3xl font-semibold"
              :class="{
                'text-n-amber-9': op.tone === 'warning',
                'text-n-ruby-9': op.tone === 'critical',
                'text-n-slate-12': op.tone === 'neutral',
              }"
            >
              {{ op.value }}
            </span>
          </div>
        </template>
      </Card>
    </section>

    <Card class="!shadow-none border border-n-weak">
      <template #title>
        <span class="text-base font-semibold text-n-slate-12">
          {{ t('SYNAPSEOS.DASHBOARD.CHART.TITLE') }}
        </span>
      </template>
      <template #content>
        <div class="h-80">
          <Chart
            v-if="!loading && chartData.labels.length"
            type="line"
            :data="chartData"
            :options="chartOptions"
            class="h-full"
          />
          <div v-else-if="loading" class="text-sm text-n-slate-10">
            {{ t('SYNAPSEOS.DASHBOARD.LOADING') }}
          </div>
          <div v-else class="text-sm text-n-slate-10">
            {{ t('SYNAPSEOS.DASHBOARD.NO_DATA') }}
          </div>
        </div>
      </template>
    </Card>
  </div>
</template>
