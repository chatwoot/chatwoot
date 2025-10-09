<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { useStore } from 'vuex';

import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import MarketingCampaignDialog from '../../../../components-next/Campaigns/Pages/CampaignPage/Marketing/MarketingCampaignDialog.vue';
import MarketingCampaignList from '../../../../components-next/Campaigns/Pages/CampaignPage/Marketing/MarketingCampaignList.vue';
import EditMarketingCampaignDialog from '../../../../components-next/Campaigns/Pages/CampaignPage/Marketing/EditMarketingCampaignDialog.vue';
import LiveChatCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/LiveChatCampaignEmptyState.vue';

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();

onMounted(async () => {
  await store.dispatch('marketingCampaigns/get');
});

const editLiveChatCampaignDialogRef = ref(null);
const confirmDeleteCampaignDialogRef = ref(null);
const selectedCampaign = ref(null);

const uiFlags = useMapGetter('marketingCampaigns/getUIFlags');

const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);
const [showMarketingCampaignDialog, toggleMarketingCampaignDialog] =
  useToggle();

const marketingCampaigns = computed(
  () => getters['marketingCampaigns/getMarketingCampaigns'].value
);

const hasNoMarketingCampaigns = computed(
  () => marketingCampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const handleEdit = campaign => {
  selectedCampaign.value = campaign;
  editLiveChatCampaignDialogRef.value.dialogRef.open();
};
const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.MARKETING.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.MARKETING.NEW_CAMPAIGN')"
    @click="toggleMarketingCampaignDialog()"
    @close="toggleMarketingCampaignDialog(false)"
  >
    <template #action>
      <MarketingCampaignDialog
        v-if="showMarketingCampaignDialog"
        @close="toggleMarketingCampaignDialog(false)"
      />
    </template>

    <div
      v-if="isFetchingCampaigns"
      class="flex justify-center items-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <MarketingCampaignList
      v-else-if="!hasNoMarketingCampaigns"
      :campaigns="marketingCampaigns"
      @edit="handleEdit"
      @delete="handleDelete"
    />
    <LiveChatCampaignEmptyState
      v-else
      :title="t('CAMPAIGN.MARKETING.EMPTY_STATE.TITLE')"
      :subtitle="t('CAMPAIGN.MARKETING.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />
    <EditMarketingCampaignDialog
      ref="editLiveChatCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      url-to-dispatch="marketingCampaigns/delete"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>
</template>
