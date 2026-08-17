<script setup>
import { computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { messageStamp } from 'shared/helpers/timeHelper';
import CampaignsAPI from 'dashboard/api/campaigns';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import CampaignAnalyticsLayout from 'dashboard/components-next/Campaigns/CampaignAnalyticsLayout.vue';
import CampaignMetricCard from 'dashboard/components-next/Campaigns/Pages/CampaignAnalyticsPage/CampaignMetricCard.vue';
import CampaignDeliveryBreakdown from 'dashboard/components-next/Campaigns/Pages/CampaignAnalyticsPage/CampaignDeliveryBreakdown.vue';
import CampaignDeliveryTable from 'dashboard/components-next/Campaigns/Pages/CampaignAnalyticsPage/CampaignDeliveryTable.vue';

const DELIVERIES_PER_PAGE = 25;
const CAMPAIGN_STATUS_PROCESSING = 'processing';
const STATUS_FILTERS = [
  'all',
  'sent',
  'delivered',
  'read',
  'failed',
  'skipped',
];

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const state = reactive({
  metrics: null,
  deliveries: [],
  meta: {},
  status: 'all',
  page: 1,
  isFetchingMetrics: true,
  isFetchingDeliveries: true,
});

const campaigns = useMapGetter('campaigns/getAllCampaigns');

const campaignId = computed(() => Number(route.params.campaignId));
const campaign = computed(() =>
  campaigns.value.find(record => Number(record.id) === campaignId.value)
);
const campaignTitle = computed(
  () => campaign.value?.title || `#${campaignId.value}`
);
const isCampaignProcessing = computed(
  () => campaign.value?.campaign_status === CAMPAIGN_STATUS_PROCESSING
);

const inboxIcon = computed(() => {
  const inbox = campaign.value?.inbox;
  if (!inbox) return '';

  return getInboxIconByType(
    inbox.channel_type,
    inbox.medium,
    'fill',
    inbox.voice_enabled
  );
});

const breadcrumbItems = computed(() => [
  { label: t('CAMPAIGN.WHATSAPP.ANALYTICS.BREADCRUMB.CAMPAIGNS') },
  { label: t('CAMPAIGN.WHATSAPP.ANALYTICS.BREADCRUMB.WHATSAPP') },
  { label: campaignTitle.value },
]);

const metricCount = key => Number(state.metrics?.[key] || 0);
const audience = computed(() => metricCount('audience'));
const analyticsEmptyState = computed(() => {
  if (state.isFetchingMetrics || audience.value > 0) return null;

  if (isCampaignProcessing.value) {
    return {
      icon: 'i-lucide-clock-3',
      title: t('CAMPAIGN.WHATSAPP.ANALYTICS.EMPTY_STATE.PENDING.TITLE'),
      description: t(
        'CAMPAIGN.WHATSAPP.ANALYTICS.EMPTY_STATE.PENDING.DESCRIPTION'
      ),
    };
  }

  return {
    icon: 'i-lucide-chart-no-axes-column',
    title: t('CAMPAIGN.WHATSAPP.ANALYTICS.EMPTY_STATE.UNAVAILABLE.TITLE'),
    description: t(
      'CAMPAIGN.WHATSAPP.ANALYTICS.EMPTY_STATE.UNAVAILABLE.DESCRIPTION'
    ),
  };
});

const metricRate = key => {
  if (!audience.value) return '';

  return t('CAMPAIGN.WHATSAPP.ANALYTICS.RATE', {
    value: Math.round((metricCount(key) / audience.value) * 100),
  });
};

const metrics = computed(() =>
  ['audience', 'sent', 'delivered', 'read', 'failed', 'skipped'].map(key => {
    const scope = `CAMPAIGN.WHATSAPP.ANALYTICS.METRICS.${key.toUpperCase()}`;

    return {
      key,
      label: t(`${scope}.LABEL`),
      hint: t(`${scope}.HINT`),
      value: metricCount(key),
      rate: key === 'audience' ? '' : metricRate(key),
    };
  })
);

const statusTabs = computed(() =>
  STATUS_FILTERS.map(key => ({
    key,
    label: t(
      key === 'all'
        ? 'CAMPAIGN.WHATSAPP.ANALYTICS.FILTERS.ALL'
        : `CAMPAIGN.WHATSAPP.ANALYTICS.STATUS.${key.toUpperCase()}`
    ),
    count:
      key === 'all'
        ? audience.value
        : Number(state.metrics?.status_counts?.[key] || 0),
  }))
);

const activeTabIndex = computed(() => STATUS_FILTERS.indexOf(state.status));

const totalDeliveries = computed(() => Number(state.meta.total_count || 0));

const noDataMessage = computed(() => {
  if (state.status === 'all') return t('CAMPAIGN.WHATSAPP.ANALYTICS.EMPTY');

  return t('CAMPAIGN.WHATSAPP.ANALYTICS.EMPTY_FILTER', {
    status: t(
      `CAMPAIGN.WHATSAPP.ANALYTICS.STATUS.${state.status.toUpperCase()}`
    ).toLowerCase(),
  });
});

const fetchMetrics = async () => {
  state.isFetchingMetrics = true;
  try {
    const { data } = await CampaignsAPI.analyticsMetrics(campaignId.value);
    state.metrics = data;
  } finally {
    state.isFetchingMetrics = false;
  }
};

const fetchDeliveries = async () => {
  state.isFetchingDeliveries = true;
  try {
    const { data } = await CampaignsAPI.analyticsContacts(campaignId.value, {
      status: state.status === 'all' ? undefined : state.status,
      page: state.page,
    });
    state.deliveries = data.payload;
    state.meta = data.meta;
  } finally {
    state.isFetchingDeliveries = false;
  }
};

const handleTabChange = tab => {
  if (tab.key === state.status) return;

  state.status = tab.key;
  state.page = 1;
};

const handlePageChange = page => {
  state.page = page;
};

const goToCampaigns = () => {
  router.push({ name: 'campaigns_whatsapp_index' });
};

// The page is kept alive by the campaigns route view, so the campaign id is the
// trigger for a full refresh rather than the mount hook.
watch(
  campaignId,
  id => {
    if (!Number.isFinite(id)) return;

    state.status = 'all';
    state.page = 1;
    fetchMetrics();
    fetchDeliveries();
  },
  { immediate: true }
);

watch(
  () => [state.status, state.page],
  () => fetchDeliveries()
);
</script>

<template>
  <CampaignAnalyticsLayout
    :breadcrumb-items="breadcrumbItems"
    @breadcrumb-click="goToCampaigns"
  >
    <div class="flex flex-col gap-6 pb-8">
      <Banner v-if="isCampaignProcessing" color="amber">
        <div class="flex items-start gap-3 text-start">
          <Icon
            icon="i-lucide-loader-circle"
            class="flex-shrink-0 mt-0.5 size-4 animate-spin"
          />
          <span>
            {{ t('CAMPAIGN.WHATSAPP.ANALYTICS.PROCESSING_BANNER') }}
          </span>
        </div>
      </Banner>

      <div
        v-if="campaign?.inbox"
        class="flex flex-wrap items-center text-sm gap-x-3 gap-y-2 text-n-slate-11"
      >
        <div class="flex items-center gap-1.5 min-w-0">
          <Icon :icon="inboxIcon" class="shrink-0 size-3.5 text-n-slate-12" />
          <span class="font-medium truncate text-n-slate-12">
            {{ campaign.inbox.name }}
          </span>
        </div>
        <span class="w-px h-3 rounded bg-n-strong" />
        <span class="whitespace-nowrap">
          {{
            t('CAMPAIGN.WHATSAPP.ANALYTICS.SENT_ON', {
              date: messageStamp(campaign.scheduled_at, 'LLL d, h:mm a'),
            })
          }}
        </span>
      </div>

      <div
        v-if="analyticsEmptyState"
        class="flex min-h-64 items-center justify-center rounded-xl border border-n-weak bg-n-solid-2 px-6 py-12 text-center"
      >
        <div class="flex max-w-md flex-col items-center gap-3">
          <div
            class="grid size-10 place-content-center rounded-full bg-n-alpha-2 text-n-slate-11"
          >
            <Icon :icon="analyticsEmptyState.icon" class="size-5" />
          </div>
          <div class="flex flex-col gap-1">
            <h3 class="text-base font-medium text-n-slate-12">
              {{ analyticsEmptyState.title }}
            </h3>
            <p class="text-sm text-n-slate-11">
              {{ analyticsEmptyState.description }}
            </p>
          </div>
        </div>
      </div>

      <div
        v-else
        class="grid grid-cols-1 gap-px overflow-hidden border rounded-xl sm:grid-cols-2 lg:grid-cols-3 bg-n-weak border-n-weak"
      >
        <CampaignMetricCard
          v-for="metric in metrics"
          :key="metric.key"
          :label="metric.label"
          :hint="metric.hint"
          :value="metric.value"
          :rate="metric.rate"
          :loading="state.isFetchingMetrics"
        />
      </div>

      <CampaignDeliveryBreakdown
        v-if="!analyticsEmptyState"
        :metrics="state.metrics ?? undefined"
        :loading="state.isFetchingMetrics"
      />

      <CampaignDeliveryTable
        v-if="!analyticsEmptyState"
        :deliveries="state.deliveries"
        :loading="state.isFetchingDeliveries"
        :no-data-message="noDataMessage"
      >
        <template #filters>
          <TabBar
            :tabs="statusTabs"
            :initial-active-tab="activeTabIndex"
            @tab-changed="handleTabChange"
          />
        </template>
        <template v-if="totalDeliveries > DELIVERIES_PER_PAGE" #footer>
          <PaginationFooter
            :current-page="state.page"
            :total-items="totalDeliveries"
            :items-per-page="DELIVERIES_PER_PAGE"
            current-page-info="CAMPAIGN.WHATSAPP.ANALYTICS.PAGE_INFO"
            class="!bg-transparent !px-5 rounded-b-xl before:hidden"
            @update:current-page="handlePageChange"
          />
        </template>
      </CampaignDeliveryTable>
    </div>
  </CampaignAnalyticsLayout>
</template>
