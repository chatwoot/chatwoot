<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import APICampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/APICampaign/APICampaignDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import APICampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/APICampaignEmptyState.vue';

const { t } = useI18n();
const getters = useStoreGetters();

const selectedCampaign = ref(null);
const [showAPICampaignDialog, toggleAPICampaignDialog] = useToggle();

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value?.isFetching ?? false);

const confirmDeleteCampaignDialogRef = ref(null);

const APICampaigns = computed(() => {
  const campaigns = getters['campaigns/getCampaigns']?.value?.(
    CAMPAIGN_TYPES.ONE_OFF
  );
  return (
    campaigns?.filter(campaign => {
      const channelType = campaign?.inbox?.channel_type;
      return channelType && channelType.includes('Api');
    }) ?? []
  );
});

const hasNoAPICampaigns = computed(
  () => APICampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const handleDelete = campaign => {
  if (!campaign) return;

  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value?.dialogRef?.open?.();
};
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.API.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.API.NEW_CAMPAIGN')"
    @click="toggleAPICampaignDialog()"
    @close="toggleAPICampaignDialog(false)"
  >
    <template #action>
      <APICampaignDialog
        v-if="showAPICampaignDialog"
        @close="toggleAPICampaignDialog(false)"
      />
    </template>
    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <CampaignList
      v-else-if="!hasNoAPICampaigns"
      :campaigns="APICampaigns"
      @delete="handleDelete"
    />
    <APICampaignEmptyState
      v-else
      :title="t('CAMPAIGN.API.EMPTY_STATE.TITLE')"
      :subtitle="t('CAMPAIGN.API.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>
</template>
