<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { formatInTimeZone, zonedTimeToUtc } from 'date-fns-tz';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { useLocale } from 'shared/composables/useLocale';
import MonitorsAPI from 'dashboard/api/monitors';
import BarChart from 'shared/components/charts/BarChart.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ReportHeader from '../components/ReportHeader.vue';
import MonitorChartFilters from './MonitorChartFilters.vue';
import MonitorDrilldown from './MonitorDrilldown.vue';
import MonitorActionDialog from './MonitorActionDialog.vue';
import MonitorUsageWarning from './MonitorUsageWarning.vue';
import { useMonitorRefresh } from './useMonitorRefresh';
import {
  CUSTOM_RANGE,
  DEFAULT_FILTERS,
  MIN_RANGE_DAYS,
  shiftDate,
} from './monitorFilters';

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
const filters = ref({ ...DEFAULT_FILTERS });
const collectionEndsAt = ref(null);
const result = ref(null);
const displayed = ref(null);
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
const startOfDay = date =>
  zonedTimeToUtc(`${date}T00:00:00`, timezone.value).getTime() / 1000;

// A paused monitor stops collecting, so every range ends at the pause instead of now.
const requestParams = ({ range, from, to, interval }) => {
  const end = collectionEndsAt.value || Math.floor(Date.now() / 1000);
  const params = { interval, timezone: timezone.value };
  if (range !== CUSTOM_RANGE) {
    return { ...params, since: end - range * DAY_IN_SECONDS, until: end };
  }
  return {
    ...params,
    since: startOfDay(from),
    until: Math.min(startOfDay(shiftDate(to, 1)), end),
  };
};

const filterSummary = computed(() => {
  if (!displayed.value) return '';
  const { range, from, to, interval } = displayed.value.filters;
  const dateOptions = { dateStyle: 'medium' };
  const lastDaysKey = monitor.value.paused_at
    ? 'MONITORS.LAST_DAYS_BEFORE_PAUSE'
    : 'MONITORS.LAST_DAYS';
  const rangeLabel =
    range === CUSTOM_RANGE
      ? t('MONITORS.CUSTOM_RANGE_SUMMARY', {
          from: formatTimestamp(startOfDay(from), dateOptions),
          to: formatTimestamp(startOfDay(to), dateOptions),
        })
      : t(lastDaysKey, { count: range });
  return t('MONITORS.FILTER_SUMMARY', {
    range: rangeLabel,
    interval: t(`MONITORS.INTERVALS.${interval.toUpperCase()}`),
  });
});
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

const fetchReport = async () => {
  const requested = {
    filters: filters.value,
    params: requestParams(filters.value),
  };
  const requestedAccount = accountId.value;
  const requestedMonitor = monitorId.value;
  try {
    const response = await run(signal =>
      MonitorsAPI.timeseries(requestedMonitor, requested.params, signal)
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
      const { range, from, to } = filters.value;
      const lastDate =
        pausedAt &&
        formatInTimeZone((pausedAt - 1) * 1000, timezone.value, 'yyyy-MM-dd');
      // A pause inside the applied custom range shortens it, falling back to the default when too short.
      if (range === CUSTOM_RANGE && lastDate && to > lastDate) {
        filters.value =
          lastDate < shiftDate(from, MIN_RANGE_DAYS - 1)
            ? { ...DEFAULT_FILTERS }
            : { ...filters.value, to: lastDate };
        return;
      }
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
    displayed.value = requested;
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
      ...displayed.value.params,
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
    displayed.value = null;
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
  shouldPoll: () => filters.value.range !== CUSTOM_RANGE,
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
  try {
    await runRetry(async signal => {
      await MonitorsAPI.retry(monitorId.value, signal);
      if (signal.aborted) return;
      notice.value = t('MONITORS.RETRY_STARTED');
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
        icon="i-lucide-copy"
        :aria-label="t('MONITORS.DUPLICATE')"
        @click="duplicate"
      />
      <Button
        v-if="!monitor.paused_at"
        v-tooltip.bottom="t('MONITORS.PAUSE')"
        slate
        faded
        size="sm"
        icon="i-lucide-pause"
        :aria-label="t('MONITORS.PAUSE')"
        @click="openAction('pause')"
      />
      <Button
        v-if="monitor.paused_at"
        v-tooltip.bottom="t('MONITORS.RESUME')"
        slate
        faded
        size="sm"
        icon="i-lucide-play"
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
  <p v-if="error" role="alert" class="text-sm text-n-ruby-11">{{ error }}</p>
  <p v-if="notice" role="status" class="text-sm text-n-slate-11">
    {{ notice }}
  </p>
  <div class="rounded-xl border border-n-weak bg-n-solid-1 p-5">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <p class="m-0 text-sm text-n-slate-11">
        {{ t('MONITORS.MATCHING_CONVERSATIONS') }}
      </p>
      <div class="ms-auto flex min-w-0 items-center gap-2">
        <span class="text-end text-xs text-n-slate-11">
          {{ filterSummary }}
        </span>
        <MonitorChartFilters
          :key="`${accountId}/${monitorId}`"
          v-model="filters"
          :timezone="timezone"
          :paused-at="monitor?.paused_at"
          :is-loading="isPending"
        />
      </div>
    </div>
    <div v-if="!result && isPending" class="flex justify-center py-20">
      <Spinner />
    </div>
    <template v-if="result">
      <p class="mb-1 mt-2 text-3xl font-semibold text-n-slate-12">
        {{ result.total_count }}
      </p>
      <p class="text-xs text-n-slate-11">{{ t('MONITORS.TIME_BASIS_HELP') }}</p>
      <p v-if="monitor.paused_at" role="status" class="text-sm text-n-slate-11">
        {{ t('MONITORS.PAUSED_HELP', { time: pausedAtLabel }) }}
      </p>
      <p
        v-else-if="monitor.processing.state !== 'live'"
        role="status"
        class="text-sm text-n-slate-11"
      >
        {{ t(`MONITORS.STATES.${monitor.processing.state.toUpperCase()}`) }}
      </p>
      <div
        v-if="monitor.processing.errors"
        class="mb-4 flex flex-wrap items-center justify-between gap-3"
      >
        <div role="alert">
          <p
            v-for="code in monitor.processing.error_codes"
            :key="code"
            class="m-0 text-sm text-n-amber-11"
          >
            {{ errorText(code) }}
          </p>
        </div>
        <Button
          v-if="isAdmin && !monitor.paused_at && !result.usage?.limit_reached"
          slate
          faded
          :label="t('MONITORS.RETRY')"
          :is-loading="isRetrying"
          :disabled="isRetrying"
          @click="retry"
        />
      </div>
      <BarChart
        :data="chartData"
        :aria-label="t('MONITORS.MATCHING_CONVERSATIONS')"
        :height="320"
        :y-step-size="countStep"
        :clickable="isAdmin"
        timeseries
        @item-click="openBucket"
      />
      <p class="mb-0 mt-4 text-xs text-n-slate-11">
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
          class="ms-1 inline-flex size-6 items-center justify-center rounded p-0 align-middle text-n-amber-11 hover:text-n-amber-12 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-n-brand"
        >
          <span
            class="i-lucide-triangle-alert size-3.5 shrink-0"
            aria-hidden="true"
          />
        </button>
      </p>
    </template>
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
