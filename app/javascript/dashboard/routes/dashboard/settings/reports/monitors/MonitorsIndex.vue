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
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import MonitorActionDialog from './MonitorActionDialog.vue';
import ReportHeader from '../components/ReportHeader.vue';
import MonitorForm from './MonitorForm.vue';
import MonitorsEmptyState from './MonitorsEmptyState.vue';
import MonitorListItem from './MonitorListItem.vue';
import MonitorTemplateCard from './MonitorTemplateCard.vue';
import MonitorUsageWarning from './MonitorUsageWarning.vue';
import { MONITOR_TEMPLATES } from './monitorTemplates';
import { useMonitorRefresh } from './useMonitorRefresh';

const PAGE_SIZE = 20;

const { t } = useI18n();
const router = useRouter();
const route = useRoute();
const { accountId, accountScopedRoute } = useAccount();
const { isAdmin } = useAdmin();
const { run, isPending } = useAbortableRequest();
const monitors = ref([]);

const page = computed({
  get: () => Number(route.query.page) || 1,
  set: value => router.replace({ query: { ...route.query, page: value } }),
});
const meta = ref({ total_count: 0, configured: true });
const loaded = ref(false);
const hasError = ref(false);
const mainContent = ref(null);
const form = ref(null);
const actionDialog = ref(null);
const notice = ref('');
const activeSection = ref('monitors');
// The translation paths are built only from the fixed template catalog.
/* eslint-disable @intlify/vue-i18n/no-dynamic-keys */
const templates = computed(() =>
  MONITOR_TEMPLATES.map(({ key, ...template }) => ({
    ...template,
    name: t(`MONITORS.TEMPLATES.${key}.NAME`),
    audience: t(`MONITORS.TEMPLATES.${key}.AUDIENCE`),
    summary: t(`MONITORS.TEMPLATES.${key}.SUMMARY`),
    condition: t(`MONITORS.TEMPLATES.${key}.CONDITION`),
  }))
);
/* eslint-enable @intlify/vue-i18n/no-dynamic-keys */
const refundTemplate = computed(() =>
  templates.value.find(({ id }) => id === 'refund-requests')
);
// Background refreshes keep the page; only a page change shows the loader.
const isChangingPage = computed(
  () => isPending.value && loaded.value && meta.value.page !== page.value
);

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
  monitors.value = [];
  loaded.value = false;
  notice.value = '';
  activeSection.value = 'monitors';
  page.value = 1;
  meta.value = { total_count: 0, configured: true };
});
watch([accountId, page], fetchMonitors, { immediate: true });
useMonitorRefresh(fetchMonitors);

const openForm = async prefill => {
  // Duplicate links open the form during setup, before it has mounted.
  await nextTick();
  form.value?.open(prefill);
};
const selectSection = section => {
  activeSection.value = section;
  mainContent.value?.scrollTo({ top: 0 });
};
const openTemplate = template => {
  if (!isAdmin.value) return;
  openForm({
    name: template.name,
    condition: template.condition,
    icon: template.icon,
    icon_color: template.icon_color,
    templateName: template.name,
  });
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
  () => [route.query.template, route.query.condition, isAdmin.value],
  ([templateId, condition]) => {
    if (typeof templateId === 'string') {
      activeSection.value = 'templates';
      if (!isAdmin.value) return;
      const selectedTemplate = templates.value.find(
        ({ id }) => id === templateId
      );
      if (selectedTemplate) openTemplate(selectedTemplate);
      const query = { ...route.query };
      delete query.template;
      delete query.condition;
      router.replace({ query });
      return;
    }
    if (typeof condition !== 'string' || !isAdmin.value) return;
    openForm({ condition });
    // The condition is a one-time prefill; drop it so a refresh or back navigation doesn't reopen the form.
    const query = { ...route.query };
    delete query.condition;
    router.replace({ query });
  },
  { immediate: true }
);
</script>

<template>
  <section class="flex h-full w-full flex-col overflow-hidden bg-n-surface-1">
    <main ref="mainContent" class="flex-1 overflow-y-auto px-6">
      <div class="mx-auto w-full max-w-5xl pb-6">
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
        <div
          role="group"
          :aria-label="t('MONITORS.SECTIONS.LABEL')"
          class="mt-6 flex gap-6 border-b border-n-weak"
        >
          <button
            type="button"
            :aria-pressed="activeSection === 'monitors'"
            class="min-h-11 border-b-2 px-1 text-sm font-medium focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand"
            :class="
              activeSection === 'monitors'
                ? 'border-n-brand text-n-brand'
                : 'border-transparent text-n-slate-11 hover:text-n-slate-12'
            "
            @click="selectSection('monitors')"
          >
            {{
              loaded && !hasError
                ? t('MONITORS.SECTIONS.YOUR_MONITORS_COUNT', {
                    count: meta.total_count,
                  })
                : t('MONITORS.SECTIONS.YOUR_MONITORS')
            }}
          </button>
          <button
            type="button"
            :aria-pressed="activeSection === 'templates'"
            class="min-h-11 border-b-2 px-1 text-sm font-medium focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand"
            :class="
              activeSection === 'templates'
                ? 'border-n-brand text-n-brand'
                : 'border-transparent text-n-slate-11 hover:text-n-slate-12'
            "
            @click="selectSection('templates')"
          >
            {{ t('MONITORS.SECTIONS.TEMPLATES') }}
          </button>
        </div>
        <section v-if="activeSection === 'templates'" class="py-6">
          <div class="mb-5 flex flex-col gap-1">
            <h2 class="m-0 text-heading-2 text-n-slate-12">
              {{ t('MONITORS.TEMPLATES.TITLE') }}
            </h2>
            <p class="m-0 text-body-main text-n-slate-11">
              {{ t('MONITORS.TEMPLATES.DESCRIPTION') }}
            </p>
          </div>
          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <MonitorTemplateCard
              v-for="template in templates"
              :key="template.id"
              :template="template"
              :can-create="isAdmin"
              @use="openTemplate"
            />
          </div>
          <p v-if="!isAdmin" class="mt-4 text-sm text-n-slate-11">
            {{ t('MONITORS.TEMPLATES.ADMIN_HELP') }}
          </p>
        </section>
        <div v-else-if="isPending && !loaded" class="flex justify-center py-20">
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
        <MonitorsEmptyState
          v-else-if="!meta.total_count"
          :template="refundTemplate"
          @create="openTemplate"
          @browse="selectSection('templates')"
        />
        <div
          v-else
          class="flex flex-col divide-y divide-n-weak border-t border-n-weak"
          :class="{ 'pointer-events-none opacity-50': isChangingPage }"
        >
          <MonitorListItem
            v-for="monitor in monitors"
            :key="monitor.id"
            :monitor="monitor"
            :show-actions="isAdmin"
            @action="action => actionDialog.open(action, monitor)"
          />
        </div>
      </div>
    </main>
    <footer
      v-if="
        activeSection === 'monitors' &&
        !hasError &&
        meta.total_count > PAGE_SIZE
      "
      class="sticky bottom-0 z-10"
    >
      <PaginationFooter
        v-model:current-page="page"
        current-page-info="MONITORS.LIST.PAGINATION"
        :total-items="meta.total_count"
        :items-per-page="PAGE_SIZE"
        class="max-w-[67rem]"
      />
      <Spinner
        v-if="isChangingPage"
        class="absolute inset-0 m-auto text-n-slate-11"
      />
    </footer>
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
  </section>
</template>
