<script setup>
import { ref, computed, onMounted, onBeforeUnmount, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
/* global axios */
import Chart from 'primevue/chart';
import SynapseStatusPill from 'next/synapseos/SynapseStatusPill.vue';
import SynapseBadge from 'next/synapseos/SynapseBadge.vue';
import SynapseEmptyState from 'next/synapseos/SynapseEmptyState.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const { t } = useI18n();
const route = useRoute();

// Popup de detalhes do alerta (clique em ÚLTIMOS ALERTAS).
const alertDialog = ref(null);
const selectedAlert = ref(null);
const openAlert = event => {
  selectedAlert.value = event;
  alertDialog.value?.open();
};
const selectedAlertConversationUrl = computed(() => {
  const cid = selectedAlert.value?.conversation_id;
  if (!cid) return null;
  return `/app/accounts/${route.params.accountId}/conversations/${cid}`;
});

const periodOptions = [
  { label: '7d', value: 7 },
  { label: '30d', value: 30 },
  { label: '90d', value: 90 },
];

// CUSTOMIZAÇÃO_SYNAPSEOS: aba "Relatórios ao vivo" ocultada (cliente não usa
// no dash executivo). Só Visão geral.
const tabs = computed(() => [
  { key: 'overview', label: t('SYNAPSEOS.DASHBOARD.TABS.OVERVIEW') },
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
    // DISPAROS NO PERÍODO — métrica primária (substitui leads como 1º card).
    // Respeita o filtro de período (7d/30d/90d).
    {
      key: 'shoots_period',
      label: t('SYNAPSEOS.DASHBOARD.KPI.SHOOTS_PERIOD'),
      value: formatNumber(k.shoots_period),
      icon: 'i-lucide-zap',
      tone: 'brand',
    },
    // Negócios ganhos = leads na coluna "Ganho" da pipeline (stage_type 'won').
    {
      key: 'deals_won',
      label: t('SYNAPSEOS.DASHBOARD.KPI.DEALS_WON'),
      value: formatNumber(k.deals_won),
      hint: t('SYNAPSEOS.DASHBOARD.KPI.DEALS_WON_HINT'),
      icon: 'i-lucide-trophy',
      tone: 'success',
    },
    // Receita potencial = somatório do valor dos veículos mencionados
    // nos alertas (preco_brl_a_partir do metadata).
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
      hint: t('SYNAPSEOS.DASHBOARD.KPI.CONVERSION_RATE_HINT'),
      icon: 'i-lucide-trending-up',
      tone: 'brand',
    },
  ];
});

// Operacionais (dash executivo):
// - DISPAROS HOJE / NO MÊS: contatos distintos abordados (dia/mês, BRT).
// - ELISA → ATENDIMENTO HUMANO: qtd de alertas enviados ao time.
// - NEGÓCIOS PERDIDOS: leads na coluna "perdido" da pipeline (stage_type lost).
// 'Agendamentos' removido (vivia em 0). Removidos antes (não são métricas de
// negócio): Leads, Mensagens recebidas/enviadas, Respostas da IA.
const operationalCards = computed(() => {
  const k = summary.value?.kpis || {};
  return [
    // Disparos HOJE (dia corrente, BRT) — NÃO reage ao filtro de período.
    {
      key: 'shoots_today',
      label: t('SYNAPSEOS.DASHBOARD.KPI.SHOOTS_TODAY'),
      value: formatNumber(k.shoots_today),
      hint: t('SYNAPSEOS.DASHBOARD.KPI.SHOOTS_TODAY_HINT'),
      valueClass: 'text-s-primary',
    },
    // Disparos no mês corrente — NÃO reage ao filtro de período da tela
    // (diferente de SHOOTS_PERIOD, que respeita 7d/30d/90d).
    {
      key: 'shoots_month',
      label: t('SYNAPSEOS.DASHBOARD.KPI.SHOOTS_MONTH'),
      value: formatNumber(k.shoots_month),
      hint: t('SYNAPSEOS.DASHBOARD.KPI.SHOOTS_MONTH_HINT'),
      valueClass: 'text-s-primary',
    },
    {
      key: 'bot_takeovers',
      label: t('SYNAPSEOS.DASHBOARD.KPI.BOT_TAKEOVERS'),
      value: formatNumber(k.bot_takeovers),
      hint: t('SYNAPSEOS.DASHBOARD.KPI.BOT_TAKEOVERS_HINT'),
      valueClass: 'text-s-warning-text',
    },
    {
      key: 'deals_lost',
      label: t('SYNAPSEOS.DASHBOARD.KPI.DEALS_LOST'),
      value: formatNumber(k.deals_lost),
      valueClass: 'text-s-primary',
    },
    // 'Agendamentos' (appointments) removido: vivia em 0 (aguardando_visita
    // vazia) e ocupava o lugar de uma métrica útil. 'Disparos hoje' (acima)
    // assume o slot operacional diário.
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

// ATIVIDADE RECENTE — só últimos alertas de venda. Backend já filtra por
// sales_alert_dispatched e enriquece com contact_name + modelo_interesse.
// Render: nome do cliente em destaque + modelo de interesse como badge.
const recentEvents = computed(() => {
  return (summary.value?.recent_events || []).map(ev => ({
    ...ev,
    meta: eventTypeMeta[ev.event_type] || {
      icon: 'i-lucide-bell',
      tone: 'success',
    },
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

// Cores do chart alinhadas com a paleta Dexi (navy + cyan accent + neutros).
// Series principais usam cyan técnico; secundárias ficam em tons navy e
// âmbar pra manter diferenciação sem competir visualmente.
const chartData = computed(() => {
  const days = summary.value?.daily || [];
  return {
    labels: days.map(d => d.date.slice(5)),
    datasets: [
      {
        label: t('SYNAPSEOS.DASHBOARD.CHART.MESSAGES_RECEIVED'),
        data: days.map(d => d.messages_received),
        borderColor: 'rgb(0, 184, 217)',
        backgroundColor: ctx => {
          const { ctx: c, chartArea } = ctx.chart;
          if (!chartArea) return 'rgba(0, 184, 217, 0.15)';
          const gradient = c.createLinearGradient(
            0,
            chartArea.top,
            0,
            chartArea.bottom
          );
          gradient.addColorStop(0, 'rgba(0, 184, 217, 0.20)');
          gradient.addColorStop(1, 'rgba(0, 184, 217, 0)');
          return gradient;
        },
        fill: true,
        tension: 0.35,
        borderWidth: 2,
        pointRadius: 0,
        pointHoverRadius: 4,
      },
      {
        label: t('SYNAPSEOS.DASHBOARD.CHART.MESSAGES_SENT'),
        data: days.map(d => d.messages_sent),
        borderColor: 'rgb(11, 31, 58)',
        backgroundColor: 'transparent',
        fill: false,
        tension: 0.35,
        borderWidth: 2,
        pointRadius: 0,
        pointHoverRadius: 4,
      },
      {
        label: t('SYNAPSEOS.DASHBOARD.CHART.AI_RESPONSES'),
        data: days.map(d => d.ai_responses),
        borderColor: 'rgb(14, 116, 144)',
        backgroundColor: 'transparent',
        borderDash: [4, 4],
        fill: false,
        tension: 0.35,
        borderWidth: 1.5,
        pointRadius: 0,
      },
      {
        label: t('SYNAPSEOS.DASHBOARD.CHART.BOT_TAKEOVERS'),
        data: days.map(d => d.bot_takeovers),
        borderColor: 'rgb(154, 103, 0)',
        backgroundColor: 'transparent',
        fill: false,
        tension: 0.35,
        borderWidth: 1.5,
        pointRadius: 0,
      },
    ],
  };
});

const chartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: false,
  interaction: { mode: 'index', intersect: false },
  plugins: {
    legend: {
      position: 'bottom',
      labels: {
        boxWidth: 8,
        boxHeight: 8,
        padding: 20,
        font: { size: 11, family: 'Inter' },
        color: '#425466',
        usePointStyle: true,
        pointStyle: 'rectRounded',
      },
    },
    tooltip: {
      backgroundColor: '#0B1F3A',
      titleColor: '#FFFFFF',
      titleFont: { size: 11, weight: 600 },
      bodyColor: '#B8C4D4',
      bodyFont: { size: 12, family: 'Inter' },
      borderColor: '#1A4272',
      borderWidth: 1,
      padding: 12,
      cornerRadius: 6,
      usePointStyle: true,
    },
  },
  scales: {
    x: {
      grid: { display: false },
      ticks: { color: '#5B6B7A', font: { size: 10, family: 'Inter' } },
      border: { color: '#D7DFE8' },
    },
    y: {
      beginAtZero: true,
      grid: { color: 'rgba(215, 223, 232, 0.6)', drawBorder: false },
      ticks: { color: '#5B6B7A', font: { size: 10, family: 'Inter' } },
      border: { display: false },
    },
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
  <div class="bg-s-bg h-full w-full flex-1 min-w-0 overflow-auto">
    <!-- Header bar: compact mission-control style -->
    <header
      class="sticky top-0 z-10 bg-s-surface/95 backdrop-blur-sm border-b border-s-border px-4 md:px-6 py-3 flex flex-wrap items-center justify-between gap-3"
    >
      <div class="flex items-center gap-3 min-w-0">
        <div
          class="size-2 rounded-full bg-s-success animate-pulse"
          aria-hidden="true"
        />
        <div class="flex flex-col min-w-0">
          <h1
            class="text-sm md:text-base font-semibold text-s-primary leading-tight truncate"
          >
            {{ t('SYNAPSEOS.DASHBOARD.TITLE') }}
          </h1>
          <p class="text-xs text-s-muted">
            {{ t('SYNAPSEOS.DASHBOARD.SUBTITLE', { days: period }) }}
          </p>
        </div>
      </div>
      <div
        v-if="activeTab === 'overview'"
        class="flex items-center gap-1 p-1 rounded-lg bg-s-subtle border border-s-border"
      >
        <button
          v-for="opt in periodOptions"
          :key="opt.value"
          type="button"
          class="px-3 py-1 text-xs font-semibold rounded-md transition-colors tabular-nums"
          :class="[
            period === opt.value
              ? 'bg-s-surface text-s-primary shadow-s-sm'
              : 'text-s-muted hover:text-s-secondary',
          ]"
          @click="period = opt.value"
        >
          {{ opt.label }}
        </button>
      </div>
    </header>

    <nav
      v-if="tabs.length > 1"
      class="px-4 md:px-6 flex gap-5 border-b border-s-border"
    >
      <button
        v-for="tab in tabs"
        :key="tab.key"
        type="button"
        class="py-2.5 text-xs font-semibold uppercase tracking-wide transition-colors border-b-2 -mb-px"
        :class="[
          activeTab === tab.key
            ? 'text-s-primary border-s-accent-500'
            : 'text-s-muted border-transparent hover:text-s-secondary',
        ]"
        @click="activeTab = tab.key"
      >
        {{ tab.label }}
      </button>
    </nav>

    <template v-if="activeTab === 'overview'">
      <!-- HERO STRIP: 4 KPIs primários em faixa densa com divisores verticais (cockpit) -->
      <section
        class="grid grid-cols-2 lg:grid-cols-4 divide-x divide-s-border bg-s-surface border-b border-s-border"
      >
        <div
          v-for="kpi in primaryKpis"
          :key="kpi.key"
          class="px-4 md:px-6 py-5 flex flex-col gap-2 min-w-0"
        >
          <div class="flex items-center gap-2 text-s-muted">
            <span class="size-3.5 shrink-0" :class="[kpi.icon]" />
            <span
              class="text-[10px] font-semibold uppercase tracking-wider truncate"
            >
              {{ kpi.label }}
            </span>
          </div>
          <div
            class="text-2xl md:text-3xl font-semibold text-s-primary tabular-nums leading-tight truncate"
          >
            {{ kpi.value }}
          </div>
          <p
            v-if="kpi.hint"
            class="text-[10px] text-s-muted leading-snug"
          >
            {{ kpi.hint }}
          </p>
        </div>
      </section>

      <!-- OPERATIONAL STRIP: indicadores de operação, inline -->
      <section
        class="grid grid-cols-2 lg:grid-cols-4 divide-x divide-s-border bg-s-subtle/50 border-b border-s-border"
      >
        <div
          v-for="op in operationalCards"
          :key="op.key"
          class="px-4 md:px-6 py-2.5 flex items-center justify-between gap-2 min-w-0"
        >
          <div class="flex flex-col min-w-0">
            <span
              class="text-[10px] font-semibold uppercase tracking-wider text-s-muted truncate"
            >
              {{ op.label }}
            </span>
            <span
              v-if="op.hint"
              class="text-[10px] text-s-muted/80 leading-snug truncate"
            >
              {{ op.hint }}
            </span>
          </div>
          <span
            class="text-sm font-semibold tabular-nums shrink-0"
            :class="[op.valueClass]"
          >
            {{ op.value }}
          </span>
        </div>
      </section>

      <!-- MAIN GRID: chart (2/3) + event feed (1/3) -->
      <div class="p-4 md:p-6 grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div class="lg:col-span-2">
          <div
            class="bg-s-surface border border-s-border rounded-lg overflow-hidden"
          >
            <div
              class="px-5 py-3 border-b border-s-border flex items-center justify-between"
            >
              <h3
                class="text-xs font-semibold uppercase tracking-wider text-s-secondary"
              >
                {{ t('SYNAPSEOS.DASHBOARD.CHART.TITLE') }}
              </h3>
              <SynapseStatusPill tone="success" size="sm">
                {{ period }}d
              </SynapseStatusPill>
            </div>
            <div class="p-4 h-80">
              <Chart
                v-if="!loading && chartData.labels.length"
                type="line"
                :data="chartData"
                :options="chartOptions"
                class="h-full"
              />
              <div
                v-else-if="loading"
                class="h-full flex items-center justify-center text-xs text-s-muted"
              >
                {{ t('SYNAPSEOS.DASHBOARD.LOADING') }}
              </div>
              <SynapseEmptyState
                v-else
                icon="i-lucide-line-chart"
                :title="t('SYNAPSEOS.DASHBOARD.EMPTY_CHART_TITLE')"
                :description="t('SYNAPSEOS.DASHBOARD.EMPTY_CHART_DESCRIPTION')"
                size="sm"
              />
            </div>
          </div>
        </div>

        <div
          class="bg-s-surface border border-s-border rounded-lg overflow-hidden flex flex-col"
        >
          <div
            class="px-5 py-3 border-b border-s-border flex items-center justify-between"
          >
            <h3
              class="text-xs font-semibold uppercase tracking-wider text-s-secondary"
            >
              {{ t('SYNAPSEOS.DASHBOARD.RECENT_EVENTS.TITLE') }}
            </h3>
            <span
              v-if="recentEvents.length"
              class="text-[10px] font-mono text-s-muted tabular-nums"
            >
              {{ recentEvents.length }}
            </span>
          </div>
          <ul
            v-if="recentEvents.length"
            class="flex flex-col divide-y divide-s-border-subtle overflow-auto max-h-80"
          >
            <li
              v-for="event in recentEvents"
              :key="event.id"
              class="flex items-start gap-3 px-5 py-3 hover:bg-s-subtle/50 transition-colors cursor-pointer"
              role="button"
              tabindex="0"
              @click="openAlert(event)"
              @keydown.enter="openAlert(event)"
            >
              <span
                :class="[
                  'size-4 mt-0.5 shrink-0 text-s-success-text',
                  event.meta.icon,
                ]"
              />
              <div class="flex flex-col min-w-0 flex-1 gap-1">
                <!-- Cliente + veículo de interesse (formato pedido pelo produto) -->
                <span class="text-sm font-medium text-s-primary truncate">
                  {{ event.contact_name || '—' }}
                </span>
                <div class="flex items-center gap-2 flex-wrap">
                  <SynapseBadge tone="brand">
                    🚗 {{ event.modelo_interesse || 'a definir' }}
                  </SynapseBadge>
                  <span class="text-[11px] font-mono text-s-muted tabular-nums">
                    {{ event.relativeTime }}
                  </span>
                </div>
              </div>
            </li>
          </ul>
          <div v-else class="flex-1 flex items-center">
            <SynapseEmptyState
              icon="i-lucide-activity"
              :title="t('SYNAPSEOS.DASHBOARD.EMPTY_EVENTS_TITLE')"
              :description="t('SYNAPSEOS.DASHBOARD.EMPTY_EVENTS_DESCRIPTION')"
              size="sm"
              class="w-full"
            />
          </div>
        </div>
      </div>
    </template>

    <!-- Popup de detalhes do alerta -->
    <Dialog
      ref="alertDialog"
      :title="t('SYNAPSEOS.DASHBOARD.ALERT_DETAILS.TITLE')"
      :show-confirm-button="false"
      :cancel-button-label="t('SYNAPSEOS.DASHBOARD.ALERT_DETAILS.CLOSE')"
    >
      <div v-if="selectedAlert" class="flex flex-col gap-3 text-sm">
        <div class="flex flex-col gap-0.5">
          <span class="text-[10px] font-semibold uppercase tracking-wider text-s-muted">
            {{ t('SYNAPSEOS.DASHBOARD.ALERT_DETAILS.CLIENT') }}
          </span>
          <span class="text-s-primary font-medium">{{ selectedAlert.contact_name || '—' }}</span>
        </div>
        <div class="flex flex-col gap-0.5">
          <span class="text-[10px] font-semibold uppercase tracking-wider text-s-muted">
            {{ t('SYNAPSEOS.DASHBOARD.ALERT_DETAILS.INTEREST') }}
          </span>
          <span class="text-s-primary">🚗 {{ selectedAlert.modelo_interesse || 'a definir' }}</span>
        </div>
        <div v-if="selectedAlert.tipo" class="flex flex-col gap-0.5">
          <span class="text-[10px] font-semibold uppercase tracking-wider text-s-muted">
            {{ t('SYNAPSEOS.DASHBOARD.ALERT_DETAILS.REASON') }}
          </span>
          <span class="text-s-primary">{{ selectedAlert.tipo }}</span>
        </div>
        <div
          v-if="selectedAlert.metadata && selectedAlert.metadata.observacoes"
          class="flex flex-col gap-0.5"
        >
          <span class="text-[10px] font-semibold uppercase tracking-wider text-s-muted">
            {{ t('SYNAPSEOS.DASHBOARD.ALERT_DETAILS.NOTES') }}
          </span>
          <span class="text-s-secondary whitespace-pre-line">{{ selectedAlert.metadata.observacoes }}</span>
        </div>
        <a
          v-if="selectedAlertConversationUrl"
          :href="selectedAlertConversationUrl"
          class="text-s-accent-600 hover:underline text-xs font-semibold mt-1"
        >
          {{ t('SYNAPSEOS.DASHBOARD.ALERT_DETAILS.OPEN_CONVERSATION') }} →
        </a>
      </div>
    </Dialog>
  </div>
</template>
