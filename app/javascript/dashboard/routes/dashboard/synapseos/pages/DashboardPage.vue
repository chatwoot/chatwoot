<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import axios from 'axios';
import Chart from 'primevue/chart';
import SynapseButton from 'next/synapseos/SynapseButton.vue';
import SynapseCard from 'next/synapseos/SynapseCard.vue';
import SynapseKpiCard from 'next/synapseos/SynapseKpiCard.vue';
import SynapseStatusPill from 'next/synapseos/SynapseStatusPill.vue';
import SynapseBadge from 'next/synapseos/SynapseBadge.vue';
import LiveReports from '../../settings/reports/LiveReports.vue';

const { t } = useI18n();
const route = useRoute();

const periodOptions = [
  { label: '7d', value: 7 },
  { label: '30d', value: 30 },
  { label: '90d', value: 90 },
];

const tabs = computed(() => [
  { key: 'overview', label: t('SYNAPSEOS.DASHBOARD.TABS.OVERVIEW') },
  { key: 'reports', label: t('SYNAPSEOS.DASHBOARD.TABS.REPORTS') },
]);
const activeTab = ref('overview');

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

const primaryKpis = computed(() => {
  const k = summary.value?.kpis || {};
  return [
    {
      key: 'leads',
      label: t('SYNAPSEOS.DASHBOARD.KPI.LEADS'),
      value: formatNumber(k.leads),
      icon: 'i-lucide-target',
      tone: 'brand',
    },
    {
      key: 'deals_won',
      label: t('SYNAPSEOS.DASHBOARD.KPI.DEALS_WON'),
      value: formatNumber(k.deals_won),
      icon: 'i-lucide-trophy',
      tone: 'success',
    },
    {
      key: 'revenue',
      label: t('SYNAPSEOS.DASHBOARD.KPI.REVENUE'),
      value: formatCurrency(k.revenue),
      icon: 'i-lucide-dollar-sign',
      tone: 'success',
    },
    {
      key: 'conversion_rate',
      label: t('SYNAPSEOS.DASHBOARD.KPI.CONVERSION_RATE'),
      value: formatPercent(k.conversion_rate),
      icon: 'i-lucide-trending-up',
      tone: 'brand',
    },
  ];
});

const secondaryKpis = computed(() => {
  const k = summary.value?.kpis || {};
  return [
    {
      key: 'messages_received',
      label: t('SYNAPSEOS.DASHBOARD.KPI.MESSAGES_RECEIVED'),
      value: formatNumber(k.messages_received),
      icon: 'i-lucide-message-square',
      tone: 'neutral',
    },
    {
      key: 'messages_sent',
      label: t('SYNAPSEOS.DASHBOARD.KPI.MESSAGES_SENT'),
      value: formatNumber(k.messages_sent),
      icon: 'i-lucide-send',
      tone: 'neutral',
    },
    {
      key: 'ai_responses',
      label: t('SYNAPSEOS.DASHBOARD.KPI.AI_RESPONSES'),
      value: formatNumber(k.ai_responses),
      icon: 'i-lucide-sparkles',
      tone: 'brand',
    },
    {
      key: 'appointments',
      label: t('SYNAPSEOS.DASHBOARD.KPI.APPOINTMENTS'),
      value: formatNumber(k.appointments),
      icon: 'i-lucide-calendar-check',
      tone: 'warning',
    },
  ];
});

const operationalCards = computed(() => {
  const k = summary.value?.kpis || {};
  return [
    {
      key: 'bot_takeovers',
      label: t('SYNAPSEOS.DASHBOARD.KPI.BOT_TAKEOVERS'),
      value: formatNumber(k.bot_takeovers),
      valueClass: 'text-s-warning-text',
    },
    {
      key: 'human_rescues',
      label: t('SYNAPSEOS.DASHBOARD.KPI.HUMAN_RESCUES'),
      value: formatNumber(k.human_rescues),
      valueClass: 'text-s-error-text',
    },
    {
      key: 'deals_lost',
      label: t('SYNAPSEOS.DASHBOARD.KPI.DEALS_LOST'),
      value: formatNumber(k.deals_lost),
      valueClass: 'text-s-primary',
    },
  ];
});

const eventTypeMeta = {
  lead_created: { icon: 'i-lucide-user-plus', tone: 'neutral' },
  lead_qualified: { icon: 'i-lucide-star', tone: 'brand' },
  lead_disqualified: { icon: 'i-lucide-x-circle', tone: 'neutral' },
  deal_created: { icon: 'i-lucide-file-plus', tone: 'neutral' },
  deal_won: { icon: 'i-lucide-check-circle', tone: 'success' },
  deal_lost: { icon: 'i-lucide-x-circle', tone: 'error' },
  bot_takeover: { icon: 'i-lucide-user-cog', tone: 'warning' },
  human_rescue: { icon: 'i-lucide-bot', tone: 'error' },
  appointment_confirmed: { icon: 'i-lucide-calendar-check', tone: 'warning' },
  private_note_added: { icon: 'i-lucide-sticky-note', tone: 'neutral' },
};

const recentEvents = computed(() => {
  return (summary.value?.recent_events || []).map(ev => ({
    ...ev,
    meta: eventTypeMeta[ev.event_type] || { icon: 'i-lucide-circle-dot', tone: 'neutral' },
    label: t(`SYNAPSEOS.DASHBOARD.EVENT_TYPE.${ev.event_type.toUpperCase()}`, ev.event_type),
    relativeTime: formatRelativeTime(ev.created_at),
  }));
});

const formatRelativeTime = iso => {
  if (!iso) return '';
  const then = new Date(iso).getTime();
  const delta = Math.max(0, Math.floor((Date.now() - then) / 1000));
  if (delta < 60) return `${delta}s`;
  if (delta < 3600) return `${Math.floor(delta / 60)}m`;
  if (delta < 86400) return `${Math.floor(delta / 3600)}h`;
  return `${Math.floor(delta / 86400)}d`;
};

const chartData = computed(() => {
  const days = summary.value?.daily || [];
  return {
    labels: days.map(d => d.date.slice(5)),
    datasets: [
      {
        label: t('SYNAPSEOS.DASHBOARD.CHART.MESSAGES_RECEIVED'),
        data: days.map(d => d.messages_received),
        borderColor: 'rgb(33, 150, 243)',
        backgroundColor: ctx => {
          const { ctx: c, chartArea } = ctx.chart;
          if (!chartArea) return 'rgba(33, 150, 243, 0.15)';
          const gradient = c.createLinearGradient(0, chartArea.top, 0, chartArea.bottom);
          gradient.addColorStop(0, 'rgba(33, 150, 243, 0.15)');
          gradient.addColorStop(1, 'rgba(33, 150, 243, 0)');
          return gradient;
        },
        fill: true,
        tension: 0.35,
      },
      {
        label: t('SYNAPSEOS.DASHBOARD.CHART.MESSAGES_SENT'),
        data: days.map(d => d.messages_sent),
        borderColor: 'rgb(13, 71, 161)',
        backgroundColor: 'rgba(13, 71, 161, 0.08)',
        fill: false,
        tension: 0.35,
      },
      {
        label: t('SYNAPSEOS.DASHBOARD.CHART.AI_RESPONSES'),
        data: days.map(d => d.ai_responses),
        borderColor: 'rgb(124, 58, 237)',
        backgroundColor: 'rgba(124, 58, 237, 0.08)',
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
    tooltip: {
      backgroundColor: '#FFFFFF',
      titleColor: '#0F172A',
      bodyColor: '#475569',
      borderColor: '#E2E8F0',
      borderWidth: 1,
      padding: 12,
    },
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
  <div class="bg-s-bg p-8 space-y-6 h-full overflow-auto">
    <header class="flex flex-wrap items-end justify-between gap-4">
      <div class="flex flex-col gap-1">
        <h1 class="text-2xl font-semibold text-s-primary">
          {{ t('SYNAPSEOS.DASHBOARD.TITLE') }}
        </h1>
        <p class="text-sm text-s-muted">
          {{ t('SYNAPSEOS.DASHBOARD.SUBTITLE', { days: period }) }}
        </p>
      </div>
      <div v-if="activeTab === 'overview'" class="flex items-center gap-2">
        <SynapseButton
          v-for="opt in periodOptions"
          :key="opt.value"
          size="sm"
          :variant="period === opt.value ? 'primary' : 'outline'"
          @click="period = opt.value"
        >
          {{ opt.label }}
        </SynapseButton>
      </div>
    </header>

    <nav class="flex gap-6 border-b border-s-border-subtle">
      <button
        v-for="tab in tabs"
        :key="tab.key"
        type="button"
        :class="[
          'pb-3 text-sm font-medium transition-colors border-b-2 -mb-px',
          activeTab === tab.key
            ? 'text-s-primary border-s-primary'
            : 'text-s-muted border-transparent hover:text-s-secondary',
        ]"
        @click="activeTab = tab.key"
      >
        {{ tab.label }}
      </button>
    </nav>

    <template v-if="activeTab === 'overview'">
    <section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <SynapseKpiCard
        v-for="kpi in primaryKpis"
        :key="kpi.key"
        :label="kpi.label"
        :value="kpi.value"
        :icon="kpi.icon"
        :tone="kpi.tone"
      />
    </section>

    <section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <SynapseKpiCard
        v-for="kpi in secondaryKpis"
        :key="kpi.key"
        :label="kpi.label"
        :value="kpi.value"
        :icon="kpi.icon"
        :tone="kpi.tone"
      />
    </section>

    <section class="grid grid-cols-1 lg:grid-cols-3 gap-4">
      <SynapseCard v-for="op in operationalCards" :key="op.key">
        <div class="flex flex-col gap-1">
          <span class="text-xs font-medium uppercase tracking-wider text-s-muted">
            {{ op.label }}
          </span>
          <span :class="['text-3xl font-semibold', op.valueClass]">
            {{ op.value }}
          </span>
        </div>
      </SynapseCard>
    </section>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
      <div class="lg:col-span-2">
        <SynapseCard :title="t('SYNAPSEOS.DASHBOARD.CHART.TITLE')">
          <div class="h-80">
            <Chart
              v-if="!loading && chartData.labels.length"
              type="line"
              :data="chartData"
              :options="chartOptions"
              class="h-full"
            />
            <div v-else-if="loading" class="text-sm text-s-muted">
              {{ t('SYNAPSEOS.DASHBOARD.LOADING') }}
            </div>
            <div v-else class="text-sm text-s-muted">
              {{ t('SYNAPSEOS.DASHBOARD.NO_DATA') }}
            </div>
          </div>
        </SynapseCard>
      </div>

      <SynapseCard :title="t('SYNAPSEOS.DASHBOARD.RECENT_EVENTS.TITLE')">
        <ul v-if="recentEvents.length" class="flex flex-col gap-3">
          <li
            v-for="event in recentEvents"
            :key="event.id"
            class="flex items-start gap-3"
          >
            <span :class="['size-5 mt-0.5 shrink-0 text-s-secondary', event.meta.icon]" />
            <div class="flex flex-col min-w-0 flex-1 gap-1">
              <span class="text-sm font-medium text-s-primary truncate">
                {{ event.label }}
              </span>
              <div class="flex items-center gap-2 flex-wrap">
                <SynapseBadge :tone="event.meta.tone">
                  conv #{{ event.conversation_id || '—' }}
                </SynapseBadge>
                <span class="text-xs text-s-muted">
                  {{ event.relativeTime }}
                </span>
              </div>
            </div>
          </li>
        </ul>
        <div v-else class="text-sm text-s-muted">
          {{ t('SYNAPSEOS.DASHBOARD.RECENT_EVENTS.EMPTY') }}
        </div>
      </SynapseCard>
    </div>
    </template>

    <div v-else-if="activeTab === 'reports'">
      <LiveReports />
    </div>
  </div>
</template>
