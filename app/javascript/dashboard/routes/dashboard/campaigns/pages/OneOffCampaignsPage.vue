<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import OneOffCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/OneOffCampaign/OneOffCampaignDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import OneOffCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/OneOffCampaignEmptyState.vue';

const { t } = useI18n();
const getters = useStoreGetters();

const selectedCampaign = ref(null);
const [showOneOffCampaignDialog, toggleOneOffCampaignDialog] = useToggle();

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);

const confirmDeleteCampaignDialogRef = ref(null);

const oneOffCampaigns = computed(() =>
  getters['campaigns/getCampaigns'].value(CAMPAIGN_TYPES.ONE_OFF)
);

const hasNoOneOffCampaigns = computed(
  () => oneOffCampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.NEW_CAMPAIGN')"
    @click="toggleOneOffCampaignDialog()"
    @close="toggleOneOffCampaignDialog(false)"
  >
    <template #action>
      <OneOffCampaignDialog
        v-if="showOneOffCampaignDialog"
        @close="toggleOneOffCampaignDialog(false)"
      />
    </template>
    <template #content>
      <div
        v-if="isFetchingCampaigns"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>
      <CampaignList
        v-else-if="!hasNoOneOffCampaigns"
        :campaigns="oneOffCampaigns"
        @delete="handleDelete"
      />
      <OneOffCampaignEmptyState
        v-else
        :title="t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.EMPTY_STATE.TITLE')"
        :subtitle="t('CAMPAIGN.ONE_OFF_CAMPAIGNS_PAGE.EMPTY_STATE.SUBTITLE')"
        class="pt-14"
      />
    </template>
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>
</template>
