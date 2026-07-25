<script setup>
import { computed, onUnmounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { usePolicy } from 'dashboard/composables/usePolicy';
import CaptainAssistant from 'dashboard/api/captain/assistant';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import RangeSelector from 'dashboard/components-next/captain/pageComponents/overview/RangeSelector.vue';
import WelcomeCard from 'dashboard/components-next/captain/pageComponents/overview/WelcomeCard.vue';
import MetricCard from 'dashboard/components-next/captain/pageComponents/overview/MetricCard.vue';
import AssistantDrilldownDrawer from 'dashboard/components-next/captain/pageComponents/overview/AssistantDrilldownDrawer.vue';
import KnowledgeCard from 'dashboard/components-next/captain/pageComponents/overview/KnowledgeCard.vue';
import QuickLinks from 'dashboard/components-next/captain/pageComponents/overview/QuickLinks.vue';
import InboxBanner from 'dashboard/components-next/captain/pageComponents/overview/InboxBanner.vue';
import CoverageBanner from 'dashboard/components-next/captain/pageComponents/overview/CoverageBanner.vue';

const { t } = useI18n();
const route = useRoute();
// Drilldown is admin-only; the backend policy enforces the same restriction.
const { checkPermissions } = usePolicy();
const canDrilldown = computed(() => checkPermissions(['administrator']));

const selectedRange = ref('this_month');

const assistantId = computed(() => route.params.assistantId);
const metricStats = ref(null);
const faqStats = ref(null);
const isFetchingMetrics = ref(false);

// Increments on every fetch so a response (or retry) from a superseded
// range/assistant can't clobber the latest request's state.
let metricsFetchToken = 0;
let faqStatsFetchToken = 0;
let metricsAbortController = null;
let faqStatsAbortController = null;

const fetchMetrics = async () => {
  metricsFetchToken += 1;
  const token = metricsFetchToken;
  metricsAbortController?.abort();
  metricsAbortController = new AbortController();
  const { signal } = metricsAbortController;
  metricStats.value = null;
  isFetchingMetrics.value = true;

  const requestMetrics = () =>
    CaptainAssistant.getMetrics({
      assistantId: assistantId.value,
      range: selectedRange.value,
      signal,
    });

  let data = null;
  try {
    ({ data } = await requestMetrics());
  } catch {
    // One silent retry before giving up, unless the request was aborted.
    try {
      if (token === metricsFetchToken && !signal.aborted)
        ({ data } = await requestMetrics());
    } catch {
      data = null;
    }
  }

  if (token !== metricsFetchToken || signal.aborted) return;
  metricStats.value = data;
  isFetchingMetrics.value = false;
};

const fetchFaqStats = async () => {
  faqStatsFetchToken += 1;
  const token = faqStatsFetchToken;
  faqStatsAbortController?.abort();
  faqStatsAbortController = new AbortController();
  const { signal } = faqStatsAbortController;
  faqStats.value = null;

  try {
    const { data } = await CaptainAssistant.getFaqStats({
      assistantId: assistantId.value,
      signal,
    });
    if (token === faqStatsFetchToken && !signal.aborted) faqStats.value = data;
  } catch {
    if (token === faqStatsFetchToken && !signal.aborted) faqStats.value = null;
  }
};

const summaryStats = computed(() => {
  if (!metricStats.value || !faqStats.value) return null;

  return { ...metricStats.value, knowledge: faqStats.value };
});

onUnmounted(() => {
  metricsAbortController?.abort();
  faqStatsAbortController?.abort();
});

watch([selectedRange, assistantId], fetchMetrics, { immediate: true });
watch(assistantId, fetchFaqStats, { immediate: true });

// `direction` says whether a rising trend is good ('up'), bad ('down'), or
// neutral, so we can colour the delta independently of its sign.
const resolveTrendGood = (trendValue, direction) => {
  if (direction === 'neutral' || trendValue === 0) return null;
  return direction === 'up' ? trendValue > 0 : trendValue < 0;
};

// Trend units mirror the backend pack mode: a relative percent change ('%') for
// :percent metrics, a percentage-point delta (' pts') for rate metrics packed as
// :point, and a plain number for :absolute counts like conversation depth.
const TREND_SUFFIX = { percent: '%', point: ' pts', absolute: '' };

// Hours-saved is reported in hours, but large values read better as days. Past
// 100h we switch the unit so the card stays legible.
const formatDuration = hours =>
  hours >= 100 ? `${Math.round(hours / 24)}d` : `${hours}h`;

const metricFor = (statKey, formatValue, direction, trendKind = 'percent') => {
  const data = metricStats.value?.[statKey];
  if (!data) return { value: '—', trend: '', trendGood: null };

  const sign = data.trend > 0 ? '+' : '';
  return {
    value: formatValue(data.current),
    trend: `${sign}${data.trend}${TREND_SUFFIX[trendKind]}`,
    trendGood: resolveTrendGood(data.trend, direction),
  };
};

const metrics = computed(() => [
  {
    key: 'handled',
    metric: 'conversations_handled',
    label: t('CAPTAIN.OVERVIEW.METRICS.HANDLED.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.HANDLED.HINT'),
    ...metricFor('conversations_handled', v => v.toLocaleString(), 'up'),
  },
  {
    key: 'autoResolution',
    metric: 'auto_resolution_rate',
    label: t('CAPTAIN.OVERVIEW.METRICS.AUTO_RESOLUTION.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.AUTO_RESOLUTION.HINT'),
    ...metricFor('auto_resolution_rate', v => `${v}%`, 'up', 'point'),
  },
  {
    key: 'handoff',
    metric: 'handoff_rate',
    label: t('CAPTAIN.OVERVIEW.METRICS.HANDOFF.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.HANDOFF.HINT'),
    ...metricFor('handoff_rate', v => `${v}%`, 'down', 'point'),
  },
  {
    key: 'reopen',
    metric: 'reopen_rate',
    label: t('CAPTAIN.OVERVIEW.METRICS.REOPEN.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.REOPEN.HINT'),
    ...metricFor('reopen_rate', v => `${v}%`, 'down', 'point'),
  },
  {
    key: 'hoursSaved',
    label: t('CAPTAIN.OVERVIEW.METRICS.HOURS_SAVED.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.HOURS_SAVED.HINT'),
    ...metricFor('hours_saved', formatDuration, 'up'),
  },
  {
    key: 'depth',
    label: t('CAPTAIN.OVERVIEW.METRICS.DEPTH.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.DEPTH.HINT'),
    ...metricFor(
      'conversation_depth',
      v => v.toFixed(1),
      'neutral',
      'absolute'
    ),
  },
]);

const drilldown = ref({ metric: '', label: '', value: '' });
const isDrilldownOpen = ref(false);

const openDrilldown = metric => {
  drilldown.value = {
    metric: metric.metric,
    label: metric.label,
    value: metric.value,
  };
  isDrilldownOpen.value = true;
};

const closeDrilldown = () => {
  isDrilldownOpen.value = false;
};
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.OVERVIEW.HEADER')"
    :is-empty="false"
    :show-pagination-footer="false"
    :show-know-more="false"
    :feature-flag="FEATURE_FLAGS.CAPTAIN"
  >
    <template #headerActions>
      <RangeSelector v-model="selectedRange" />
    </template>
    <template #paywall>
      <CaptainPaywall />
    </template>
    <template #body>
      <div class="flex flex-col gap-6 pb-8">
        <InboxBanner />

        <CoverageBanner :knowledge="faqStats ?? undefined" />

        <WelcomeCard :range="selectedRange" :stats="summaryStats" />

        <div
          class="grid grid-cols-1 gap-px overflow-hidden border rounded-xl sm:grid-cols-2 lg:grid-cols-3 bg-n-weak border-n-weak"
        >
          <MetricCard
            v-for="metric in metrics"
            :key="metric.key"
            :label="metric.label"
            :value="metric.value"
            :trend="metric.trend"
            :hint="metric.hint"
            :trend-good="metric.trendGood"
            :loading="isFetchingMetrics"
            :clickable="
              canDrilldown && Boolean(metric.metric) && !isFetchingMetrics
            "
            @click="openDrilldown(metric)"
          />
        </div>

        <KnowledgeCard :knowledge="faqStats ?? undefined" />

        <QuickLinks />
      </div>

      <AssistantDrilldownDrawer
        v-if="canDrilldown"
        :open="isDrilldownOpen"
        :assistant-id="assistantId"
        :metric="drilldown.metric"
        :metric-name="drilldown.label"
        :metric-value="drilldown.value"
        :range="selectedRange"
        @close="closeDrilldown"
      />
    </template>
  </PageLayout>
</template>
