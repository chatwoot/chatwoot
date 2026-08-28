<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useMapGetter } from 'dashboard/composables/store';
import { useCaptain } from 'dashboard/composables/useCaptain';
import {
  isAbortError,
  useAbortableRequest,
} from 'dashboard/composables/useAbortableRequest';
import CaptainAssistant from 'dashboard/api/captain/assistant';
import CaptainAssistantStats from 'dashboard/api/captain/assistantStats';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import RangeSelector from 'dashboard/components-next/captain/pageComponents/overview/RangeSelector.vue';
import InboxBanner from 'dashboard/components-next/captain/pageComponents/overview/InboxBanner.vue';
import CoverageBanner from 'dashboard/components-next/captain/pageComponents/overview/CoverageBanner.vue';
import QuickLinks from 'dashboard/components-next/captain/pageComponents/overview/QuickLinks.vue';
import OverviewSummaryCard from './OverviewSummaryCard.vue';
import ResolutionFlowCard from './ResolutionFlowCard.vue';
import ResolutionTrendCard from './ResolutionTrendCard.vue';
import CsatCard from './CsatCard.vue';
import UsageCard from './UsageCard.vue';
import KnowledgeCoverageCard from './KnowledgeCoverageCard.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const currentUser = useMapGetter('getCurrentUser');
const { responseLimits, documentLimits, isFetchingLimits, fetchLimits } =
  useCaptain();

const selectedRange = ref('this_month');
const overview = ref(null);
const summaryPoints = ref([]);
const resolutionFlow = ref(null);
const resolutionTrend = ref(null);
const faqStats = ref(null);

const TREND_DIRECTIONS = {
  UP: 'up',
  DOWN: 'down',
  NEUTRAL: 'neutral',
};
const HOURS_PER_DAY = 24;
const SECONDS_PER_MINUTE = 60;
const SECONDS_PER_HOUR = 60 * SECONDS_PER_MINUTE;
const DURATION_DAY_THRESHOLD_HOURS = 100;

const assistantId = computed(() => route.params.assistantId);
const userName = computed(
  () =>
    currentUser.value?.name?.split(' ')[0] ||
    t('CAPTAIN.OVERVIEW.V2.SUMMARY.DEFAULT_NAME')
);

const { run: runReportRequest, isPending: isFetchingReport } =
  useAbortableRequest();
const { run: runSummaryRequest, isPending: isFetchingSummary } =
  useAbortableRequest();
const { run: runKnowledgeRequest, isPending: isFetchingKnowledge } =
  useAbortableRequest();

const optionalResponseData = async request => {
  try {
    return (await request).data;
  } catch (error) {
    if (isAbortError(error)) throw error;
    return null;
  }
};

const fetchReport = async () => {
  const results = await runReportRequest(signal => {
    const request = {
      assistantId: assistantId.value,
      range: selectedRange.value,
      signal,
    };

    return Promise.all([
      optionalResponseData(CaptainAssistantStats.getOverview(request)),
      optionalResponseData(CaptainAssistantStats.getResolutionFlow(request)),
      optionalResponseData(CaptainAssistantStats.getResolutionTrend(request)),
    ]);
  });

  if (results) {
    [overview.value, resolutionFlow.value, resolutionTrend.value] = results;
  }
};

const fetchSummary = async () => {
  summaryPoints.value = [];

  try {
    const response = await runSummaryRequest(signal =>
      CaptainAssistantStats.getOverviewSummary({
        assistantId: assistantId.value,
        range: selectedRange.value,
        signal,
      })
    );
    if (response) summaryPoints.value = response.data.points || [];
  } catch {
    summaryPoints.value = [];
  }
};

const fetchKnowledge = async () => {
  faqStats.value = null;

  try {
    const response = await runKnowledgeRequest(signal =>
      CaptainAssistant.getFaqStats({
        assistantId: assistantId.value,
        signal,
      })
    );
    if (response) faqStats.value = response.data;
  } catch {
    faqStats.value = null;
  }
};

watch(
  [selectedRange, assistantId],
  () => {
    fetchReport();
    fetchSummary();
  },
  { immediate: true }
);
watch(assistantId, fetchKnowledge, { immediate: true });

onMounted(fetchLimits);

const trendGood = (trend, direction) => {
  if (!trend || direction === TREND_DIRECTIONS.NEUTRAL) return null;
  return direction === TREND_DIRECTIONS.UP ? trend > 0 : trend < 0;
};

const signed = value => `${value > 0 ? '+' : ''}${value}`;
const formatDuration = hours =>
  hours >= DURATION_DAY_THRESHOLD_HOURS
    ? t('CAPTAIN.OVERVIEW.V2.UNITS.DAYS', {
        value: Math.round(hours / HOURS_PER_DAY),
      })
    : t('CAPTAIN.OVERVIEW.V2.UNITS.HOURS', { value: hours });

const formatResolutionTime = seconds => {
  if (seconds >= SECONDS_PER_HOUR) {
    return t('CAPTAIN.OVERVIEW.V2.UNITS.HOURS', {
      value: (seconds / SECONDS_PER_HOUR).toFixed(1),
    });
  }
  return t('CAPTAIN.OVERVIEW.V2.UNITS.MINUTES', {
    value: Math.round(seconds / SECONDS_PER_MINUTE),
  });
};

const formatResolutionTrend = seconds => {
  const absolute = Math.abs(seconds);
  const formatted = formatResolutionTime(absolute);
  let sign = '';
  if (seconds > 0) sign = '+';
  if (seconds < 0) sign = '-';
  return `${sign}${formatted}`;
};

const formatDurationTrend = hours => {
  let sign = '';
  if (hours > 0) sign = '+';
  if (hours < 0) sign = '-';
  return `${sign}${formatDuration(Math.abs(hours))}`;
};

const metricFor = ({
  key,
  label,
  hint,
  hintNote = '',
  formatValue,
  direction,
  trendSuffix = '',
  formatTrend,
  supportingValue = '',
  supportingText = '',
  valueClass = 'text-n-slate-12',
}) => {
  const data = overview.value?.[key];
  if (!data) {
    return {
      key,
      label,
      hint,
      hintNote,
      value: '—',
      trend: '',
      trendGood: null,
      trendUp: null,
      supportingValue: '',
      supportingText: '',
      valueClass,
    };
  }

  return {
    key,
    label,
    hint,
    hintNote,
    value: formatValue(data.current),
    trend: formatTrend
      ? formatTrend(data.trend)
      : `${signed(data.trend)}${trendSuffix}`,
    trendGood: trendGood(data.trend, direction),
    trendUp: data.trend === 0 ? null : data.trend > 0,
    supportingValue,
    supportingText,
    valueClass,
  };
};

const handledCount = computed(
  () => overview.value?.conversations_handled?.current || 0
);

const featuredMetrics = computed(() => [
  metricFor({
    key: 'hours_saved',
    label: t('CAPTAIN.OVERVIEW.V2.METRICS.TIME_SAVED.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.HOURS_SAVED.HINT'),
    hintNote: t('CAPTAIN.OVERVIEW.METRICS.HOURS_SAVED.NOTE'),
    formatValue: formatDuration,
    formatTrend: formatDurationTrend,
    direction: TREND_DIRECTIONS.UP,
    valueClass: 'text-n-iris-11',
  }),
  metricFor({
    key: 'durable_resolution_rate',
    label: t('CAPTAIN.OVERVIEW.V2.METRICS.DURABLE.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.V2.METRICS.DURABLE.HINT'),
    hintNote: t('CAPTAIN.OVERVIEW.V2.METRICS.DURABLE.NOTE'),
    formatValue: value => `${value}%`,
    direction: TREND_DIRECTIONS.UP,
    trendSuffix: '%',
    valueClass: 'text-n-iris-11',
  }),
]);

const metrics = computed(() => [
  metricFor({
    key: 'conversations_handled',
    label: t('CAPTAIN.OVERVIEW.METRICS.HANDLED.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.HANDLED.HINT'),
    formatValue: value => value.toLocaleString(),
    direction: TREND_DIRECTIONS.UP,
    trendSuffix: '%',
  }),
  metricFor({
    key: 'auto_resolution_rate',
    label: t('CAPTAIN.OVERVIEW.METRICS.AUTO_RESOLUTION.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.AUTO_RESOLUTION.HINT'),
    formatValue: value => `${value}%`,
    direction: TREND_DIRECTIONS.UP,
    trendSuffix: '%',
    supportingValue: Number(
      overview.value?.autonomous_resolutions?.current || 0
    ).toLocaleString(),
    supportingText: t('CAPTAIN.OVERVIEW.V2.METRICS.OF_TOTAL', {
      total: handledCount.value,
    }),
  }),
  metricFor({
    key: 'handoff_rate',
    label: t('CAPTAIN.OVERVIEW.METRICS.HANDOFF.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.HANDOFF.HINT'),
    formatValue: value => `${value}%`,
    direction: TREND_DIRECTIONS.DOWN,
    trendSuffix: '%',
    supportingValue: Number(
      overview.value?.handoff_count?.current || 0
    ).toLocaleString(),
    supportingText: t('CAPTAIN.OVERVIEW.V2.METRICS.OF_TOTAL', {
      total: handledCount.value,
    }),
  }),
  metricFor({
    key: 'conversation_depth',
    label: t('CAPTAIN.OVERVIEW.V2.METRICS.DEPTH.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.DEPTH.HINT'),
    hintNote: t('CAPTAIN.OVERVIEW.METRICS.DEPTH.NOTE'),
    formatValue: value => value.toFixed(1),
    direction: TREND_DIRECTIONS.NEUTRAL,
  }),
  metricFor({
    key: 'reopen_rate',
    label: t('CAPTAIN.OVERVIEW.METRICS.REOPEN.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.METRICS.REOPEN.HINT'),
    hintNote: t('CAPTAIN.OVERVIEW.METRICS.REOPEN.NOTE'),
    formatValue: value => `${value}%`,
    direction: TREND_DIRECTIONS.DOWN,
    trendSuffix: '%',
  }),
  metricFor({
    key: 'median_resolution_seconds',
    label: t('CAPTAIN.OVERVIEW.V2.METRICS.MEDIAN_RESOLUTION.LABEL'),
    hint: t('CAPTAIN.OVERVIEW.V2.METRICS.MEDIAN_RESOLUTION.HINT'),
    hintNote: t('CAPTAIN.OVERVIEW.V2.METRICS.MEDIAN_RESOLUTION.NOTE'),
    formatValue: formatResolutionTime,
    formatTrend: formatResolutionTrend,
    direction: TREND_DIRECTIONS.DOWN,
  }),
]);

const openBilling = () =>
  router.push({
    name: 'billing_settings_index',
    params: { accountId: route.params.accountId },
  });

const reviewFaqs = () =>
  router.push({
    name: 'captain_assistants_faq_suggestions',
    params: {
      accountId: route.params.accountId,
      assistantId: assistantId.value,
    },
  });
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
      <div class="flex flex-col gap-5 pb-8">
        <InboxBanner />
        <CoverageBanner :knowledge="faqStats ?? undefined" />

        <OverviewSummaryCard
          :user-name="userName"
          :points="summaryPoints"
          :featured-metrics="featuredMetrics"
          :metrics="metrics"
          :loading="isFetchingReport"
          :summary-loading="isFetchingSummary"
        />

        <ResolutionFlowCard
          :flow="resolutionFlow"
          :loading="isFetchingReport"
        />

        <div class="grid gap-5 lg:grid-cols-[minmax(0,2fr)_minmax(18rem,1fr)]">
          <ResolutionTrendCard
            :trend="resolutionTrend"
            :loading="isFetchingReport"
          />
          <CsatCard
            :autonomous="overview?.autonomous_csat_score"
            :assisted="overview?.assisted_csat_score"
            :human-only="overview?.human_only_csat_score"
            :loading="isFetchingReport"
          />
        </div>

        <div class="grid gap-5 lg:grid-cols-[minmax(0,2fr)_minmax(18rem,1fr)]">
          <UsageCard
            :response-limits="responseLimits"
            :document-limits="documentLimits"
            :loading="isFetchingLimits"
            @refresh="fetchLimits"
            @buy="openBilling"
          />
          <KnowledgeCoverageCard
            :knowledge="faqStats"
            :loading="isFetchingKnowledge"
            @review="reviewFaqs"
          />
        </div>

        <QuickLinks />
      </div>
    </template>
  </PageLayout>
</template>
