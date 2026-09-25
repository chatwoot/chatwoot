<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { useLocale } from 'shared/composables/useLocale';
import MonitorsAPI from 'dashboard/api/monitors';
import BarChart from 'shared/components/charts/BarChart.vue';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ReportHeader from '../components/ReportHeader.vue';
import MonitorChartFilters from './MonitorChartFilters.vue';
import MonitorDrilldown from './MonitorDrilldown.vue';
import MonitorActionDialog from './MonitorActionDialog.vue';
import MonitorUsageWarning from './MonitorUsageWarning.vue';
import { useMonitorRefresh } from './useMonitorRefresh';

const DAY_IN_SECONDS = 86400;
const CHART_TICK_COUNT = 5;

const { t, te } = useI18n();
const route = useRoute();
const router = useRouter();
const { accountId, currentAccount, accountScopedRoute } = useAccount();
const { isAdmin } = useAdmin();
const { resolvedLocale } = useLocale();
const { run, abort, isPending } = useAbortableRequest();
const {
  run: runRetry,
  abort: abortRetry,
  isPending: isRetrying,
} = useAbortableRequest();

const monitorId = computed(() => route.params.monitorId);
const filters = ref({ range: 7, interval: 'day' });
const collectionEndsAt = ref(null);
const result = ref(null);
const displayedParams = ref(null);
const drilldown = ref(null);
const actionDialog = ref(null);
const error = ref('');
const notice = ref('');
const refreshedAt = ref('');

const monitor = computed(() => result.value?.monitor);
const timezone = computed(
  () =>
    currentAccount.value?.reporting_timezone ||
    currentAccount.value?.custom_attributes?.timezone ||
    Intl.DateTimeFormat().resolvedOptions().timeZone
);

const formatTimestamp = (timestamp, options) =>
  new Intl.DateTimeFormat(resolvedLocale.value, {
    timeZone: timezone.value,
    ...options,
  }).format(new Date(timestamp * 1000));
// A paused monitor stops collecting, so the range ends at the pause instead of now.
const requestParams = ({ range, interval }) => {
  const until = collectionEndsAt.value || Math.floor(Date.now() / 1000);
  return {
    since: until - range * DAY_IN_SECONDS,
    until,
    interval,
    timezone: timezone.value,
  };
};

const pausedAtLabel = computed(() =>
  formatTimestamp(monitor.value.paused_at, {
    dateStyle: 'medium',
    timeStyle: 'short',
  })
);
const counts = computed(
  () => result.value?.buckets.map(bucket => bucket.count) || []
);
const countStep = computed(() =>
  Math.max(1, Math.ceil(Math.max(0, ...counts.value) / CHART_TICK_COUNT))
);
const bucketLabel = bucket =>
  formatTimestamp(bucket.start, {
    month: 'short',
    day: 'numeric',
    ...(result.value.interval !== 'day'
      ? { hour: 'numeric', minute: '2-digit', timeZoneName: 'short' }
      : {}),
  });
const chartData = computed(() => ({
  categories: result.value?.buckets.map(bucketLabel) || [],
  series: [
    {
      id: 'matches',
      label: t('MONITORS.MATCHING_CONVERSATIONS'),
      color: 'rgb(var(--blue-9))',
      data: counts.value,
    },
  ],
}));

const errorText = code => {
  const key = code && `MONITORS.ERRORS.${code.toUpperCase()}`;
  return t(
    key && (te(key) || te(key, 'en')) ? key : 'MONITORS.ERRORS.FETCH_FAILED'
  );
};
const statusText = computed(() => {
  if (monitor.value.paused_at) {
    return t('MONITORS.PAUSED_HELP', { time: pausedAtLabel.value });
  }
  const { state } = monitor.value.processing;
  return state === 'live' ? '' : t(`MONITORS.STATES.${state.toUpperCase()}`);
});
const canRetry = computed(
  () =>
    isAdmin.value &&
    monitor.value.processing.errors &&
    !monitor.value.paused_at &&
    !result.value.usage?.limit_reached
);

const fetchReport = async () => {
  const params = requestParams(filters.value);
  const requestedAccount = accountId.value;
  const requestedMonitor = monitorId.value;
  try {
    const response = await run(signal =>
      MonitorsAPI.timeseries(requestedMonitor, params, signal)
    );
    if (
      !response ||
      requestedAccount !== accountId.value ||
      requestedMonitor !== monitorId.value
    )
      return;
    const { data } = response;
    const pausedAt = data.monitor.paused_at || null;
    if (pausedAt !== collectionEndsAt.value) {
      collectionEndsAt.value = pausedAt;
      await fetchReport();
      return;
    }
    if (drilldown.value) {
      const { bucket, request } = drilldown.value;
      const updated = data.buckets.find(item => item.start === bucket.start);
      if (
        data.data_revision !== request.data_revision ||
        updated?.count !== bucket.count
      ) {
        drilldown.value = null;
        notice.value = t('MONITORS.RESULTS_UPDATED');
      }
    }
    result.value = data;
    displayedParams.value = params;
    refreshedAt.value = formatTimestamp(Date.now() / 1000, {
      timeStyle: 'medium',
    });
    error.value = '';
  } catch (failure) {
    error.value = errorText(failure.response?.data?.error);
  }
};

const openBucket = ({ pointIndex }) => {
  if (!isAdmin.value) return;
  const bucket = result.value.buckets[pointIndex];
  if (!bucket?.count) return;
  drilldown.value = {
    bucket,
    request: {
      ...displayedParams.value,
      monitorId: monitorId.value,
      bucket_start: bucket.start,
      data_revision: result.value.data_revision,
    },
  };
};
const resultsChanged = () => {
  drilldown.value = null;
  notice.value = t('MONITORS.RESULTS_UPDATED');
  fetchReport();
};

watch(filters, fetchReport);
watch(
  [accountId, monitorId, timezone],
  () => {
    abort();
    abortRetry();
    actionDialog.value?.close();
    result.value = null;
    displayedParams.value = null;
    collectionEndsAt.value = null;
    drilldown.value = null;
    notice.value = '';
    error.value = '';
    fetchReport();
  },
  { immediate: true }
);
watch(isAdmin, () => {
  drilldown.value = null;
});
useMonitorRefresh(fetchReport, {
  monitorId: () => Number(monitorId.value),
  onDeleted: () => {
    abort();
    result.value = null;
    drilldown.value = null;
    router.replace(accountScopedRoute('monitor_reports_index'));
  },
});

const openAction = nextAction =>
  actionDialog.value.open(nextAction, {
    ...monitor.value,
    id: monitorId.value,
  });
const onActionSaved = action => {
  if (action === 'delete') {
    router.push(accountScopedRoute('monitor_reports_index'));
    return;
  }
  notice.value = '';
  fetchReport();
};
const onMonitorChanged = message => {
  notice.value = message;
  fetchReport();
};
const retry = async () => {
  if (isRetrying.value) return;
  notice.value = '';
  try {
    await runRetry(async signal => {
      await MonitorsAPI.retry(monitorId.value, signal);
      if (signal.aborted) return;
      fetchReport();
    });
  } catch (failure) {
    error.value = errorText(failure.response?.data?.error);
  }
};
const duplicate = () =>
  router.push(
    accountScopedRoute(
      'monitor_reports_index',
      {},
      { condition: monitor.value.condition }
    )
  );
</script>

<template>
  <ReportHeader
    :header-title="monitor?.name || t('MONITORS.TITLE')"
    :header-description="monitor?.condition || ''"
    has-back-button
  >
    <div v-if="monitor && isAdmin" class="flex flex-wrap justify-end gap-2">
      <Button
        v-tooltip.bottom="t('MONITORS.EDIT')"
        slate
        faded
        size="sm"
        icon="i-woot-edit-pen"
        :aria-label="t('MONITORS.EDIT')"
        @click="openAction('edit')"
      />
      <Button
        v-tooltip.bottom="t('MONITORS.DUPLICATE')"
        slate
        faded
        size="sm"
        icon="i-woot-clone"
        :aria-label="t('MONITORS.DUPLICATE')"
        @click="duplicate"
      />
      <Button
        v-if="!monitor.paused_at"
        v-tooltip.bottom="t('MONITORS.PAUSE')"
        slate
        faded
        size="sm"
        icon="i-ph-pause"
        :aria-label="t('MONITORS.PAUSE')"
        @click="openAction('pause')"
      />
      <Button
        v-if="monitor.paused_at"
        v-tooltip.bottom="t('MONITORS.RESUME')"
        slate
        faded
        size="sm"
        icon="i-ph-play"
        :aria-label="t('MONITORS.RESUME')"
        @click="openAction('resume')"
      />
      <Button
        v-tooltip.bottom="t('MONITORS.DELETE')"
        ruby
        faded
        size="sm"
        icon="i-woot-bin"
        :aria-label="t('MONITORS.DELETE')"
        @click="openAction('delete')"
      />
    </div>
  </ReportHeader>
  <MonitorUsageWarning :usage="result?.usage" />
  <div class="flex flex-col gap-4">
    <Banner v-if="error" color="ruby" role="alert">{{ error }}</Banner>
    <Banner v-if="notice" color="blue" role="status">{{ notice }}</Banner>
    <Banner
      v-if="monitor && (statusText || monitor.processing.errors)"
      :color="monitor.processing.errors ? 'amber' : 'slate'"
      :action-label="canRetry ? t('MONITORS.RETRY') : null"
      :is-loading="isRetrying"
      @action="retry"
    >
      <p v-if="statusText" role="status" class="m-0 font-medium">
        {{ statusText }}
      </p>
      <div v-if="monitor.processing.errors" role="alert">
        <p
          v-for="code in monitor.processing.error_codes"
          :key="code"
          class="m-0"
        >
          {{ errorText(code) }}
        </p>
      </div>
    </Banner>
    <div class="rounded-xl border border-n-weak bg-n-solid-1 p-5">
      <div class="flex flex-wrap items-start justify-between gap-4">
        <div class="flex flex-col gap-1">
          <div class="flex items-center gap-1.5">
            <span class="text-body-main text-n-slate-11">
              {{ t('MONITORS.MATCHING_CONVERSATIONS') }}
            </span>
            <button
              v-tooltip.top="t('MONITORS.TIME_BASIS_HELP')"
              type="button"
              :aria-label="t('MONITORS.TIME_BASIS_HELP')"
              class="inline-flex size-5 items-center justify-center rounded p-0 text-n-slate-10 hover:text-n-slate-12 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-n-brand"
            >
              <span
                class="i-lucide-info size-3.5 shrink-0"
                aria-hidden="true"
              />
            </button>
          </div>
          <span v-if="result" class="text-3xl font-semibold text-n-slate-12">
            {{ result.total_count }}
          </span>
        </div>
        <MonitorChartFilters
          v-model="filters"
          :paused-at="monitor?.paused_at"
        />
      </div>
      <div v-if="!result && isPending" class="flex justify-center py-20">
        <Spinner />
      </div>
      <template v-if="result">
        <BarChart
          class="mt-4"
          :data="chartData"
          :aria-label="t('MONITORS.MATCHING_CONVERSATIONS')"
          :height="320"
          :y-step-size="countStep"
          :clickable="isAdmin"
          timeseries
          @item-click="openBucket"
        />
        <p class="mb-0 mt-4 flex items-center gap-1 text-xs text-n-slate-11">
          {{
            monitor.paused_at
              ? t('MONITORS.COLLECTED_UNTIL', { time: pausedAtLabel })
              : t('MONITORS.REFRESHED', { time: refreshedAt })
          }}
          <button
            v-if="result.buckets.some(bucket => !bucket.covered)"
            v-tooltip.top="t('MONITORS.COVERAGE_HELP')"
            type="button"
            :aria-label="t('MONITORS.COVERAGE_HELP')"
            class="inline-flex size-5 items-center justify-center rounded p-0 text-n-amber-11 hover:text-n-amber-12 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-n-brand"
          >
            <span
              class="i-lucide-triangle-alert size-3.5 shrink-0"
              aria-hidden="true"
            />
          </button>
        </p>
      </template>
    </div>
  </div>
  <MonitorDrilldown
    v-if="drilldown"
    :request="drilldown.request"
    :title="bucketLabel(drilldown.bucket)"
    :count="drilldown.bucket.count"
    @close="drilldown = null"
    @changed="resultsChanged"
  />
  <MonitorActionDialog
    v-if="isAdmin"
    :key="`${accountId}/${monitorId}`"
    ref="actionDialog"
    @saved="onActionSaved"
    @changed="onMonitorChanged"
  />
</template>
