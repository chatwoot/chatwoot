<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import MonitorsAPI from 'dashboard/api/monitors';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ReportHeader from '../components/ReportHeader.vue';
import MonitorForm from './MonitorForm.vue';
import MonitorUsageWarning from './MonitorUsageWarning.vue';
import { useMonitorRefresh } from './useMonitorRefresh';

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
const condition = ref('');
const examples = computed(() => [
  t('MONITORS.EXAMPLES.REFUNDS'),
  t('MONITORS.EXAMPLES.BSUID'),
  t('MONITORS.EXAMPLES.AUTOMATIONS'),
]);

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

const openForm = async (example = '') => {
  condition.value = example;
  await nextTick();
  form.value?.open();
};
const onCreated = monitor =>
  router.push(
    accountScopedRoute('monitor_reports_show', { monitorId: monitor.id })
  );
watch(
  () => route.query.condition,
  value => {
    if (typeof value === 'string' && isAdmin.value) openForm(value);
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
      :label="t('MONITORS.CREATE')"
      @click="openForm()"
    />
  </ReportHeader>
  <MonitorUsageWarning :usage="meta.usage" />
  <p
    v-if="!meta.configured && isAdmin"
    role="status"
    class="rounded-lg bg-n-amber-3 p-4 text-sm text-n-amber-11"
  >
    {{ t('MONITORS.ERRORS.not_configured') }}
  </p>
  <div v-if="isPending && !loaded" class="flex justify-center py-20">
    <Spinner />
  </div>
  <div
    v-else-if="hasError"
    role="alert"
    class="flex flex-col items-center gap-4 py-12"
  >
    <p class="text-n-ruby-11">{{ t('MONITORS.ERRORS.fetch_failed') }}</p>
    <Button :label="t('MONITORS.RETRY')" @click="fetchMonitors" />
  </div>
  <div
    v-else-if="!meta.total_count"
    class="flex flex-col items-center gap-6 rounded-xl border border-n-weak bg-n-solid-1 px-6 py-16 text-center"
  >
    <span class="i-lucide-chart-no-axes-combined size-12 text-n-brand" />
    <h2 class="m-0 text-heading-2 text-n-slate-12">
      {{ t('MONITORS.EMPTY_TITLE') }}
    </h2>
    <p class="m-0 max-w-lg text-body-main text-n-slate-11">
      {{ t('MONITORS.EMPTY_DESCRIPTION') }}
    </p>
    <div class="flex max-w-xl flex-col gap-3">
      <button
        v-for="example in examples"
        :key="example"
        type="button"
        :disabled="!isAdmin"
        class="rounded-lg border border-n-weak px-5 py-3 text-start text-sm text-n-slate-12 enabled:hover:bg-n-alpha-2"
        @click="openForm(example)"
      >
        {{ example }}
      </button>
    </div>
    <Button v-if="isAdmin" :label="t('MONITORS.CREATE')" @click="openForm()" />
    <p v-else class="text-sm text-n-slate-11">{{ t('MONITORS.ADMIN_HELP') }}</p>
  </div>
  <div v-else class="flex flex-col gap-3">
    <RouterLink
      v-for="monitor in monitors"
      :key="monitor.id"
      :to="
        accountScopedRoute('monitor_reports_show', { monitorId: monitor.id })
      "
      class="flex items-center justify-between gap-5 rounded-xl border border-n-weak bg-n-solid-1 p-5 hover:bg-n-alpha-2"
    >
      <div class="min-w-0">
        <h2 class="m-0 truncate text-heading-3 text-n-slate-12">
          {{ monitor.name }}
        </h2>
        <p class="my-2 line-clamp-2 text-sm text-n-slate-11">
          {{ monitor.condition }}
        </p>
        <span class="text-xs text-n-slate-11">{{
          t(`MONITORS.STATES.${monitor.processing.state}`)
        }}</span>
      </div>
      <div class="shrink-0 text-end">
        <p class="m-0 text-2xl font-semibold text-n-slate-12">
          {{ monitor.recent_count }}
        </p>
        <span class="text-xs text-n-slate-11">{{
          monitor.paused_at
            ? t('MONITORS.LAST_DAYS_BEFORE_PAUSE', { days: 7 })
            : t('MONITORS.LAST_SEVEN_DAYS')
        }}</span>
      </div>
    </RouterLink>
    <div class="mt-3 flex justify-end gap-2">
      <Button
        v-if="page > 1"
        slate
        faded
        :label="t('MONITORS.PREVIOUS')"
        @click="page -= 1"
      />
      <Button
        v-if="page * 20 < meta.total_count"
        slate
        faded
        :label="t('MONITORS.NEXT')"
        @click="page += 1"
      />
    </div>
  </div>
  <MonitorForm
    v-if="isAdmin"
    :key="accountId"
    ref="form"
    :initial-condition="condition"
    @created="onCreated"
  />
</template>
