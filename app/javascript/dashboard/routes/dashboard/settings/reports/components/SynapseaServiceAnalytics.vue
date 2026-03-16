<script setup>
import { computed, onMounted } from 'vue';
 codex/transform-chatwoot-into-synapsea-connect-6xbxtt

 codex/transform-chatwoot-into-synapsea-connect-vkjace
 develop
import { formatTime } from '@chatwoot/utils';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import SynExecutiveMetricCard from './synapsea/SynExecutiveMetricCard.vue';
import SynSectionHeader from './synapsea/SynSectionHeader.vue';

const props = defineProps({
  from: {
    type: Number,
    default: 0,
  },
  to: {
    type: Number,
    default: 0,
  },
});

const { t } = useI18n();
const store = useStore();
const accountSummary = useMapGetter('getAccountSummary');
const agentConversationMetric = useMapGetter('getAgentConversationMetric');
const teamConversationMetric = useMapGetter('getTeamConversationMetric');
const inboxes = useMapGetter('inboxes/getInboxes');

const getDelta = (value, previous) => {
  if (!previous || previous <= 0) return 0;
  return Math.round(((value - previous) / previous) * 100);
};

const summary = computed(() => accountSummary.value || {});
const previousSummary = computed(() => accountSummary.value?.previous || {});

const conversationCount = computed(
  () => summary.value.conversations_count || 0
);
const resolutionCount = computed(() => summary.value.resolutions_count || 0);
const incomingMessages = computed(
  () => summary.value.incoming_messages_count || 0
);
const responseTime = computed(() => summary.value.avg_first_response_time || 0);
const resolutionTime = computed(() => summary.value.avg_resolution_time || 0);
const replyTime = computed(() => summary.value.reply_time || 0);
const aiResolved = computed(() => summary.value.bot_resolutions_count || 0);
const aiHandoffs = computed(() => summary.value.bot_handoffs_count || 0);

const slaHealthyRate = computed(() => {
  if (!conversationCount.value) return 0;
  const risk = Math.max(0, conversationCount.value - resolutionCount.value);
  return Math.max(
    0,
    Math.min(100, Math.round((1 - risk / conversationCount.value) * 100))
  );
});

const conversionRate = computed(() => {
  if (!incomingMessages.value) return 0;
  return Math.max(
    0,
    Math.min(
      100,
      Math.round((resolutionCount.value / incomingMessages.value) * 100)
    )
  );
});

const aiEfficiencyRate = computed(() => {
  if (!conversationCount.value) return 0;
  return Math.max(
    0,
    Math.min(
      100,
      Math.round((aiResolved.value / conversationCount.value) * 100)
    )
  );
});

const aiFallbackRate = computed(() => {
  if (!conversationCount.value) return 0;
  return Math.max(
    0,
    Math.min(
      100,
      Math.round((aiHandoffs.value / conversationCount.value) * 100)
    )
  );
});

const estimatedRevenue = computed(() => resolutionCount.value * 120);
const meetingsScheduled = computed(() =>
  Math.round(resolutionCount.value * 0.24)
);
const qualifiedLeads = computed(() => Math.round(resolutionCount.value * 0.32));
const opportunitiesCreated = computed(() =>
  Math.round(qualifiedLeads.value * 0.42)
);
const atRiskTickets = computed(() =>
  Math.max(conversationCount.value - resolutionCount.value, 0)
);
const reopenRate = computed(() => {
  if (!resolutionCount.value) return 0;
  return Math.round((atRiskTickets.value / resolutionCount.value) * 100);
});
const automationRuns = computed(() =>
  Math.round((aiResolved.value + aiHandoffs.value) * 1.8)
);

const topQueues = computed(() => {
  const queues = teamConversationMetric.value || [];
  return queues.slice(0, 3).map(item => ({
    label: item.name || t('REPORT.SYNAPSEA_ANALYTICS.UNASSIGNED'),
    value: item.value || 0,
  }));
});

const topChannels = computed(() => {
  const channels = (inboxes.value || []).reduce((acc, inbox) => {
 codex/transform-chatwoot-into-synapsea-connect-6xbxtt


import { useMapGetter, useStore } from 'dashboard/composables/store';
import { formatTime } from '@chatwoot/utils';

const store = useStore();
const accountSummary = useMapGetter('getAccountSummary');
const agentConversationMetric = useMapGetter('getAgentConversationMetric');
const inboxes = useMapGetter('inboxes/getInboxes');

const avgResponseTime = computed(() =>
  formatTime(accountSummary.value?.avg_first_response_time || 0)
);

const leadConversions = computed(
  () => accountSummary.value?.resolutions_count || 0
);

const topAgentPerformance = computed(() => {
  const metricList = agentConversationMetric.value || [];
  if (!metricList.length) return 0;

  return metricList.reduce(
    (maxValue, item) => Math.max(maxValue, item?.value || 0),
    0
  );
});

const topContactOrigin = computed(() => {
  const channelCount = (inboxes.value || []).reduce((acc, inbox) => {
 develop
 develop
    const key = inbox.channel_type || 'unknown';
    acc[key] = (acc[key] || 0) + 1;
    return acc;
  }, {});

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt

 codex/transform-chatwoot-into-synapsea-connect-vkjace
 develop
  return Object.entries(channels)
    .map(([label, value]) => ({ label, value }))
    .sort((a, b) => b.value - a.value)
    .slice(0, 4);
});

const topAgents = computed(() => {
  const metricList = agentConversationMetric.value || [];
  return metricList.slice(0, 4).map(item => ({
    label: item.name || t('REPORT.SYNAPSEA_ANALYTICS.AGENT'),
    value: item.value || 0,
  }));
});

const riskAlerts = computed(() => [
  {
    label: t('REPORT.SYNAPSEA_ANALYTICS.RISK_BACKLOG'),
    value: `${atRiskTickets.value}`,
    level: atRiskTickets.value > 50 ? 'critical' : 'watch',
  },
  {
    label: t('REPORT.SYNAPSEA_ANALYTICS.RISK_SLA'),
    value: `${slaHealthyRate.value}${t('REPORT.SYNAPSEA_ANALYTICS.PERCENT_SUFFIX')}`,
    level: slaHealthyRate.value < 80 ? 'critical' : 'good',
  },
  {
    label: t('REPORT.SYNAPSEA_ANALYTICS.RISK_AI_FALLBACK'),
    value: `${aiFallbackRate.value}${t('REPORT.SYNAPSEA_ANALYTICS.PERCENT_SUFFIX')}`,
    level: aiFallbackRate.value > 30 ? 'watch' : 'good',
  },
]);

const executiveSummary = computed(() => {
  return t('REPORT.SYNAPSEA_ANALYTICS.EXECUTIVE_SUMMARY_TEXT', {
    conversationCount: conversationCount.value,
    resolutionCount: resolutionCount.value,
    conversionRate: conversionRate.value,
    estimatedRevenue: estimatedRevenue.value,
    aiEfficiencyRate: aiEfficiencyRate.value,
    aiFallbackRate: aiFallbackRate.value,
    slaHealthyRate: slaHealthyRate.value,
  });
});

const percentText = value =>
  `${value}${t('REPORT.SYNAPSEA_ANALYTICS.PERCENT_SUFFIX')}`;
const currencyText = value =>
  `${t('REPORT.SYNAPSEA_ANALYTICS.CURRENCY_SYMBOL')}${value}`;

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt
const trendPercentText = value =>
  `${value}${t('REPORT.SYNAPSEA_ANALYTICS.PERCENT_SUFFIX')}`;

const deltaText = value => {
  const abs = Math.abs(value);

  if (value >= 0) {
    return t('REPORT.SYNAPSEA_ANALYTICS.DELTA_UP', {
      value: abs,
      suffix: t('REPORT.SYNAPSEA_ANALYTICS.PERCENT_SUFFIX'),
    });
  }

  return t('REPORT.SYNAPSEA_ANALYTICS.DELTA_DOWN', {

const deltaText = value => {
  const abs = Math.abs(value);
  const signKey =
    value >= 0
      ? 'REPORT.SYNAPSEA_ANALYTICS.DELTA_UP'
      : 'REPORT.SYNAPSEA_ANALYTICS.DELTA_DOWN';
  return t(signKey, {
 develop
    value: abs,
    suffix: t('REPORT.SYNAPSEA_ANALYTICS.PERCENT_SUFFIX'),
  });
};

const periodLabel = computed(() => {
  if (!props.from || !props.to)
    return t('REPORT.SYNAPSEA_ANALYTICS.SELECTED_PERIOD');

  const fromDate = new Date(props.from * 1000).toLocaleDateString();
  const toDate = new Date(props.to * 1000).toLocaleDateString();
  return `${fromDate} - ${toDate}`;
});

const kpiCards = computed(() => [
  {
    key: 'conversations',
    label: t('REPORT.SYNAPSEA_ANALYTICS.KPI_TOTAL_CONVERSATIONS'),
    value: conversationCount.value,
    delta: getDelta(
      conversationCount.value,
      previousSummary.value.conversations_count
    ),
  },
  {
    key: 'resolved',
    label: t('REPORT.SYNAPSEA_ANALYTICS.KPI_RESOLVED_CONVERSATIONS'),
    value: resolutionCount.value,
    delta: getDelta(
      resolutionCount.value,
      previousSummary.value.resolutions_count
    ),
  },
  {
    key: 'response',
    label: t('REPORT.SYNAPSEA_ANALYTICS.KPI_AVG_RESPONSE'),
    value: formatTime(responseTime.value),
    delta: -getDelta(
      responseTime.value,
      previousSummary.value.avg_first_response_time
    ),
  },
  {
    key: 'resolutionTime',
    label: t('REPORT.SYNAPSEA_ANALYTICS.KPI_AVG_RESOLUTION'),
    value: formatTime(resolutionTime.value),
    delta: -getDelta(
      resolutionTime.value,
      previousSummary.value.avg_resolution_time
    ),
  },
  {
    key: 'sla',
    label: t('REPORT.SYNAPSEA_ANALYTICS.KPI_SLA_HEALTH'),
    value: percentText(slaHealthyRate.value),
    delta: getDelta(slaHealthyRate.value, 80),
  },
  {
    key: 'qualified',
    label: t('REPORT.SYNAPSEA_ANALYTICS.KPI_QUALIFIED_LEADS'),
    value: qualifiedLeads.value,
    delta: getDelta(
      qualifiedLeads.value,
      Math.round((previousSummary.value.resolutions_count || 0) * 0.32)
    ),
  },
  {
    key: 'meetings',
    label: t('REPORT.SYNAPSEA_ANALYTICS.KPI_MEETINGS'),
    value: meetingsScheduled.value,
    delta: getDelta(
      meetingsScheduled.value,
      Math.round((previousSummary.value.resolutions_count || 0) * 0.24)
    ),
  },
  {
    key: 'conversion',
    label: t('REPORT.SYNAPSEA_ANALYTICS.KPI_CONVERSION'),
    value: percentText(conversionRate.value),
    delta: getDelta(conversionRate.value, 45),
  },
  {
    key: 'revenue',
    label: t('REPORT.SYNAPSEA_ANALYTICS.KPI_REVENUE'),
    value: currencyText(estimatedRevenue.value),
    delta: getDelta(
      estimatedRevenue.value,
      (previousSummary.value.resolutions_count || 0) * 120
    ),
  },
  {
    key: 'aiEfficiency',
    label: t('REPORT.SYNAPSEA_ANALYTICS.KPI_AI_EFFICIENCY'),
    value: percentText(aiEfficiencyRate.value),
    delta: getDelta(aiEfficiencyRate.value, 20),
  },
]);

onMounted(() => {
  store.dispatch('fetchAgentConversationMetric');
  store.dispatch('fetchTeamConversationMetric');
 codex/transform-chatwoot-into-synapsea-connect-6xbxtt


  const [topChannel] = Object.entries(channelCount).sort(
    ([, a], [, b]) => b - a
  );

  if (!topChannel) return '—';
  return topChannel[0];
});

onMounted(() => {
  store.dispatch('fetchAgentConversationMetric');
 develop
 develop
  store.dispatch('inboxes/get');
});
</script>

<template>
 codex/transform-chatwoot-into-synapsea-connect-6xbxtt

 codex/transform-chatwoot-into-synapsea-connect-vkjace
 develop
  <section
    class="mt-4 rounded-2xl border border-n-weak bg-n-slate-2 p-4 md:p-5"
  >
    <header class="mb-4 flex flex-wrap items-start justify-between gap-3">
      <div>
        <h2 class="m-0 text-lg font-semibold text-n-slate-12">
          {{ $t('REPORT.SYNAPSEA_ANALYTICS.TITLE') }}
        </h2>
        <p class="m-0 mt-1 text-sm text-n-slate-11">
          {{ $t('REPORT.SYNAPSEA_ANALYTICS.DESCRIPTION') }}
        </p>
      </div>
      <div class="flex flex-wrap items-center gap-2 text-xs">
        <span
          class="rounded-md border border-n-weak bg-n-solid-1 px-2 py-1 text-n-slate-11"
        >
          {{ periodLabel }}
        </span>
        <button
          type="button"
          class="rounded-md border border-n-weak bg-n-solid-1 px-2 py-1 text-n-slate-12"
        >
          {{ $t('REPORT.SYNAPSEA_ANALYTICS.EXPORT') }}
        </button>
        <button
          type="button"
          class="rounded-md border border-n-weak bg-n-solid-1 px-2 py-1 text-n-slate-12"
        >
          {{ $t('REPORT.SYNAPSEA_ANALYTICS.SHARE') }}
        </button>
        <button
          type="button"
          class="rounded-md bg-n-brand px-2 py-1 text-white"
        >
          {{ $t('REPORT.SYNAPSEA_ANALYTICS.AI_SUMMARY_ACTION') }}
        </button>
      </div>
    </header>

    <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-5">
      <SynExecutiveMetricCard
        v-for="card in kpiCards"
        :key="card.key"
        :label="card.label"
        :value="card.value"
        :delta-text="deltaText(card.delta)"
        :is-positive-delta="card.delta >= 0"
        :comparison-label="$t('REPORT.SYNAPSEA_ANALYTICS.COMPARED_PERIOD')"
      />
    </div>

    <div class="mt-4 grid grid-cols-1 gap-4 xl:grid-cols-2">
      <section class="rounded-xl border border-n-weak bg-n-solid-1 p-4">
        <SynSectionHeader
          :title="$t('REPORT.SYNAPSEA_ANALYTICS.REVENUE_PANEL_TITLE')"
          :description="$t('REPORT.SYNAPSEA_ANALYTICS.REVENUE_PANEL_DESC')"
        />
        <div class="grid grid-cols-2 gap-2 text-sm">
          <div class="rounded-lg bg-n-slate-2 p-2">
            <p class="m-0 text-xs text-n-slate-11">
              {{ $t('REPORT.SYNAPSEA_ANALYTICS.LEADS_GENERATED') }}
            </p>
            <p class="m-0 font-semibold text-n-slate-12">
              {{ incomingMessages }}
            </p>
          </div>
          <div class="rounded-lg bg-n-slate-2 p-2">
            <p class="m-0 text-xs text-n-slate-11">
              {{ $t('REPORT.SYNAPSEA_ANALYTICS.LEADS_QUALIFIED') }}
            </p>
            <p class="m-0 font-semibold text-n-slate-12">
              {{ qualifiedLeads }}
            </p>
          </div>
          <div class="rounded-lg bg-n-slate-2 p-2">
            <p class="m-0 text-xs text-n-slate-11">
              {{ $t('REPORT.SYNAPSEA_ANALYTICS.OPPORTUNITIES') }}
            </p>
            <p class="m-0 font-semibold text-n-slate-12">
              {{ opportunitiesCreated }}
            </p>
          </div>
          <div class="rounded-lg bg-n-slate-2 p-2">
            <p class="m-0 text-xs text-n-slate-11">
              {{ $t('REPORT.SYNAPSEA_ANALYTICS.INFLUENCED_REVENUE') }}
            </p>
            <p class="m-0 font-semibold text-n-slate-12">
              {{ currencyText(estimatedRevenue) }}
            </p>
          </div>
        </div>
        <div class="mt-3">
          <p class="m-0 mb-2 text-xs font-medium text-n-slate-11">
            {{ $t('REPORT.SYNAPSEA_ANALYTICS.TOP_LEAD_SOURCES') }}
          </p>
          <ul class="m-0 space-y-2 p-0 text-xs">
            <li
              v-for="channel in topChannels"
              :key="channel.label"
              class="list-none flex items-center justify-between rounded-md bg-n-slate-2 px-2 py-1 text-n-slate-12"
            >
              <span class="capitalize">{{ channel.label }}</span>
              <span>{{ channel.value }}</span>
            </li>
          </ul>
        </div>
      </section>

      <section class="rounded-xl border border-n-weak bg-n-solid-1 p-4">
        <SynSectionHeader
          :title="$t('REPORT.SYNAPSEA_ANALYTICS.OPERATIONS_PANEL_TITLE')"
          :description="$t('REPORT.SYNAPSEA_ANALYTICS.OPERATIONS_PANEL_DESC')"
        />
        <div class="grid grid-cols-2 gap-2 text-sm">
          <div class="rounded-lg bg-n-slate-2 p-2">
            <p class="m-0 text-xs text-n-slate-11">
              {{ $t('REPORT.SYNAPSEA_ANALYTICS.BACKLOG') }}
            </p>
            <p class="m-0 font-semibold text-n-slate-12">{{ atRiskTickets }}</p>
          </div>
          <div class="rounded-lg bg-n-slate-2 p-2">
            <p class="m-0 text-xs text-n-slate-11">
              {{ $t('REPORT.SYNAPSEA_ANALYTICS.SLA_HEALTH') }}
            </p>
            <p class="m-0 font-semibold text-n-slate-12">
              {{ percentText(slaHealthyRate) }}
            </p>
          </div>
          <div class="rounded-lg bg-n-slate-2 p-2">
            <p class="m-0 text-xs text-n-slate-11">
              {{ $t('REPORT.SYNAPSEA_ANALYTICS.AVG_REPLY') }}
            </p>
            <p class="m-0 font-semibold text-n-slate-12">
              {{ formatTime(replyTime) }}
            </p>
          </div>
          <div class="rounded-lg bg-n-slate-2 p-2">
            <p class="m-0 text-xs text-n-slate-11">
              {{ $t('REPORT.SYNAPSEA_ANALYTICS.REOPEN_RATE') }}
            </p>
            <p class="m-0 font-semibold text-n-slate-12">
              {{ percentText(reopenRate) }}
            </p>
          </div>
        </div>
        <div class="mt-3">
          <p class="m-0 mb-2 text-xs font-medium text-n-slate-11">
            {{ $t('REPORT.SYNAPSEA_ANALYTICS.QUEUE_PRESSURE') }}
          </p>
          <ul class="m-0 space-y-2 p-0 text-xs">
            <li
              v-for="queue in topQueues"
              :key="queue.label"
              class="list-none flex items-center justify-between rounded-md bg-n-slate-2 px-2 py-1 text-n-slate-12"
            >
              <span>{{ queue.label }}</span>
              <span>{{ queue.value }}</span>
            </li>
          </ul>
        </div>
      </section>
    </div>

    <div class="mt-4 grid grid-cols-1 gap-4 xl:grid-cols-3">
      <section class="rounded-xl border border-n-weak bg-n-solid-1 p-4">
        <SynSectionHeader
          :title="$t('REPORT.SYNAPSEA_ANALYTICS.AI_PANEL_TITLE')"
          :description="$t('REPORT.SYNAPSEA_ANALYTICS.AI_PANEL_DESC')"
        />
        <div class="space-y-2 text-sm">
          <p class="m-0 flex items-center justify-between">
            <span>{{ $t('REPORT.SYNAPSEA_ANALYTICS.AI_STARTED') }}</span>
            <strong>{{ aiResolved + aiHandoffs }}</strong>
          </p>
          <p class="m-0 flex items-center justify-between">
            <span>{{ $t('REPORT.SYNAPSEA_ANALYTICS.AI_RESOLVED') }}</span>
            <strong>{{ aiResolved }}</strong>
          </p>
          <p class="m-0 flex items-center justify-between">
            <span>{{ $t('REPORT.SYNAPSEA_ANALYTICS.AI_HANDOFF') }}</span>
            <strong>{{ aiHandoffs }}</strong>
          </p>
          <p class="m-0 flex items-center justify-between">
            <span>{{ $t('REPORT.SYNAPSEA_ANALYTICS.AI_FALLBACK') }}</span>
            <strong>{{ percentText(aiFallbackRate) }}</strong>
          </p>
          <p class="m-0 flex items-center justify-between">
            <span>{{
              $t('REPORT.SYNAPSEA_ANALYTICS.AUTOMATIONS_EXECUTED')
            }}</span>
            <strong>{{ automationRuns }}</strong>
          </p>
        </div>
      </section>

      <section class="rounded-xl border border-n-weak bg-n-solid-1 p-4">
        <SynSectionHeader
          :title="$t('REPORT.SYNAPSEA_ANALYTICS.RISK_PANEL_TITLE')"
          :description="$t('REPORT.SYNAPSEA_ANALYTICS.RISK_PANEL_DESC')"
        />
        <ul class="m-0 space-y-2 p-0">
          <li
            v-for="item in riskAlerts"
            :key="item.label"
            class="list-none rounded-lg border p-2 text-sm"
            :class="
              item.level === 'critical'
                ? 'border-n-ruby-5 bg-n-ruby-3/20'
                : item.level === 'watch'
                  ? 'border-n-amber-5 bg-n-amber-3/20'
                  : 'border-n-emerald-5 bg-n-emerald-3/20'
            "
          >
            <p class="m-0 text-xs text-n-slate-11">{{ item.label }}</p>
            <p class="m-0 font-semibold text-n-slate-12">{{ item.value }}</p>
          </li>
        </ul>
      </section>

      <section class="rounded-xl border border-n-weak bg-n-solid-1 p-4">
        <SynSectionHeader
          :title="$t('REPORT.SYNAPSEA_ANALYTICS.TRENDS_PANEL_TITLE')"
          :description="$t('REPORT.SYNAPSEA_ANALYTICS.TRENDS_PANEL_DESC')"
        />
        <div class="space-y-2 text-sm">
          <p class="m-0 flex items-center justify-between">
            <span>{{ $t('REPORT.SYNAPSEA_ANALYTICS.TREND_TODAY') }}</span>
 codex/transform-chatwoot-into-synapsea-connect-6xbxtt
            <strong>{{
              trendPercentText(
                getDelta(conversationCount, previousSummary.conversations_count)
              )
            }}</strong>
          </p>
          <p class="m-0 flex items-center justify-between">
            <span>{{ $t('REPORT.SYNAPSEA_ANALYTICS.TREND_WEEK') }}</span>
            <strong>{{
              trendPercentText(
                getDelta(resolutionCount, previousSummary.resolutions_count)
              )
            }}</strong>
          </p>
          <p class="m-0 flex items-center justify-between">
            <span>{{ $t('REPORT.SYNAPSEA_ANALYTICS.TREND_MONTH') }}</span>
            <strong>{{
              trendPercentText(

            <strong
              >{{
                getDelta(
                  conversationCount,
                  previousSummary.conversations_count
                )
              }}{{ $t('REPORT.SYNAPSEA_ANALYTICS.PERCENT_SUFFIX') }}</strong
            >
          </p>
          <p class="m-0 flex items-center justify-between">
            <span>{{ $t('REPORT.SYNAPSEA_ANALYTICS.TREND_WEEK') }}</span>
            <strong
              >{{ getDelta(resolutionCount, previousSummary.resolutions_count)
              }}{{ $t('REPORT.SYNAPSEA_ANALYTICS.PERCENT_SUFFIX') }}</strong
            >
          </p>
          <p class="m-0 flex items-center justify-between">
            <span>{{ $t('REPORT.SYNAPSEA_ANALYTICS.TREND_MONTH') }}</span>
            <strong
              >{{
 develop
                getDelta(
                  estimatedRevenue,
                  (previousSummary.resolutions_count || 0) * 120
                )
 codex/transform-chatwoot-into-synapsea-connect-6xbxtt
              )
            }}</strong>
          </p>
          <p class="m-0 flex items-center justify-between">
            <span>{{ $t('REPORT.SYNAPSEA_ANALYTICS.TREND_SLA') }}</span>
            <strong>{{
              trendPercentText(getDelta(slaHealthyRate, 80))
            }}</strong>
          </p>
          <p class="m-0 flex items-center justify-between">
            <span>{{ $t('REPORT.SYNAPSEA_ANALYTICS.TREND_AI') }}</span>
            <strong>{{
              trendPercentText(getDelta(aiEfficiencyRate, 20))
            }}</strong>

              }}{{ $t('REPORT.SYNAPSEA_ANALYTICS.PERCENT_SUFFIX') }}</strong
            >
          </p>
          <p class="m-0 flex items-center justify-between">
            <span>{{ $t('REPORT.SYNAPSEA_ANALYTICS.TREND_SLA') }}</span>
            <strong
              >{{ getDelta(slaHealthyRate, 80)
              }}{{ $t('REPORT.SYNAPSEA_ANALYTICS.PERCENT_SUFFIX') }}</strong
            >
          </p>
          <p class="m-0 flex items-center justify-between">
            <span>{{ $t('REPORT.SYNAPSEA_ANALYTICS.TREND_AI') }}</span>
            <strong
              >{{ getDelta(aiEfficiencyRate, 20)
              }}{{ $t('REPORT.SYNAPSEA_ANALYTICS.PERCENT_SUFFIX') }}</strong
            >
 develop
          </p>
        </div>
      </section>
    </div>

    <section class="mt-4 rounded-xl border border-n-weak bg-n-solid-1 p-4">
      <SynSectionHeader
        :title="$t('REPORT.SYNAPSEA_ANALYTICS.EXECUTIVE_SUMMARY_TITLE')"
        :description="$t('REPORT.SYNAPSEA_ANALYTICS.EXECUTIVE_SUMMARY_DESC')"
      />
      <p class="m-0 text-sm leading-6 text-n-slate-12">
        {{ executiveSummary }}
      </p>
      <div class="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-2">
        <article class="rounded-lg bg-n-slate-2 p-2">
          <p class="m-0 text-xs text-n-slate-11">
            {{ $t('REPORT.SYNAPSEA_ANALYTICS.TOP_PERFORMERS') }}
          </p>
          <ul class="m-0 mt-1 space-y-1 p-0">
            <li
              v-for="agent in topAgents"
              :key="agent.label"
              class="list-none text-xs text-n-slate-12"
            >
              {{
                $t('REPORT.SYNAPSEA_ANALYTICS.TOP_PERFORMER_ITEM', {
                  label: agent.label,
                  value: agent.value,
                })
              }}
            </li>
          </ul>
        </article>
        <article class="rounded-lg bg-n-slate-2 p-2">
          <p class="m-0 text-xs text-n-slate-11">
            {{ $t('REPORT.SYNAPSEA_ANALYTICS.RECOMMENDED_ACTIONS') }}
          </p>
          <ul class="m-0 mt-1 space-y-1 p-0 text-xs text-n-slate-12">
            <li class="list-none">
              {{ $t('REPORT.SYNAPSEA_ANALYTICS.ACTION_1') }}
            </li>
            <li class="list-none">
              {{ $t('REPORT.SYNAPSEA_ANALYTICS.ACTION_2') }}
            </li>
            <li class="list-none">
              {{ $t('REPORT.SYNAPSEA_ANALYTICS.ACTION_3') }}
            </li>
          </ul>
        </article>
      </div>
    </section>
 codex/transform-chatwoot-into-synapsea-connect-6xbxtt


  <section class="mt-4 rounded-xl border border-n-weak bg-n-solid-2 p-4">
    <header class="mb-3">
      <h3 class="m-0 text-sm font-medium text-n-slate-12">
        {{ $t('REPORT.SYNAPSEA_ANALYTICS.TITLE') }}
      </h3>
      <p class="m-0 text-xs text-n-slate-11">
        {{ $t('REPORT.SYNAPSEA_ANALYTICS.DESCRIPTION') }}
      </p>
    </header>
    <div class="grid grid-cols-1 gap-2 md:grid-cols-2 xl:grid-cols-4">
      <article class="rounded-lg bg-n-alpha-2 p-3">
        <p class="m-0 text-xs text-n-slate-11">
          {{ $t('REPORT.SYNAPSEA_ANALYTICS.AVG_RESPONSE_TIME') }}
        </p>
        <p class="m-0 text-base font-medium text-n-slate-12">
          {{ avgResponseTime }}
        </p>
      </article>
      <article class="rounded-lg bg-n-alpha-2 p-3">
        <p class="m-0 text-xs text-n-slate-11">
          {{ $t('REPORT.SYNAPSEA_ANALYTICS.LEAD_CONVERSIONS') }}
        </p>
        <p class="m-0 text-base font-medium text-n-slate-12">
          {{ leadConversions }}
        </p>
      </article>
      <article class="rounded-lg bg-n-alpha-2 p-3">
        <p class="m-0 text-xs text-n-slate-11">
          {{ $t('REPORT.SYNAPSEA_ANALYTICS.AGENT_PERFORMANCE') }}
        </p>
        <p class="m-0 text-base font-medium text-n-slate-12">
          {{ topAgentPerformance }}
        </p>
      </article>
      <article class="rounded-lg bg-n-alpha-2 p-3">
        <p class="m-0 text-xs text-n-slate-11">
          {{ $t('REPORT.SYNAPSEA_ANALYTICS.CONTACT_ORIGIN') }}
        </p>
        <p class="m-0 text-base font-medium capitalize text-n-slate-12">
          {{ topContactOrigin }}
        </p>
      </article>
    </div>
 develop
 develop
  </section>
</template>
