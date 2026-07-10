<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import QRCode from 'qrcode';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import EmailCampaignReportsAPI from 'dashboard/api/emailCampaignReports';
import CtwaTrackedLinksAPI from 'dashboard/api/ctwaTrackedLinks';
import LineChart from 'shared/components/charts/LineChart.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const { t } = useI18n();
const store = useStore();

const globalConfig = useMapGetter('globalConfig/get');
const whatsappInboxes = useMapGetter('inboxes/getWhatsAppInboxes');
const enabled = computed(
  () =>
    globalConfig.value?.emailCampaignEnabled === true &&
    globalConfig.value?.crmKanbanEnabled === true
);

const summary = ref(null);
const campaigns = ref([]);
const selectedCampaignId = ref('');
const isLoading = ref(false);
const hasError = ref(false);

const timeline = ref([]);
const timelineInterval = ref('day');
const clicks = ref([]);
const recipients = ref([]);
const recipientsMeta = ref({});
const recipientsPage = ref(1);
const recipientsSearch = ref('');

const trackedLinks = ref([]);
const trackedLinkForm = ref({
  name: '',
  inboxId: '',
  prefilledText: '',
});
const isTrackedLinksLoading = ref(false);
const isTrackedLinkCreating = ref(false);
const deletingTrackedLinkId = ref(null);
const copiedTrackedLinkId = ref(null);

const kpiCards = computed(() => {
  const s = summary.value || {};
  return [
    {
      key: 'SENT',
      label: t('CAMPAIGN_MANAGEMENT.KPIS.SENT'),
      icon: 'i-lucide-send',
      value: s.sent ?? 0,
      rate: null,
    },
    {
      key: 'DELIVERED',
      label: t('CAMPAIGN_MANAGEMENT.KPIS.DELIVERED'),
      icon: 'i-lucide-mail-check',
      value: s.delivered ?? 0,
      rate: null,
    },
    {
      key: 'OPENED',
      label: `${t('CAMPAIGN_MANAGEMENT.KPIS.OPENED')} (${t('CAMPAIGN_MANAGEMENT.APPROXIMATE')})`,
      icon: 'i-lucide-mail-open',
      value: s.opened ?? 0,
      rate: s.open_rate,
    },
    {
      key: 'CLICKED',
      label: t('CAMPAIGN_MANAGEMENT.KPIS.CLICKED'),
      icon: 'i-lucide-mouse-pointer-click',
      value: s.clicked ?? 0,
      rate: s.click_rate,
    },
    {
      key: 'UNSUBSCRIBED',
      label: t('CAMPAIGN_MANAGEMENT.KPIS.UNSUBSCRIBED'),
      icon: 'i-lucide-user-x',
      value: s.unsubscribed ?? 0,
      rate: s.unsubscribe_rate,
    },
    {
      key: 'BOUNCED',
      label: t('CAMPAIGN_MANAGEMENT.KPIS.BOUNCED'),
      icon: 'i-lucide-mail-x',
      value: s.bounced ?? 0,
      rate: s.bounce_rate,
    },
    {
      key: 'COMPLAINED',
      label: t('CAMPAIGN_MANAGEMENT.KPIS.COMPLAINED'),
      icon: 'i-lucide-octagon-alert',
      value: s.complained ?? 0,
      rate: s.complaint_rate,
    },
  ];
});

const rateLabel = rate =>
  `${rate}% ${t('CAMPAIGN_MANAGEMENT.RATES.OVER_DELIVERED')}`;

const hasCampaigns = computed(() => campaigns.value.length > 0);
const hasTrackedLinks = computed(() => trackedLinks.value.length > 0);
const canCreateTrackedLink = computed(
  () =>
    trackedLinkForm.value.name.trim().length > 0 &&
    Boolean(trackedLinkForm.value.inboxId)
);

const pct = (numerator, base) =>
  base ? `${(((numerator ?? 0) / base) * 100).toFixed(2)}%` : '—';

const comparisonRows = computed(() =>
  campaigns.value.map(c => ({
    id: c.id,
    name: c.name,
    status: c.status,
    sent: c.sent ?? 0,
    delivered: c.delivered ?? 0,
    openRate: pct(c.opened, c.delivered),
    clickRate: pct(c.clicked, c.delivered),
    bounceRate: pct(c.bounced, c.delivered),
    unsubscribeRate: pct(c.unsubscribed, c.delivered),
  }))
);

const formatDate = value => {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date);
};

const formatBucket = value => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  if (timelineInterval.value === 'hour') {
    return new Intl.DateTimeFormat(undefined, {
      day: '2-digit',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit',
    }).format(date);
  }
  return new Intl.DateTimeFormat(undefined, {
    day: '2-digit',
    month: 'short',
  }).format(date);
};

const timelineCollection = computed(() => ({
  labels: timeline.value.map(bucket => formatBucket(bucket.bucket)),
  datasets: [
    {
      label: t('CAMPAIGN_MANAGEMENT.KPIS.DELIVERED'),
      data: timeline.value.map(bucket => bucket.delivered ?? 0),
      borderColor: '#16a34a',
      backgroundColor: '#16a34a',
      tension: 0.2,
    },
    {
      label: `${t('CAMPAIGN_MANAGEMENT.KPIS.OPENED')} (${t('CAMPAIGN_MANAGEMENT.APPROXIMATE')})`,
      data: timeline.value.map(bucket => bucket.open ?? 0),
      borderColor: '#2563eb',
      backgroundColor: '#2563eb',
      tension: 0.2,
    },
    {
      label: t('CAMPAIGN_MANAGEMENT.KPIS.CLICKED'),
      data: timeline.value.map(bucket => bucket.click ?? 0),
      borderColor: '#7c3aed',
      backgroundColor: '#7c3aed',
      tension: 0.2,
    },
  ],
}));

const fetchReports = async () => {
  if (!enabled.value) return;
  isLoading.value = true;
  hasError.value = false;
  try {
    const { data } = await EmailCampaignReportsAPI.getReports(
      selectedCampaignId.value
    );
    summary.value = data.payload.summary;
    campaigns.value = data.payload.campaigns || [];
  } catch (error) {
    hasError.value = true;
    summary.value = null;
    campaigns.value = [];
  } finally {
    isLoading.value = false;
  }
};

const fetchTimeline = async () => {
  try {
    const { data } = await EmailCampaignReportsAPI.getTimeline(
      selectedCampaignId.value,
      timelineInterval.value
    );
    timeline.value = data.payload.series || [];
  } catch (error) {
    timeline.value = [];
  }
};

const fetchClicks = async () => {
  try {
    const { data } = await EmailCampaignReportsAPI.getClicks(
      selectedCampaignId.value
    );
    clicks.value = data.payload.clicks || [];
  } catch (error) {
    clicks.value = [];
  }
};

const fetchRecipients = async () => {
  try {
    const { data } = await EmailCampaignReportsAPI.getRecipients(
      selectedCampaignId.value,
      { page: recipientsPage.value, search: recipientsSearch.value }
    );
    recipients.value = data.payload.recipients || [];
    recipientsMeta.value = data.payload.meta || {};
  } catch (error) {
    recipients.value = [];
    recipientsMeta.value = {};
  }
};

const fetchCampaignDrilldown = async () => {
  if (!selectedCampaignId.value) {
    timeline.value = [];
    clicks.value = [];
    recipients.value = [];
    recipientsMeta.value = {};
    return;
  }
  await Promise.all([fetchTimeline(), fetchClicks(), fetchRecipients()]);
};

const onFilterChange = async () => {
  recipientsPage.value = 1;
  recipientsSearch.value = '';
  await Promise.all([fetchReports(), fetchCampaignDrilldown()]);
};

const intervalOptions = computed(() => [
  { id: 'day', label: t('CAMPAIGN_MANAGEMENT.TIMELINE.INTERVAL.DAY') },
  { id: 'hour', label: t('CAMPAIGN_MANAGEMENT.TIMELINE.INTERVAL.HOUR') },
]);

const openRateApproxHeader = computed(
  () =>
    `${t('CAMPAIGN_MANAGEMENT.RATES.OPEN_RATE')} (${t('CAMPAIGN_MANAGEMENT.APPROXIMATE')})`
);

const setTimelineInterval = async interval => {
  timelineInterval.value = interval;
  await fetchTimeline();
};

const searchRecipients = async () => {
  recipientsPage.value = 1;
  await fetchRecipients();
};

const RECIPIENTS_PER_PAGE = 50;
const totalPages = computed(
  () => Math.ceil((recipientsMeta.value.count || 0) / RECIPIENTS_PER_PAGE) || 1
);
const currentPage = computed(
  () => recipientsMeta.value.current_page || recipientsPage.value
);

const goToPage = async page => {
  recipientsPage.value = page;
  await fetchRecipients();
};

const exportCsv = async () => {
  const { data } = await EmailCampaignReportsAPI.export(
    selectedCampaignId.value
  );
  const url = URL.createObjectURL(data);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute(
    'download',
    `email-campaign-${selectedCampaignId.value}-report.csv`
  );
  link.click();
  URL.revokeObjectURL(url);
};

const resetTrackedLinkForm = () => {
  trackedLinkForm.value = {
    name: '',
    inboxId: '',
    prefilledText: '',
  };
};

const fetchTrackedLinks = async () => {
  isTrackedLinksLoading.value = true;
  try {
    const { data } = await CtwaTrackedLinksAPI.get();
    trackedLinks.value = data.payload || [];
  } catch (error) {
    trackedLinks.value = [];
    useAlert(t('CRM_KANBAN.TRACKED_LINKS.CREATE_ERROR'));
  } finally {
    isTrackedLinksLoading.value = false;
  }
};

const createTrackedLink = async () => {
  if (!canCreateTrackedLink.value || isTrackedLinkCreating.value) return;

  isTrackedLinkCreating.value = true;
  try {
    await CtwaTrackedLinksAPI.create({
      name: trackedLinkForm.value.name.trim(),
      inbox_id: Number(trackedLinkForm.value.inboxId),
      prefilled_text: trackedLinkForm.value.prefilledText.trim(),
    });
    resetTrackedLinkForm();
    await fetchTrackedLinks();
    useAlert(t('CRM_KANBAN.TRACKED_LINKS.CREATE_SUCCESS'));
  } catch (error) {
    useAlert(t('CRM_KANBAN.TRACKED_LINKS.CREATE_ERROR'));
  } finally {
    isTrackedLinkCreating.value = false;
  }
};

const copyTrackedLink = async link => {
  if (!link.short_url) return;

  try {
    await navigator.clipboard.writeText(link.short_url);
    copiedTrackedLinkId.value = link.id;
    useAlert(t('CRM_KANBAN.TRACKED_LINKS.COPIED'));
    window.setTimeout(() => {
      if (copiedTrackedLinkId.value === link.id) {
        copiedTrackedLinkId.value = null;
      }
    }, 2000);
  } catch (error) {
    useAlert(t('CRM_KANBAN.TRACKED_LINKS.CREATE_ERROR'));
  }
};

const downloadTrackedLinkQr = async link => {
  if (!link.wa_link) return;

  try {
    const qrDataUrl = await QRCode.toDataURL(link.wa_link, { width: 512 });
    const anchor = document.createElement('a');
    anchor.href = qrDataUrl;
    anchor.download = `${link.code || 'ctwa-link'}-qr.png`;
    anchor.click();
  } catch (error) {
    useAlert(t('CRM_KANBAN.TRACKED_LINKS.CREATE_ERROR'));
  }
};

const deleteTrackedLink = async link => {
  // eslint-disable-next-line no-alert
  if (!window.confirm(t('CRM_KANBAN.TRACKED_LINKS.DELETE_CONFIRM'))) return;

  deletingTrackedLinkId.value = link.id;
  try {
    await CtwaTrackedLinksAPI.delete(link.id);
    trackedLinks.value = trackedLinks.value.filter(item => item.id !== link.id);
  } catch (error) {
    useAlert(t('CRM_KANBAN.TRACKED_LINKS.CREATE_ERROR'));
  } finally {
    deletingTrackedLinkId.value = null;
  }
};

onMounted(() => {
  if (!enabled.value) return;

  fetchReports();
  fetchTrackedLinks();
  store.dispatch('inboxes/get');
});
</script>

<template>
  <div class="flex flex-col w-full h-full overflow-auto bg-n-background">
    <header class="px-6 py-5 border-b border-n-weak">
      <div class="min-w-0">
        <h1 class="mb-1 text-xl font-semibold text-n-slate-12">
          {{ t('CAMPAIGN_MANAGEMENT.HEADER.TITLE') }}
        </h1>
        <p class="m-0 text-sm text-n-slate-11">
          {{ t('CAMPAIGN_MANAGEMENT.HEADER.DESCRIPTION') }}
        </p>
      </div>
    </header>

    <div
      v-if="!enabled"
      class="flex flex-col items-center justify-center flex-1 gap-3 p-8 text-center"
    >
      <span class="i-lucide-lock size-8 text-n-slate-10" />
      <h2 class="m-0 text-lg font-medium text-n-slate-12">
        {{ t('CAMPAIGN_MANAGEMENT.PAYWALL.TITLE') }}
      </h2>
      <p class="max-w-md m-0 text-sm text-n-slate-11">
        {{ t('CAMPAIGN_MANAGEMENT.PAYWALL.DESCRIPTION') }}
      </p>
    </div>

    <div v-else class="flex flex-col gap-6 p-6">
      <section
        class="flex flex-col gap-1 p-5 border rounded-xl border-n-weak bg-n-solid-1"
      >
        <span class="text-xs font-medium text-n-slate-11">
          {{ t('CAMPAIGN_MANAGEMENT.FILTER.LABEL') }}
        </span>
        <div class="flex flex-wrap items-center gap-3">
          <select
            v-model="selectedCampaignId"
            class="px-3 h-9 text-sm border rounded-lg outline-none border-n-weak bg-n-alpha-black1 text-n-slate-12 min-w-60"
            @change="onFilterChange"
          >
            <option value="">
              {{ t('CAMPAIGN_MANAGEMENT.FILTER.ALL') }}
            </option>
            <option
              v-for="campaign in campaigns"
              :key="campaign.id"
              :value="campaign.id"
            >
              {{ campaign.name }}
            </option>
          </select>
          <button
            v-if="selectedCampaignId"
            class="flex items-center gap-2 px-3 h-9 text-sm font-medium border rounded-lg border-n-weak bg-n-alpha-black1 text-n-slate-12 hover:bg-n-alpha-2"
            @click="exportCsv"
          >
            <span class="i-lucide-download size-4" />
            {{ t('CAMPAIGN_MANAGEMENT.EXPORT_CSV') }}
          </button>
        </div>
      </section>

      <section
        class="flex flex-col gap-5 p-5 border rounded-xl border-n-weak bg-n-solid-1"
      >
        <div class="flex flex-col gap-1">
          <h2 class="m-0 text-base font-semibold text-n-slate-12">
            {{ t('CRM_KANBAN.TRACKED_LINKS.TITLE') }}
          </h2>
          <p class="m-0 text-sm text-n-slate-11">
            {{ t('CRM_KANBAN.TRACKED_LINKS.SUBTITLE') }}
          </p>
        </div>

        <form
          class="grid grid-cols-1 gap-3 lg:grid-cols-[minmax(0,1fr)_minmax(12rem,16rem)_minmax(0,1.5fr)_auto]"
          @submit.prevent="createTrackedLink"
        >
          <Input
            v-model="trackedLinkForm.name"
            :label="t('CRM_KANBAN.TRACKED_LINKS.NAME')"
            :placeholder="t('CRM_KANBAN.TRACKED_LINKS.NAME_PLACEHOLDER')"
          />

          <label class="flex flex-col min-w-0 gap-1">
            <span class="mb-0.5 text-heading-3 text-n-slate-12">
              {{ t('CRM_KANBAN.TRACKED_LINKS.INBOX') }}
            </span>
            <select
              v-model="trackedLinkForm.inboxId"
              class="w-full px-3 h-10 text-sm border rounded-lg outline-none border-n-weak bg-n-alpha-black1 text-n-slate-12"
            >
              <option value="">
                {{ t('CRM_KANBAN.TRACKED_LINKS.INBOX') }}
              </option>
              <option
                v-for="inbox in whatsappInboxes"
                :key="inbox.id"
                :value="inbox.id"
              >
                {{ inbox.name }}
              </option>
            </select>
          </label>

          <Input
            v-model="trackedLinkForm.prefilledText"
            :label="t('CRM_KANBAN.TRACKED_LINKS.PREFILLED')"
            :placeholder="t('CRM_KANBAN.TRACKED_LINKS.PREFILLED_PLACEHOLDER')"
          />

          <div class="flex items-end">
            <Button
              :label="t('CRM_KANBAN.TRACKED_LINKS.ADD')"
              icon="i-lucide-plus"
              type="submit"
              class="w-full lg:w-auto"
              :disabled="!canCreateTrackedLink || isTrackedLinkCreating"
              :is-loading="isTrackedLinkCreating"
            />
          </div>
        </form>

        <div
          v-if="isTrackedLinksLoading"
          class="flex items-center justify-center py-10 text-sm text-n-slate-11"
        >
          <span class="i-lucide-loader-2 size-5 animate-spin" />
        </div>

        <div
          v-else-if="!hasTrackedLinks"
          class="py-8 text-sm text-center border rounded-lg border-n-weak bg-n-alpha-black1 text-n-slate-11"
        >
          {{ t('CRM_KANBAN.TRACKED_LINKS.EMPTY') }}
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full text-sm border-collapse">
            <thead>
              <tr class="text-left border-b border-n-weak text-n-slate-11">
                <th class="py-2 pr-3 text-xs font-medium">
                  {{ t('CRM_KANBAN.TRACKED_LINKS.NAME') }}
                </th>
                <th class="py-2 pr-3 text-xs font-medium">
                  {{ t('CRM_KANBAN.TRACKED_LINKS.CODE') }}
                </th>
                <th class="py-2 pr-3 text-xs font-medium text-right">
                  {{ t('CRM_KANBAN.TRACKED_LINKS.CLICKS') }}
                </th>
                <th class="py-2 pr-3 text-xs font-medium text-right">
                  {{ t('CRM_KANBAN.TRACKED_LINKS.CONVERSATIONS') }}
                </th>
                <th class="py-2 text-xs font-medium text-right">
                  {{ t('CRM_KANBAN.TRACKED_LINKS.COPY_LINK') }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="link in trackedLinks"
                :key="link.id"
                class="border-b border-n-weak last:border-b-0"
              >
                <td class="max-w-xs py-3 pr-3">
                  <span class="block truncate text-n-slate-12">
                    {{ link.name }}
                  </span>
                  <span
                    v-if="link.prefilled_text"
                    class="block truncate text-xs text-n-slate-10"
                  >
                    {{ link.prefilled_text }}
                  </span>
                </td>
                <td class="py-3 pr-3 font-mono text-xs text-n-slate-11">
                  {{ link.code }}
                </td>
                <td class="py-3 pr-3 text-right text-n-slate-12">
                  {{ link.clicks_count ?? 0 }}
                </td>
                <td class="py-3 pr-3 text-right text-n-slate-12">
                  {{ link.conversations_count ?? 0 }}
                </td>
                <td class="py-3">
                  <div class="flex flex-wrap justify-end gap-2">
                    <Button
                      :label="
                        copiedTrackedLinkId === link.id
                          ? t('CRM_KANBAN.TRACKED_LINKS.COPIED')
                          : t('CRM_KANBAN.TRACKED_LINKS.COPY_LINK')
                      "
                      icon="i-lucide-copy"
                      slate
                      outline
                      sm
                      type="button"
                      :disabled="!link.short_url"
                      @click="copyTrackedLink(link)"
                    />
                    <Button
                      :label="t('CRM_KANBAN.TRACKED_LINKS.DOWNLOAD_QR')"
                      icon="i-lucide-qr-code"
                      slate
                      outline
                      sm
                      type="button"
                      :disabled="!link.wa_link"
                      @click="downloadTrackedLinkQr(link)"
                    />
                    <Button
                      :label="t('CRM_KANBAN.TRACKED_LINKS.DELETE')"
                      icon="i-lucide-trash-2"
                      ruby
                      ghost
                      sm
                      type="button"
                      :disabled="deletingTrackedLinkId === link.id"
                      :is-loading="deletingTrackedLinkId === link.id"
                      @click="deleteTrackedLink(link)"
                    />
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <p v-if="hasError" class="m-0 text-sm text-n-ruby-11">
        {{ t('CAMPAIGN_MANAGEMENT.ERROR') }}
      </p>

      <div
        v-else-if="!isLoading && !hasCampaigns"
        class="flex flex-col items-center justify-center gap-2 p-10 text-center border rounded-xl border-n-weak bg-n-solid-1"
      >
        <span class="i-lucide-inbox size-8 text-n-slate-10" />
        <h2 class="m-0 text-base font-medium text-n-slate-12">
          {{ t('CAMPAIGN_MANAGEMENT.EMPTY_STATE.TITLE') }}
        </h2>
        <p class="max-w-md m-0 text-sm text-n-slate-11">
          {{ t('CAMPAIGN_MANAGEMENT.EMPTY_STATE.SUBTITLE') }}
        </p>
      </div>

      <template v-else>
        <section class="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-4">
          <div
            v-for="card in kpiCards"
            :key="card.key"
            class="flex flex-col gap-2 p-4 border rounded-xl border-n-weak bg-n-solid-1"
          >
            <div class="flex items-center gap-2 text-n-slate-11">
              <span :class="card.icon" class="size-4" />
              <span class="text-xs font-medium">{{ card.label }}</span>
            </div>
            <span class="text-2xl font-semibold text-n-slate-12">
              {{ card.value }}
            </span>
            <span
              v-if="card.rate !== null && card.rate !== undefined"
              class="text-xs text-n-slate-11"
            >
              {{ rateLabel(card.rate) }}
            </span>
          </div>
        </section>

        <p class="flex items-start gap-2 m-0 text-xs text-n-slate-11">
          <span class="i-lucide-info size-4 shrink-0" />
          {{ t('CAMPAIGN_MANAGEMENT.OPEN_APPROXIMATE_HINT') }}
        </p>

        <template v-if="selectedCampaignId">
          <section
            class="flex flex-col gap-3 p-5 border rounded-xl border-n-weak bg-n-solid-1"
          >
            <div class="flex items-center justify-between gap-3">
              <h3 class="m-0 text-sm font-semibold text-n-slate-12">
                {{ t('CAMPAIGN_MANAGEMENT.TIMELINE.TITLE') }}
              </h3>
              <div class="flex gap-1">
                <button
                  v-for="option in intervalOptions"
                  :key="option.id"
                  class="px-2 py-1 text-xs font-medium border rounded-lg border-n-weak"
                  :class="
                    timelineInterval === option.id
                      ? 'bg-n-alpha-2 text-n-slate-12'
                      : 'bg-n-alpha-black1 text-n-slate-11'
                  "
                  @click="setTimelineInterval(option.id)"
                >
                  {{ option.label }}
                </button>
              </div>
            </div>
            <p v-if="!timeline.length" class="m-0 text-sm text-n-slate-11">
              {{ t('CAMPAIGN_MANAGEMENT.TIMELINE.EMPTY') }}
            </p>
            <div v-else class="h-64">
              <LineChart :collection="timelineCollection" />
            </div>
          </section>

          <section
            class="flex flex-col gap-3 p-5 border rounded-xl border-n-weak bg-n-solid-1"
          >
            <h3 class="m-0 text-sm font-semibold text-n-slate-12">
              {{ t('CAMPAIGN_MANAGEMENT.CLICKS_BY_LINK.TITLE') }}
            </h3>
            <p v-if="!clicks.length" class="m-0 text-sm text-n-slate-11">
              {{ t('CAMPAIGN_MANAGEMENT.CLICKS_BY_LINK.EMPTY') }}
            </p>
            <table v-else class="w-full text-sm border-collapse">
              <thead>
                <tr class="text-left border-b border-n-weak text-n-slate-11">
                  <th class="py-2 pr-3 text-xs font-medium">
                    {{ t('CAMPAIGN_MANAGEMENT.CLICKS_BY_LINK.URL') }}
                  </th>
                  <th class="py-2 pr-3 text-xs font-medium text-right">
                    {{ t('CAMPAIGN_MANAGEMENT.CLICKS_BY_LINK.UNIQUE') }}
                  </th>
                  <th class="py-2 text-xs font-medium text-right">
                    {{ t('CAMPAIGN_MANAGEMENT.CLICKS_BY_LINK.TOTAL') }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="click in clicks"
                  :key="click.url"
                  class="border-b border-n-weak last:border-b-0"
                >
                  <td class="max-w-md py-2 pr-3 truncate text-n-slate-12">
                    {{ click.url }}
                  </td>
                  <td class="py-2 pr-3 text-right text-n-slate-12">
                    {{ click.unique_clicks }}
                  </td>
                  <td class="py-2 text-right text-n-slate-12">
                    {{ click.total_clicks }}
                  </td>
                </tr>
              </tbody>
            </table>
          </section>

          <section
            class="flex flex-col gap-3 p-5 border rounded-xl border-n-weak bg-n-solid-1"
          >
            <div class="flex flex-wrap items-center justify-between gap-3">
              <h3 class="m-0 text-sm font-semibold text-n-slate-12">
                {{ t('CAMPAIGN_MANAGEMENT.RECIPIENTS.TITLE') }}
              </h3>
              <div class="flex items-center gap-2">
                <input
                  v-model="recipientsSearch"
                  type="text"
                  class="px-3 py-1.5 text-sm border rounded-lg outline-none border-n-weak bg-n-alpha-black1 text-n-slate-12 min-w-56"
                  :placeholder="
                    t('CAMPAIGN_MANAGEMENT.RECIPIENTS.SEARCH_PLACEHOLDER')
                  "
                  @keyup.enter="searchRecipients"
                />
                <button
                  class="flex items-center gap-1 px-3 py-1.5 text-sm font-medium border rounded-lg border-n-weak bg-n-alpha-black1 text-n-slate-12 hover:bg-n-alpha-2"
                  @click="searchRecipients"
                >
                  <span class="i-lucide-search size-4" />
                </button>
              </div>
            </div>
            <p v-if="!recipients.length" class="m-0 text-sm text-n-slate-11">
              {{ t('CAMPAIGN_MANAGEMENT.RECIPIENTS.EMPTY') }}
            </p>
            <template v-else>
              <table class="w-full text-sm border-collapse">
                <thead>
                  <tr class="text-left border-b border-n-weak text-n-slate-11">
                    <th class="py-2 pr-3 text-xs font-medium">
                      {{ t('CAMPAIGN_MANAGEMENT.TABLE.EMAIL') }}
                    </th>
                    <th class="py-2 pr-3 text-xs font-medium">
                      {{ t('CAMPAIGN_MANAGEMENT.TABLE.NAME') }}
                    </th>
                    <th class="py-2 pr-3 text-xs font-medium">
                      {{ t('CAMPAIGN_MANAGEMENT.TABLE.STATUS') }}
                    </th>
                    <th class="py-2 pr-3 text-xs font-medium text-right">
                      {{ t('CAMPAIGN_MANAGEMENT.TABLE.ATTEMPTS') }}
                    </th>
                    <th class="py-2 pr-3 text-xs font-medium text-right">
                      {{ t('CAMPAIGN_MANAGEMENT.TABLE.OPENS') }}
                    </th>
                    <th class="py-2 pr-3 text-xs font-medium text-right">
                      {{ t('CAMPAIGN_MANAGEMENT.TABLE.CLICKS') }}
                    </th>
                    <th class="py-2 text-xs font-medium">
                      {{ t('CAMPAIGN_MANAGEMENT.TABLE.LAST_EVENT_AT') }}
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="recipient in recipients"
                    :key="recipient.id"
                    class="border-b border-n-weak last:border-b-0"
                  >
                    <td class="max-w-xs py-2 pr-3 truncate text-n-slate-12">
                      {{ recipient.email }}
                    </td>
                    <td class="max-w-xs py-2 pr-3 truncate text-n-slate-11">
                      {{ recipient.name || '—' }}
                    </td>
                    <td class="py-2 pr-3 text-n-slate-12">
                      {{ recipient.status }}
                    </td>
                    <td class="py-2 pr-3 text-right text-n-slate-12">
                      {{ recipient.attempts }}
                    </td>
                    <td class="py-2 pr-3 text-right text-n-slate-12">
                      {{ recipient.opens }}
                    </td>
                    <td class="py-2 pr-3 text-right text-n-slate-12">
                      {{ recipient.clicks }}
                    </td>
                    <td class="py-2 whitespace-nowrap text-n-slate-10">
                      {{ formatDate(recipient.last_event_at) }}
                    </td>
                  </tr>
                </tbody>
              </table>
              <div class="flex items-center justify-end gap-3 text-xs">
                <span class="text-n-slate-11">
                  {{
                    t('CAMPAIGN_MANAGEMENT.RECIPIENTS.PAGE_OF', {
                      page: currentPage,
                      total: totalPages,
                    })
                  }}
                </span>
                <button
                  class="px-2 py-1 font-medium border rounded-lg border-n-weak bg-n-alpha-black1 text-n-slate-12 disabled:opacity-50"
                  :disabled="currentPage <= 1"
                  @click="goToPage(currentPage - 1)"
                >
                  {{ t('CAMPAIGN_MANAGEMENT.RECIPIENTS.PREV') }}
                </button>
                <button
                  class="px-2 py-1 font-medium border rounded-lg border-n-weak bg-n-alpha-black1 text-n-slate-12 disabled:opacity-50"
                  :disabled="currentPage >= totalPages"
                  @click="goToPage(currentPage + 1)"
                >
                  {{ t('CAMPAIGN_MANAGEMENT.RECIPIENTS.NEXT') }}
                </button>
              </div>
            </template>
          </section>
        </template>

        <section
          class="flex flex-col gap-3 p-5 border rounded-xl border-n-weak bg-n-solid-1"
        >
          <h3 class="m-0 text-sm font-semibold text-n-slate-12">
            {{ t('CAMPAIGN_MANAGEMENT.COMPARISON.TITLE') }}
          </h3>
          <table class="w-full text-sm border-collapse">
            <thead>
              <tr class="text-left border-b border-n-weak text-n-slate-11">
                <th class="py-2 pr-3 text-xs font-medium">
                  {{ t('CAMPAIGN_MANAGEMENT.TABLE.NAME') }}
                </th>
                <th class="py-2 pr-3 text-xs font-medium">
                  {{ t('CAMPAIGN_MANAGEMENT.TABLE.STATUS') }}
                </th>
                <th class="py-2 pr-3 text-xs font-medium text-right">
                  {{ t('CAMPAIGN_MANAGEMENT.KPIS.SENT') }}
                </th>
                <th class="py-2 pr-3 text-xs font-medium text-right">
                  {{ t('CAMPAIGN_MANAGEMENT.KPIS.DELIVERED') }}
                </th>
                <th class="py-2 pr-3 text-xs font-medium text-right">
                  {{ openRateApproxHeader }}
                </th>
                <th class="py-2 pr-3 text-xs font-medium text-right">
                  {{ t('CAMPAIGN_MANAGEMENT.RATES.CLICK_RATE') }}
                </th>
                <th class="py-2 pr-3 text-xs font-medium text-right">
                  {{ t('CAMPAIGN_MANAGEMENT.RATES.BOUNCE_RATE') }}
                </th>
                <th class="py-2 text-xs font-medium text-right">
                  {{ t('CAMPAIGN_MANAGEMENT.RATES.UNSUBSCRIBE_RATE') }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="row in comparisonRows"
                :key="row.id"
                class="border-b border-n-weak last:border-b-0"
              >
                <td class="max-w-xs py-2 pr-3 truncate text-n-slate-12">
                  {{ row.name }}
                </td>
                <td class="py-2 pr-3 text-n-slate-11">{{ row.status }}</td>
                <td class="py-2 pr-3 text-right text-n-slate-12">
                  {{ row.sent }}
                </td>
                <td class="py-2 pr-3 text-right text-n-slate-12">
                  {{ row.delivered }}
                </td>
                <td class="py-2 pr-3 text-right text-n-slate-12">
                  {{ row.openRate }}
                </td>
                <td class="py-2 pr-3 text-right text-n-slate-12">
                  {{ row.clickRate }}
                </td>
                <td class="py-2 pr-3 text-right text-n-slate-12">
                  {{ row.bounceRate }}
                </td>
                <td class="py-2 text-right text-n-slate-12">
                  {{ row.unsubscribeRate }}
                </td>
              </tr>
            </tbody>
          </table>
        </section>
      </template>
    </div>
  </div>
</template>
