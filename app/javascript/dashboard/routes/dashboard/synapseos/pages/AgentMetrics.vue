<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import SynapseCard from 'next/synapseos/SynapseCard.vue';
import SynapseButton from 'next/synapseos/SynapseButton.vue';
import SynapseStatusPill from 'next/synapseos/SynapseStatusPill.vue';
import {
  useAgentMetricsStore,
  RANGE_OPTIONS,
} from 'dashboard/store/synapseos/useAgentMetrics';
import {
  formatBRL,
  formatPercent,
  formatSeconds,
  formatCount,
  EMPTY,
} from 'dashboard/helper/synapseos/metricsFormatters';

const { t } = useI18n();
const route = useRoute();
const store = useAgentMetricsStore();

const accountId = computed(() => route.params.accountId);

// Agent card declarative configuration.
// Each card has: slug, icon, tone, hero KPI (large), secondary KPIs (smaller rows).
const AGENT_CARDS = {
  alice: {
    icon: 'i-lucide-target',
    tone: 'brand',
    hero: { key: 'leads_frios_contactados', format: 'count' },
    secondary: [
      { key: 'taxa_resposta', format: 'percent' },
      { key: 'leads_convertidos', format: 'count' },
    ],
  },
  iza: {
    icon: 'i-lucide-sparkles',
    tone: 'brand',
    hero: { key: 'leads_inbound_recepcionados', format: 'count' },
    secondary: [
      { key: 'speed_to_lead_seconds', format: 'seconds' },
      { key: 'taxa_qualificacao', format: 'percent' },
      { key: 'handoffs', format: 'count' },
    ],
  },
  otto: {
    icon: 'i-lucide-bot',
    tone: 'brand',
    hero: { key: 'interacoes_crm', format: 'count' },
    secondary: [
      { key: 'alertas_sla', format: 'count' },
      { key: 'resgates', format: 'count' },
    ],
  },
  luis: {
    icon: 'i-lucide-wrench',
    tone: 'info',
    hero: { key: 'assistencias_tecnicas', format: 'count' },
    secondary: [],
  },
  fernanda: {
    icon: 'i-lucide-life-buoy',
    tone: 'success',
    hero: { key: 'pipeline_resgatado_cents', format: 'brl' },
    secondary: [{ key: 'leads_reativados', format: 'count' }],
  },
  angela: {
    icon: 'i-lucide-calendar-check',
    tone: 'warning',
    hero: { key: 'agendamentos', format: 'count' },
    secondary: [{ key: 'taxa_crosssell', format: 'percent' }],
  },
  vitor: {
    icon: 'i-lucide-hand-coins',
    tone: 'success',
    hero: { key: 'valor_recuperado_cents', format: 'brl' },
    secondary: [{ key: 'acordos_fechados', format: 'count' }],
  },
};

const GROUPS = [
  { key: 'FRONTLINE', slugs: ['alice', 'iza'] },
  { key: 'PARTNERS', slugs: ['otto', 'luis'] },
  { key: 'RESCUE', slugs: ['fernanda', 'angela', 'vitor'] },
];

const formatKpi = (format, value) => {
  if (format === 'brl') return formatBRL(value);
  if (format === 'percent') return formatPercent(value);
  if (format === 'seconds') return formatSeconds(value);
  return formatCount(value);
};

// Whether the hero/secondary KPI is a money or percentage one — drives visual priority.
const isHighlightFormat = format => format === 'brl' || format === 'percent';

const i18nAgentKey = slug => slug.toUpperCase();

const agentDisplayName = slug =>
  store.agents[slug]?.displayName ||
  t(`SYNAPSEOS.METRICS.AGENTS.${i18nAgentKey(slug)}.NAME`);

const kpiLabel = (slug, key) =>
  t(`SYNAPSEOS.METRICS.AGENTS.${i18nAgentKey(slug)}.KPI.${key.toUpperCase()}`);

const lastUpdatedLabel = computed(() => {
  if (!store.lastUpdatedAt) return EMPTY;
  const d = new Date(store.lastUpdatedAt);
  return d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
});

const refreshAll = () => store.fetchAll({ accountId: accountId.value });

const selectRange = rangeKey => {
  store.range = rangeKey;
  store.since = new Date(
    Date.now() - (RANGE_OPTIONS.find(r => r.key === rangeKey)?.hours || 720) * 3600 * 1000
  ).toISOString();
  refreshAll();
};

onMounted(refreshAll);
</script>

<template>
  <div class="bg-s-bg p-8 space-y-8 h-full overflow-auto">
    <header class="flex flex-col md:flex-row md:items-start md:justify-between gap-4">
      <div class="flex flex-col gap-1">
        <h1 class="text-2xl font-semibold text-s-primary">
          {{ t('SYNAPSEOS.METRICS.TITLE') }}
        </h1>
        <p class="text-sm text-s-muted">
          {{ t('SYNAPSEOS.METRICS.SUBTITLE') }}
        </p>
      </div>
      <div class="flex items-center gap-3">
        <div
          class="inline-flex rounded-lg border border-s-border bg-s-surface p-0.5"
          role="group"
        >
          <button
            v-for="r in RANGE_OPTIONS"
            :key="r.key"
            type="button"
            :class="[
              'px-3 h-8 text-xs font-medium rounded-md transition-colors',
              store.range === r.key
                ? 'bg-s-brand-soft text-s-brand-text'
                : 'text-s-secondary hover:bg-s-subtle',
            ]"
            @click="selectRange(r.key)"
          >
            {{ t(r.labelKey) }}
          </button>
        </div>
        <SynapseButton
          variant="outline"
          size="sm"
          icon="i-lucide-refresh-cw"
          @click="refreshAll"
        >
          {{ t('SYNAPSEOS.METRICS.REFRESH') }}
        </SynapseButton>
        <span class="text-xs text-s-muted whitespace-nowrap">
          {{ t('SYNAPSEOS.METRICS.LAST_UPDATED', { time: lastUpdatedLabel }) }}
        </span>
      </div>
    </header>

    <section v-for="group in GROUPS" :key="group.key" class="space-y-4">
      <div class="flex items-center gap-3">
        <h2 class="text-lg font-semibold text-s-primary">
          {{ t(`SYNAPSEOS.METRICS.GROUPS.${group.key}`) }}
        </h2>
        <span class="h-px flex-1 bg-s-border-subtle" />
        <SynapseStatusPill tone="neutral" size="sm">
          {{ t('SYNAPSEOS.METRICS.AGENT_COUNT', group.slugs.length) }}
        </SynapseStatusPill>
      </div>

      <div
        class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5"
      >
        <SynapseCard
          v-for="slug in group.slugs"
          :key="slug"
          padding="none"
        >
          <div class="p-6 flex flex-col gap-5">
            <!-- Header: icon + agent name + status chip -->
            <div class="flex items-start justify-between gap-3">
              <div class="flex items-center gap-3 min-w-0">
                <span
                  :class="[
                    'inline-flex items-center justify-center size-10 rounded-xl shrink-0',
                    `bg-s-${AGENT_CARDS[slug].tone}-soft`,
                    `text-s-${AGENT_CARDS[slug].tone}-text`,
                  ]"
                >
                  <span :class="['size-5', AGENT_CARDS[slug].icon]" />
                </span>
                <div class="flex flex-col min-w-0">
                  <span class="text-base font-semibold text-s-primary truncate">
                    {{ agentDisplayName(slug) }}
                  </span>
                  <span class="text-xs text-s-muted">
                    {{ t(`SYNAPSEOS.METRICS.AGENTS.${i18nAgentKey(slug)}.ROLE`) }}
                  </span>
                </div>
              </div>
              <SynapseStatusPill
                v-if="store.agents[slug].error"
                tone="error"
                size="sm"
              >
                {{ t('SYNAPSEOS.METRICS.ERROR') }}
              </SynapseStatusPill>
            </div>

            <!-- Loading skeleton -->
            <div v-if="store.agents[slug].isLoading" class="flex flex-col gap-4">
              <div class="h-12 rounded bg-s-subtle animate-pulse" />
              <div class="h-4 rounded bg-s-subtle animate-pulse w-3/4" />
              <div class="h-4 rounded bg-s-subtle animate-pulse w-2/3" />
            </div>

            <!-- Error -->
            <div
              v-else-if="store.agents[slug].error"
              class="text-sm text-s-error-text"
            >
              {{ t('SYNAPSEOS.METRICS.ERROR') }}
            </div>

            <!-- Data -->
            <template v-else>
              <!-- Hero KPI -->
              <div class="flex flex-col gap-1">
                <span class="text-xs font-medium uppercase tracking-wider text-s-muted">
                  {{ kpiLabel(slug, AGENT_CARDS[slug].hero.key) }}
                </span>
                <span
                  :class="[
                    'font-synapse font-bold tracking-tight leading-none text-[2.75rem]',
                    isHighlightFormat(AGENT_CARDS[slug].hero.format)
                      ? 'text-s-brand'
                      : 'text-s-primary',
                  ]"
                >
                  {{
                    formatKpi(
                      AGENT_CARDS[slug].hero.format,
                      store.agents[slug].kpis[AGENT_CARDS[slug].hero.key]
                    )
                  }}
                </span>
              </div>

              <!-- Secondary KPIs -->
              <div
                v-if="AGENT_CARDS[slug].secondary.length"
                class="flex flex-col gap-3 pt-3 border-t border-s-border-subtle"
              >
                <div
                  v-for="kpi in AGENT_CARDS[slug].secondary"
                  :key="kpi.key"
                  class="flex items-center justify-between gap-3"
                >
                  <span class="text-sm text-s-muted">
                    {{ kpiLabel(slug, kpi.key) }}
                  </span>
                  <span
                    :class="[
                      'text-base font-semibold',
                      isHighlightFormat(kpi.format)
                        ? 'text-s-brand-text'
                        : 'text-s-primary',
                    ]"
                  >
                    {{ formatKpi(kpi.format, store.agents[slug].kpis[kpi.key]) }}
                  </span>
                </div>
              </div>
            </template>
          </div>
        </SynapseCard>
      </div>
    </section>
  </div>
</template>
