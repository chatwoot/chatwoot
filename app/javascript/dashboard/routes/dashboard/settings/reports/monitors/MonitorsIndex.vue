<script setup>
import { nextTick, ref, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import MonitorsAPI from 'dashboard/api/monitors';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import MonitorActionDialog from './MonitorActionDialog.vue';
import ReportHeader from '../components/ReportHeader.vue';
import MonitorForm from './MonitorForm.vue';
import MonitorsEmptyState from './MonitorsEmptyState.vue';
import MonitorListItem from './MonitorListItem.vue';
import MonitorUsageWarning from './MonitorUsageWarning.vue';
import { useMonitorRefresh } from './useMonitorRefresh';

const PAGE_SIZE = 20;

const { t } = useI18n();
const router = useRouter();
const route = useRoute();
const { accountId, accountScopedRoute } = useAccount();
const { isAdmin } = useAdmin();
const { run, isPending } = useAbortableRequest();
const monitors = ref([]);
const page = ref(1);
const meta = ref({ total_count: 0, configured: true });
const loaded = ref(false);
const hasError = ref(false);
const form = ref(null);
const actionDialog = ref(null);
const notice = ref('');

const fetchMonitors = async () => {
  try {
    const response = await run(signal =>
      MonitorsAPI.get({ page: page.value }, signal)
    );
    if (!response) return;
    monitors.value = response.data.payload;
    meta.value = response.data.meta;
    loaded.value = true;
    hasError.value = false;
  } catch {
    hasError.value = true;
    monitors.value = [];
  }
};

watch(accountId, () => {
  loaded.value = false;
  notice.value = '';
  page.value = 1;
  meta.value = { total_count: 0, configured: true };
});
watch(
  [accountId, page],
  () => {
    monitors.value = [];
    fetchMonitors();
  },
  { immediate: true }
);
useMonitorRefresh(fetchMonitors);

const openForm = async prefill => {
  // Duplicate links open the form during setup, before it has mounted.
  await nextTick();
  form.value?.open(prefill);
};
const onActionSaved = action => {
  notice.value = '';
  if (action === 'delete' && monitors.value.length === 1 && page.value > 1) {
    page.value -= 1;
  } else {
    fetchMonitors();
  }
};
const onMonitorChanged = message => {
  notice.value = message;
  fetchMonitors();
};
const onCreated = monitor =>
  router.push(
    accountScopedRoute('monitor_reports_show', { monitorId: monitor.id })
  );
watch(
  () => route.query.condition,
  value => {
    if (typeof value !== 'string' || !isAdmin.value) return;
    openForm({ condition: value });
    // The condition is a one-time prefill; drop it so a refresh or back navigation doesn't reopen the form.
    const { condition, ...query } = route.query;
    router.replace({ query });
  },
  { immediate: true }
);
</script>

<template>
  <ReportHeader
    :header-title="t('MONITORS.TITLE')"
    :header-description="t('MONITORS.DESCRIPTION')"
  >
    <Button
      v-if="isAdmin"
      icon="i-lucide-plus"
      size="sm"
      :label="t('MONITORS.CREATE')"
      @click="openForm()"
    />
  </ReportHeader>
  <MonitorUsageWarning :usage="meta.usage" />
  <p v-if="notice" role="status" class="text-sm text-n-slate-11">
    {{ notice }}
  </p>
  <p
    v-if="!meta.configured && isAdmin"
    role="status"
    class="rounded-lg bg-n-amber-3 p-4 text-sm text-n-amber-11"
  >
    {{ t('MONITORS.ERRORS.NOT_CONFIGURED') }}
  </p>
  <div v-if="isPending && !loaded" class="flex justify-center py-20">
    <Spinner />
  </div>
  <div
    v-else-if="hasError"
    role="alert"
    class="flex flex-col items-center gap-4 py-12"
  >
    <p class="text-n-ruby-11">{{ t('MONITORS.LIST.FETCH_FAILED') }}</p>
    <Button :label="t('MONITORS.RETRY')" @click="fetchMonitors" />
  </div>
  <MonitorsEmptyState v-else-if="!meta.total_count" @create="openForm" />
  <div v-else class="flex flex-col gap-3">
    <div class="flex flex-col divide-y divide-n-weak border-t border-n-weak">
      <MonitorListItem
        v-for="monitor in monitors"
        :key="monitor.id"
        :monitor="monitor"
        :show-actions="isAdmin"
        @action="action => actionDialog.open(action, monitor)"
      />
    </div>
    <div class="mt-3 flex justify-end gap-2">
      <Button
        v-if="page > 1"
        slate
        faded
        :label="t('MONITORS.PREVIOUS')"
        @click="page -= 1"
      />
      <Button
        v-if="page * PAGE_SIZE < meta.total_count"
        slate
        faded
        :label="t('MONITORS.NEXT')"
        @click="page += 1"
      />
    </div>
  </div>
  <MonitorActionDialog
    v-if="isAdmin"
    :key="`actions-${accountId}`"
    ref="actionDialog"
    @saved="onActionSaved"
    @changed="onMonitorChanged"
  />
  <MonitorForm
    v-if="isAdmin"
    :key="accountId"
    ref="form"
    @created="onCreated"
  />
</template>
