<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { addDays, differenceInCalendarDays, format } from 'date-fns';
import { formatInTimeZone, zonedTimeToUtc } from 'date-fns-tz';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import MonitorsAPI from 'dashboard/api/monitors';
import BarChart from 'shared/components/charts/BarChart.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ReportHeader from '../components/ReportHeader.vue';
import MonitorDrilldown from './MonitorDrilldown.vue';
import MonitorUsageWarning from './MonitorUsageWarning.vue';
import { useMonitorRefresh } from './useMonitorRefresh';

const { t, te } = useI18n();
const route = useRoute();
const router = useRouter();
const { accountId, currentAccount, accountScopedRoute } = useAccount();
const { isAdmin } = useAdmin();
const { run, abort, isPending } = useAbortableRequest();
const result = ref(null);
const error = ref('');
const notice = ref('');
const rangeDays = ref('7');
const interval = ref('day');
const timezone = computed(
  () =>
    currentAccount.value?.reporting_timezone ||
    currentAccount.value?.custom_attributes?.timezone ||
    Intl.DateTimeFormat().resolvedOptions().timeZone
);
const MIN_RANGE_DAYS = 7;
const MAX_RANGE_DAYS = 30;
const today = formatInTimeZone(new Date(), timezone.value, 'yyyy-MM-dd');
const startDate = ref(
  format(
    addDays(new Date(`${today}T12:00:00`), 1 - MIN_RANGE_DAYS),
    'yyyy-MM-dd'
  )
);
const endDate = ref(today);
const request = ref(null);
const displayedRequest = ref(null);
const displayedRangeDays = ref('7');
const collectionEndsAt = ref(null);
const activeRangeDays = ref('7');
const filterPopover = ref(null);
const filterTrigger = ref(null);
const filterForm = ref(null);
const rangeSelect = ref(null);
const filterError = ref('');
const drilldown = ref(null);
const drilldownLabel = ref('');
const refreshedAt = ref(null);
const actionDialog = ref(null);
const action = ref('');
const newName = ref('');
const newCondition = ref('');
const actionVersion = ref(null);
const actionError = ref('');
const resumeMode = ref('catch_up');
const isSaving = ref(false);
const monitor = computed(() => result.value?.monitor);
const monitorId = computed(() => route.params.monitorId);
const groupingOptions = computed(() => [
  { value: 'hour', label: t('MONITORS.INTERVALS.hour') },
  { value: 'six_hours', label: t('MONITORS.INTERVALS.six_hours') },
  { value: 'day', label: t('MONITORS.INTERVALS.day') },
]);
const filterSummary = computed(() => {
  if (!displayedRequest.value) return '';
  let range;
  if (displayedRangeDays.value === 'custom') {
    const dateOptions = {
      timeZone: displayedRequest.value.timezone,
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    };
    range = t('MONITORS.CUSTOM_RANGE_SUMMARY', {
      from: new Date(displayedRequest.value.since * 1000).toLocaleDateString(
        undefined,
        dateOptions
      ),
      to: new Date(
        (displayedRequest.value.until - 1) * 1000
      ).toLocaleDateString(undefined, dateOptions),
    });
  } else {
    range = monitor.value?.paused_at
      ? t('MONITORS.LAST_DAYS_BEFORE_PAUSE', { days: displayedRangeDays.value })
      : t('MONITORS.LAST_DAYS', { days: displayedRangeDays.value });
  }
  return t('MONITORS.FILTER_SUMMARY', {
    range,
    interval: groupingOptions.value.find(
      option => option.value === displayedRequest.value.interval
    ).label,
  });
});
const focusFilters = async () => {
  await nextTick();
  rangeSelect.value?.focus();
};
const restoreFilterFocus = () => {
  if (filterForm.value?.contains(document.activeElement)) {
    filterTrigger.value?.$el.focus();
  }
};
const pausedAtLabel = computed(() =>
  monitor.value?.paused_at
    ? new Date(monitor.value.paused_at * 1000).toLocaleString(undefined, {
        timeZone: result.value.timezone,
      })
    : ''
);
const CHART_TICK_COUNT = 5;
const countStep = computed(() =>
  Math.max(
    1,
    Math.ceil(
      Math.max(
        0,
        ...(result.value?.buckets.map(bucket => bucket.count) || [])
      ) / CHART_TICK_COUNT
    )
  )
);
const actionLabel = computed(() =>
  t(`MONITORS.${action.value.toUpperCase() || 'EDIT'}`)
);
const labelFor = bucket =>
  new Date(bucket.start * 1000).toLocaleString(undefined, {
    timeZone: result.value.timezone,
    month: 'short',
    day: 'numeric',
    ...(result.value.interval !== 'day'
      ? { hour: 'numeric', minute: '2-digit', timeZoneName: 'short' }
      : {}),
  });
const chartData = computed(() => ({
  categories: result.value?.buckets.map(labelFor) || [],
  series: [
    {
      id: 'matches',
      label: t('MONITORS.MATCHING_CONVERSATIONS'),
      color: 'rgb(var(--blue-9))',
      data: result.value?.buckets.map(bucket => bucket.count) || [],
    },
  ],
}));
const errorText = code =>
  t(
    te(`MONITORS.ERRORS.${code}`)
      ? `MONITORS.ERRORS.${code}`
      : 'MONITORS.ERRORS.fetch_failed'
  );

const fetchReport = async () => {
  if (!request.value) return;
  if (activeRangeDays.value !== 'custom') {
    const until = collectionEndsAt.value || Math.floor(Date.now() / 1000);
    request.value = {
      ...request.value,
      until,
      since: until - Number(activeRangeDays.value) * 86400,
    };
  }
  if (collectionEndsAt.value) {
    request.value = {
      ...request.value,
      until: Math.min(request.value.until, collectionEndsAt.value),
    };
    if (request.value.since >= request.value.until) {
      error.value = errorText('invalid_parameters');
      result.value = null;
      drilldown.value = null;
      return;
    }
  }
  const requestedFilters = { ...request.value };
  const requestedRangeDays = activeRangeDays.value;
  const requestedAccount = accountId.value;
  const requestedMonitor = monitorId.value;
  try {
    const response = await run(signal =>
      MonitorsAPI.timeseries(requestedMonitor, requestedFilters, signal)
    );
    if (
      !response ||
      requestedAccount !== accountId.value ||
      requestedMonitor !== monitorId.value
    )
      return;
    const wasPaused = Boolean(collectionEndsAt.value);
    collectionEndsAt.value = response.data.monitor.paused_at || null;
    if (
      wasPaused &&
      !collectionEndsAt.value &&
      activeRangeDays.value !== 'custom'
    ) {
      await fetchReport();
      return;
    }
    if (
      collectionEndsAt.value &&
      (activeRangeDays.value === 'custom'
        ? requestedFilters.until > collectionEndsAt.value
        : requestedFilters.until !== collectionEndsAt.value)
    ) {
      await fetchReport();
      return;
    }
    if (drilldown.value) {
      const selected = result.value.buckets.find(
        bucket => bucket.start === drilldown.value.bucket_start
      );
      const updated = response.data.buckets.find(
        bucket => bucket.start === drilldown.value.bucket_start
      );
      if (
        response.data.data_revision !== drilldown.value.data_revision ||
        !updated ||
        updated.count !== selected.count
      ) {
        drilldown.value = null;
        notice.value = t('MONITORS.RESULTS_UPDATED');
      }
    }
    result.value = response.data;
    displayedRequest.value = requestedFilters;
    displayedRangeDays.value = requestedRangeDays;
    refreshedAt.value = new Date().toLocaleTimeString();
    error.value = '';
  } catch (failure) {
    error.value = errorText(failure.response?.data?.error);
    result.value = null;
    drilldown.value = null;
  }
};

const applyFilters = () => {
  filterError.value = '';
  if (rangeDays.value === 'custom') {
    const days =
      differenceInCalendarDays(
        new Date(`${endDate.value}T12:00:00`),
        new Date(`${startDate.value}T12:00:00`)
      ) + 1;
    if (
      !Number.isFinite(days) ||
      days < MIN_RANGE_DAYS ||
      days > MAX_RANGE_DAYS
    ) {
      filterError.value = t('MONITORS.CUSTOM_RANGE_HELP');
      return;
    }
  }
  const until =
    rangeDays.value === 'custom'
      ? zonedTimeToUtc(
          `${format(addDays(new Date(`${endDate.value}T12:00:00`), 1), 'yyyy-MM-dd')}T00:00:00`,
          timezone.value
        ).getTime() / 1000
      : Math.floor(Date.now() / 1000);
  const since =
    rangeDays.value === 'custom'
      ? zonedTimeToUtc(
          `${startDate.value}T00:00:00`,
          timezone.value
        ).getTime() / 1000
      : until - Number(rangeDays.value) * 86400;
  if (!Number.isFinite(since) || !Number.isFinite(until) || since >= until) {
    filterError.value = errorText('invalid_parameters');
    return;
  }
  request.value = {
    since,
    until,
    interval: interval.value,
    timezone: timezone.value,
  };
  activeRangeDays.value = rangeDays.value;
  drilldown.value = null;
  filterPopover.value?.hide();
  fetchReport();
};

watch(
  [accountId, monitorId, timezone],
  () => {
    abort();
    result.value = null;
    displayedRequest.value = null;
    collectionEndsAt.value = null;
    drilldown.value = null;
    notice.value = '';
    filterPopover.value?.hide();
    actionDialog.value?.close();
    applyFilters();
  },
  { immediate: true }
);
watch(isAdmin, () => {
  drilldown.value = null;
});
useMonitorRefresh(fetchReport);

const openBucket = ({ pointIndex }) => {
  if (!isAdmin.value) return;
  const bucket = result.value.buckets[pointIndex];
  if (!bucket || !bucket.count) return;
  drilldownLabel.value = `${labelFor(bucket)} · ${bucket.count}`;
  drilldown.value = {
    ...displayedRequest.value,
    monitorId: monitorId.value,
    bucket_start: bucket.start,
    data_revision: result.value.data_revision,
  };
};
const resultsChanged = () => {
  drilldown.value = null;
  notice.value = t('MONITORS.RESULTS_UPDATED');
  fetchReport();
};
const openAction = nextAction => {
  action.value = nextAction;
  newName.value = monitor.value.name;
  newCondition.value = monitor.value.condition;
  actionVersion.value = monitor.value.collection_version;
  actionError.value = '';
  resumeMode.value = 'catch_up';
  actionDialog.value.open();
};
const saveAction = async () => {
  if (isSaving.value) return;
  isSaving.value = true;
  actionError.value = '';
  const target = `${accountId.value}/${monitorId.value}`;
  const deleting = action.value === 'delete';
  try {
    if (deleting) {
      await MonitorsAPI.delete(monitorId.value);
    } else if (action.value === 'resume') {
      await MonitorsAPI.resume(monitorId.value, {
        mode: resumeMode.value,
        collection_version: actionVersion.value,
      });
    } else {
      await MonitorsAPI.update(
        monitorId.value,
        action.value === 'edit'
          ? {
              name: newName.value.trim(),
              condition: newCondition.value.trim(),
              collection_version: actionVersion.value,
            }
          : { paused: true }
      );
    }
    if (target !== `${accountId.value}/${monitorId.value}`) return;
    if (deleting) router.push(accountScopedRoute('monitor_reports_index'));
    else fetchReport();
    actionDialog.value.close();
  } catch (failure) {
    actionError.value = errorText(failure.response?.data?.error);
    if (failure.response?.data?.error === 'monitor_changed') {
      notice.value = actionError.value;
      actionDialog.value.close();
      fetchReport();
    }
  } finally {
    isSaving.value = false;
  }
};
const retry = async () => {
  try {
    await MonitorsAPI.retry(monitorId.value);
    notice.value = t('MONITORS.RETRY_STARTED');
    fetchReport();
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
        icon="i-lucide-pencil"
        :aria-label="t('MONITORS.EDIT')"
        @click="openAction('edit')"
      />
      <Button
        v-tooltip.bottom="t('MONITORS.DUPLICATE')"
        slate
        faded
        icon="i-lucide-copy"
        :aria-label="t('MONITORS.DUPLICATE')"
        @click="duplicate"
      />
      <Button
        v-if="!monitor.paused_at"
        v-tooltip.bottom="t('MONITORS.PAUSE')"
        slate
        faded
        icon="i-lucide-pause"
        :aria-label="t('MONITORS.PAUSE')"
        @click="openAction('pause')"
      />
      <Button
        v-if="monitor.paused_at"
        v-tooltip.bottom="t('MONITORS.RESUME')"
        slate
        faded
        icon="i-lucide-play"
        :aria-label="t('MONITORS.RESUME')"
        @click="openAction('resume')"
      />
      <Button
        v-tooltip.bottom="t('MONITORS.DELETE')"
        ruby
        faded
        icon="i-lucide-trash-2"
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
        <Popover
          ref="filterPopover"
          @show="focusFilters"
          @hide="restoreFilterFocus"
        >
          <template #default="{ isOpen }">
            <Button
              ref="filterTrigger"
              v-tooltip.bottom="t('MONITORS.FILTERS')"
              slate
              ghost
              size="sm"
              icon="i-lucide-list-filter"
              class="shrink-0"
              :aria-label="t('MONITORS.FILTERS')"
              :aria-expanded="isOpen"
              aria-haspopup="dialog"
              aria-controls="monitor-chart-filters"
            />
          </template>
          <template #content>
            <form
              id="monitor-chart-filters"
              ref="filterForm"
              role="dialog"
              :aria-label="t('MONITORS.FILTERS')"
              class="flex w-full flex-col gap-4 p-4 md:w-72"
              @submit.prevent="applyFilters"
            >
              <p class="m-0 text-sm font-medium text-n-slate-12">
                {{ t('MONITORS.FILTERS') }}
              </p>
              <label class="flex flex-col gap-2 text-sm text-n-slate-12">
                {{ t('MONITORS.DATE_RANGE') }}
                <select
                  ref="rangeSelect"
                  v-model="rangeDays"
                  class="m-0 w-full rounded-lg border border-n-weak bg-n-solid-1 text-sm text-n-slate-12"
                >
                  <option
                    v-for="days in [MIN_RANGE_DAYS, MAX_RANGE_DAYS]"
                    :key="days"
                    :value="String(days)"
                  >
                    {{
                      monitor?.paused_at
                        ? t('MONITORS.LAST_DAYS_BEFORE_PAUSE', { days })
                        : t('MONITORS.LAST_DAYS', { days })
                    }}
                  </option>
                  <option value="custom">
                    {{ t('MONITORS.CUSTOM_RANGE') }}
                  </option>
                </select>
              </label>
              <template v-if="rangeDays === 'custom'">
                <Input
                  v-model="startDate"
                  type="date"
                  :label="t('MONITORS.FROM')"
                />
                <Input
                  v-model="endDate"
                  type="date"
                  :label="t('MONITORS.TO')"
                />
                <p v-if="!filterError" class="m-0 text-xs text-n-slate-11">
                  {{ t('MONITORS.CUSTOM_RANGE_HELP') }}
                </p>
              </template>
              <label class="flex flex-col gap-2 text-sm text-n-slate-12">
                {{ t('MONITORS.INTERVAL') }}
                <select
                  v-model="interval"
                  class="m-0 w-full rounded-lg border border-n-weak bg-n-solid-1 text-sm text-n-slate-12"
                >
                  <option
                    v-for="option in groupingOptions"
                    :key="option.value"
                    :value="option.value"
                  >
                    {{ option.label }}
                  </option>
                </select>
              </label>
              <p
                v-if="filterError"
                role="alert"
                class="m-0 text-xs text-n-ruby-11"
              >
                {{ filterError }}
              </p>
              <Button
                type="submit"
                size="sm"
                :label="t('MONITORS.APPLY')"
                :is-loading="isPending"
              />
            </form>
          </template>
        </Popover>
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
        {{ t(`MONITORS.STATES.${monitor.processing.state}`) }}
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
    v-if="isAdmin"
    :request="drilldown"
    :label="drilldownLabel"
    @close="drilldown = null"
    @changed="resultsChanged"
  />
  <Dialog
    ref="actionDialog"
    :title="actionLabel"
    :confirm-button-label="
      action === 'edit' ? t('MONITORS.UPDATE') : actionLabel
    "
    :is-loading="isSaving"
    :disable-confirm-button="
      isSaving ||
      (action === 'edit' && (!newName.trim() || !newCondition.trim()))
    "
    @confirm="saveAction"
  >
    <div v-if="action === 'edit'" class="flex flex-col gap-4">
      <Input v-model="newName" :label="t('MONITORS.NAME')" maxlength="100" />
      <label class="flex flex-col gap-2 text-sm text-n-slate-12">
        {{ t('MONITORS.MONITOR_DESCRIPTION') }}
        <textarea
          v-model="newCondition"
          :placeholder="t('MONITORS.CONDITION_PLACEHOLDER')"
          maxlength="2000"
          rows="4"
          class="w-full rounded-lg border border-n-weak bg-n-solid-1 p-3 text-sm text-n-slate-12 focus:border-n-brand"
        />
      </label>
      <p class="m-0 text-sm text-n-slate-11">{{ t('MONITORS.EDIT_HELP') }}</p>
    </div>
    <fieldset v-else-if="action === 'resume'" class="flex flex-col gap-4">
      <legend class="mb-4 text-sm text-n-slate-11">
        {{ t('MONITORS.RESUME_HELP') }}
      </legend>
      <label
        class="flex cursor-pointer items-start gap-3 rounded-lg border border-n-weak p-4"
      >
        <input
          v-model="resumeMode"
          type="radio"
          value="catch_up"
          name="monitor-resume-mode"
          class="mt-1"
        />
        <span class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">{{
            t('MONITORS.RESUME_CATCH_UP')
          }}</span>
          <span class="text-sm text-n-slate-11">{{
            t('MONITORS.RESUME_CATCH_UP_HELP')
          }}</span>
        </span>
      </label>
      <label
        class="flex cursor-pointer items-start gap-3 rounded-lg border border-n-weak p-4"
      >
        <input
          v-model="resumeMode"
          type="radio"
          value="from_now"
          name="monitor-resume-mode"
          class="mt-1"
        />
        <span class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">{{
            t('MONITORS.RESUME_FROM_NOW')
          }}</span>
          <span class="text-sm text-n-slate-11">{{
            t('MONITORS.RESUME_FROM_NOW_HELP')
          }}</span>
        </span>
      </label>
    </fieldset>
    <p v-else class="text-sm text-n-slate-11">
      {{
        t(action === 'delete' ? 'MONITORS.DELETE_HELP' : 'MONITORS.PAUSE_HELP')
      }}
    </p>
    <p v-if="actionError" role="alert" class="mt-4 text-sm text-n-ruby-11">
      {{ actionError }}
    </p>
  </Dialog>
</template>
