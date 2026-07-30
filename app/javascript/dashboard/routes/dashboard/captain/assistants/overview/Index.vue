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
import ResolutionCard from 'dashboard/components-next/captain/pageComponents/overview/ResolutionCard.vue';
import HandoffReasonsCard from 'dashboard/components-next/captain/pageComponents/overview/HandoffReasonsCard.vue';
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

const selectedRange = ref('7');

const assistantId = computed(() => route.params.assistantId);
const metricStats = ref(null);
const outcomeStats = ref(null);
const faqStats = ref(null);
const isFetchingMetrics = ref(false);
const isFetchingOutcomes = ref(false);

// Increments on every fetch so a response (or retry) from a superseded
// range/assistant can't clobber the latest request's state.
let metricsFetchToken = 0;
let outcomesFetchToken = 0;
let faqStatsFetchToken = 0;
let metricsAbortController = null;
let outcomesAbortController = null;
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

const fetchOutcomeMetrics = async () => {
  outcomesFetchToken += 1;
  const token = outcomesFetchToken;
  outcomesAbortController?.abort();
  outcomesAbortController = new AbortController();
  const { signal } = outcomesAbortController;
  outcomeStats.value = null;
  isFetchingOutcomes.value = true;

  const requestOutcomes = () =>
    CaptainAssistant.getOutcomeMetrics({
      assistantId: assistantId.value,
      range: selectedRange.value,
      signal,
    });

  let data = null;
  try {
    ({ data } = await requestOutcomes());
  } catch {
    // One silent retry before giving up, unless the request was aborted.
    try {
      if (token === outcomesFetchToken && !signal.aborted)
        ({ data } = await requestOutcomes());
    } catch {
      data = null;
    }
  }

  if (token !== outcomesFetchToken || signal.aborted) return;
  outcomeStats.value = data;
  isFetchingOutcomes.value = false;
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

onUnmounted(() => {
  metricsAbortController?.abort();
  outcomesAbortController?.abort();
  faqStatsAbortController?.abort();
});

watch(
  [selectedRange, assistantId],
  () => {
    fetchMetrics();
    fetchOutcomeMetrics();
  },
  { immediate: true }
);
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

// Durations arrive as seconds; switch units so the card stays legible.
const formatSeconds = seconds => {
  if (seconds < 60) return `${Math.round(seconds)}s`;
  if (seconds < 3600) return `${Math.round(seconds / 60)}m`;
  return `${(seconds / 3600).toFixed(1)}h`;
};

const metricFor = (source, statKey, formatValue, direction, trendKind) => {
  const data = source?.[statKey];
  if (!data) return { value: '—', trend: '', trendGood: null };

  const sign = data.trend > 0 ? '+' : '';
  return {
    value: formatValue(data.current),
    trend: `${sign}${data.trend}${TREND_SUFFIX[trendKind]}`,
    trendGood: resolveTrendGood(data.trend, direction),
  };
};

const overviewMetric = (
  statKey,
  formatValue,
  direction,
  trendKind = 'percent'
) => ({
  loading: isFetchingMetrics.value,
  ...metricFor(metricStats.value, statKey, formatValue, direction, trendKind),
});

const outcomeMetric = (
  statKey,
  formatValue,
  direction,
  trendKind = 'percent'
) => ({
  loading: isFetchingOutcomes.value,
  ...metricFor(outcomeStats.value, statKey, formatValue, direction, trendKind),
});

// Reach: how much of the account's support demand Captain touches.
const reachMetrics = computed(() => [
  {
    key: 'handled',
    metric: 'conversations_handled',
    label: t('CAPTAIN.OVERVIEW.METRICS.HANDLED.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.HANDLED.HINT'),
    ...overviewMetric('conversations_handled', v => v.toLocaleString(), 'up'),
  },
  {
    key: 'handoff',
    metric: 'handoff_rate',
    label: t('CAPTAIN.OVERVIEW.METRICS.HANDOFF.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.HANDOFF.HINT'),
    ...overviewMetric('handoff_rate', v => `${v}%`, 'down', 'point'),
  },
  {
    key: 'hoursSaved',
    label: t('CAPTAIN.OVERVIEW.METRICS.HOURS_SAVED.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.HOURS_SAVED.HINT'),
    ...overviewMetric('hours_saved', formatDuration, 'up'),
  },
]);

// The autonomous count with the handled denominator as a muted suffix,
// e.g. "124 of 200": same numerator as the rate beside it, so a separate
// card would just repeat it.
const autonomousCount = computed(() => {
  const count = outcomeStats.value?.autonomous_resolutions?.current;
  const total = metricStats.value?.conversations_handled?.current;

  return {
    value: count ? count.toLocaleString() : '—',
    suffix:
      count && total
        ? t('CAPTAIN.OVERVIEW.METRICS.AUTO_RESOLUTION.DENOMINATOR', {
            total: total.toLocaleString(),
          })
        : '',
  };
});

// Resolution: one card — four headline stats over the flow diagram.
const resolutionStats = computed(() => [
  {
    key: 'autoResolution',
    metric: 'auto_resolution_rate',
    label: t('CAPTAIN.OVERVIEW.METRICS.AUTO_RESOLUTION.LABEL'),
    ...overviewMetric('auto_resolution_rate', v => `${v}%`, 'up', 'point'),
  },
  {
    key: 'autonomousCount',
    label: t('CAPTAIN.OVERVIEW.METRICS.AUTO_RESOLUTION.COUNT_LABEL'),
    value: autonomousCount.value.value,
    suffix: autonomousCount.value.suffix,
    trend: '',
    trendGood: null,
  },
  {
    key: 'durable',
    label: t('CAPTAIN.OVERVIEW.METRICS.DURABLE.LABEL'),
    ...outcomeMetric('durable_resolution_rate', v => `${v}%`, 'up', 'point'),
  },
  {
    key: 'reopen',
    metric: 'reopen_rate',
    label: t('CAPTAIN.OVERVIEW.METRICS.REOPEN.LABEL'),
    ...overviewMetric('reopen_rate', v => `${v}%`, 'down', 'point'),
  },
]);

const csatBaseline = computed(() => {
  const score = outcomeStats.value?.human_only_csat_score?.current;
  if (!score) return '';
  return t('CAPTAIN.OVERVIEW.METRICS.CSAT.BASELINE', { score });
});

// Experience: is the support Captain delivers fast and satisfying.
const experienceMetrics = computed(() => [
  {
    key: 'csat',
    label: t('CAPTAIN.OVERVIEW.METRICS.CSAT.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.CSAT.HINT'),
    secondary: csatBaseline.value,
    ...outcomeMetric(
      'csat_score',
      v => (v ? v.toFixed(1) : '—'),
      'up',
      'absolute'
    ),
  },
  {
    key: 'resolutionTime',
    label: t('CAPTAIN.OVERVIEW.METRICS.RESOLUTION_TIME.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.RESOLUTION_TIME.HINT'),
    ...outcomeMetric(
      'median_resolution_seconds',
      v => (v ? formatSeconds(v) : '—'),
      'down',
      'absolute'
    ),
  },
  {
    key: 'depth',
    label: t('CAPTAIN.OVERVIEW.METRICS.DEPTH.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.DEPTH.HINT'),
    ...overviewMetric(
      'conversation_depth',
      v => v.toFixed(1),
      'neutral',
      'absolute'
    ),
  },
]);

const cardSections = computed(() => [
  {
    key: 'reach',
    title: t('CAPTAIN.OVERVIEW.SECTIONS.REACH'),
    metrics: reachMetrics.value,
  },
  {
    key: 'experience',
    title: t('CAPTAIN.OVERVIEW.SECTIONS.EXPERIENCE'),
    metrics: experienceMetrics.value,
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

        <WelcomeCard :range="selectedRange" />

        <template v-for="section in cardSections" :key="section.key">
          <section class="flex flex-col">
            <h3
              class="self-start px-2 pt-1 pb-[3px] ml-4 text-[11px] leading-[11px] font-semibold tracking-wider uppercase rounded-t-md bg-n-slate-4 text-n-slate-11"
            >
              {{ section.title }}
            </h3>
            <div
              class="grid grid-cols-1 gap-px overflow-hidden border rounded-xl sm:grid-cols-2 lg:grid-cols-3 bg-n-weak border-n-weak"
            >
              <MetricCard
                v-for="metric in section.metrics"
                :key="metric.key"
                :label="metric.label"
                :value="metric.value"
                :trend="metric.trend"
                :hint="metric.hint"
                :secondary="metric.secondary"
                :trend-good="metric.trendGood"
                :loading="metric.loading"
                :clickable="
                  canDrilldown && Boolean(metric.metric) && !metric.loading
                "
                @click="openDrilldown(metric)"
              />
            </div>
          </section>

          <section v-if="section.key === 'reach'" class="flex flex-col">
            <h3
              class="self-start px-2 pt-1 pb-[3px] ml-4 text-[11px] leading-[11px] font-semibold tracking-wider uppercase rounded-t-md bg-n-slate-4 text-n-slate-11"
            >
              {{ $t('CAPTAIN.OVERVIEW.SECTIONS.RESOLUTION') }}
            </h3>
            <ResolutionCard
              :stats="resolutionStats"
              :flow="outcomeStats?.flow ?? null"
              :loading="isFetchingMetrics || isFetchingOutcomes"
              :clickable="canDrilldown"
              @drilldown="openDrilldown"
            />
          </section>
        </template>

        <div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
          <KnowledgeCard :knowledge="faqStats ?? undefined" />
          <HandoffReasonsCard
            :reasons="outcomeStats?.handoff_reasons"
            :loading="isFetchingOutcomes"
          />
        </div>

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
