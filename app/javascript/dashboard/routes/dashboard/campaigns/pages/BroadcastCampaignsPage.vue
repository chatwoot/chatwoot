<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  useStore,
  useStoreGetters,
  useMapGetter,
} from 'dashboard/composables/store';
import {
  BROADCAST_CHANNELS,
  BROADCAST_STATUS,
  getBroadcastChannel,
  getBroadcastStatus,
} from 'dashboard/helper/campaignHelper';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import BroadcastDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/Broadcast/BroadcastDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import BroadcastCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/BroadcastCampaignEmptyState.vue';

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();

const ALL = 'all';

const broadcastDialogRef = ref(null);
const confirmDeleteCampaignDialogRef = ref(null);
const selectedCampaign = ref(null);
const dialogMode = ref('create');
const activeChannel = ref(ALL);
const activeStatus = ref(ALL);

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);

const broadcastCampaigns = computed(
  () => getters['campaigns/getBroadcastCampaigns'].value
);

const channelFilters = computed(() => [
  { key: ALL, label: t('CAMPAIGN.BROADCAST.FILTER.CHANNEL.ALL') },
  { key: BROADCAST_CHANNELS.SMS, label: t('CAMPAIGN.CHANNEL.SMS') },
  { key: BROADCAST_CHANNELS.WHATSAPP, label: t('CAMPAIGN.CHANNEL.WHATSAPP') },
]);

const statusFilters = computed(() => [
  { key: ALL, label: t('CAMPAIGN.BROADCAST.FILTER.STATUS.ALL') },
  {
    key: BROADCAST_STATUS.SCHEDULED,
    label: t('CAMPAIGN.BROADCAST.CARD.STATUS.SCHEDULED'),
  },
  {
    key: BROADCAST_STATUS.PROCESSING,
    label: t('CAMPAIGN.BROADCAST.CARD.STATUS.PROCESSING'),
  },
  {
    key: BROADCAST_STATUS.COMPLETED,
    label: t('CAMPAIGN.BROADCAST.CARD.STATUS.COMPLETED'),
  },
]);

const activeChannelIndex = computed(() =>
  channelFilters.value.findIndex(filter => filter.key === activeChannel.value)
);

const activeStatusIndex = computed(() =>
  statusFilters.value.findIndex(filter => filter.key === activeStatus.value)
);

const filteredCampaigns = computed(() =>
  broadcastCampaigns.value.filter(campaign => {
    const matchesChannel =
      activeChannel.value === ALL ||
      getBroadcastChannel(campaign.inbox) === activeChannel.value;
    const matchesStatus =
      activeStatus.value === ALL ||
      getBroadcastStatus(campaign) === activeStatus.value;

    return matchesChannel && matchesStatus;
  })
);

const hasNoBroadcastCampaigns = computed(
  () => broadcastCampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const handleCreate = () => {
  selectedCampaign.value = null;
  dialogMode.value = 'create';
  broadcastDialogRef.value.dialogRef.open();
};

const handleEdit = campaign => {
  selectedCampaign.value = campaign;
  dialogMode.value = 'edit';
  broadcastDialogRef.value.dialogRef.open();
};

const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};

onMounted(() => store.dispatch('campaignTemplates/get'));
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.BROADCAST.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.BROADCAST.NEW_CAMPAIGN')"
    @click="handleCreate"
  >
    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <template v-else-if="!hasNoBroadcastCampaigns">
      <div class="flex flex-wrap items-center gap-3 pb-4">
        <TabBar
          :tabs="channelFilters"
          :initial-active-tab="activeChannelIndex"
          @tab-changed="activeChannel = $event.key"
        />
        <TabBar
          :tabs="statusFilters"
          :initial-active-tab="activeStatusIndex"
          @tab-changed="activeStatus = $event.key"
        />
      </div>
      <p
        v-if="filteredCampaigns.length === 0"
        class="py-10 mb-0 text-sm text-center text-n-slate-11"
      >
        {{ t('CAMPAIGN.BROADCAST.FILTER.NO_RESULTS') }}
      </p>
      <CampaignList
        v-else
        :campaigns="filteredCampaigns"
        @edit="handleEdit"
        @delete="handleDelete"
      />
    </template>
    <BroadcastCampaignEmptyState
      v-else
      :title="t('CAMPAIGN.BROADCAST.EMPTY_STATE.TITLE')"
      :subtitle="t('CAMPAIGN.BROADCAST.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />
    <BroadcastDialog
      ref="broadcastDialogRef"
      :mode="dialogMode"
      :selected-campaign="selectedCampaign"
    />
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>
</template>
