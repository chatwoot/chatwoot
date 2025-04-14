<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';

import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import EmailCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/EmailCampaign/EmailCampaignDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import EmailCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/EmailCampaignEmptyState.vue';
import EditEmailCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/EmailCampaign/EditEmailCampaignDialog.vue';

const { t } = useI18n();
const getters = useStoreGetters();

const selectedCampaign = ref(null);
const [showEmailCampaignDialog, toggleEmailCampaignDialog] = useToggle();
const [showEditEmailCampaignDialog, toggleEditEmailCampaignDialog] =
  useToggle();

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);

const confirmDeleteCampaignDialogRef = ref(null);

const EmailCampaigns = computed(() =>
  getters['campaigns/getCampaigns'].value(CAMPAIGN_TYPES.EMAIL)
);

const hasNoEmailCampaigns = computed(
  () => EmailCampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const handleEdit = campaign => {
  console.log("This is the campaign", campaign) 
  selectedCampaign.value = campaign;
  toggleEditEmailCampaignDialog(true);
};

const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.EMAIL.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.EMAIL.NEW_CAMPAIGN')"
    @click="toggleEmailCampaignDialog(true)"
    @close="toggleEmailCampaignDialog(false)"
  >
    <template #action>
      <EmailCampaignDialog
        v-if="showEmailCampaignDialog"
        @close="toggleEmailCampaignDialog(false)"
      />
      <EditEmailCampaignDialog
        v-if="showEditEmailCampaignDialog"
        :selected-campaign="selectedCampaign"
        @close="toggleEditEmailCampaignDialog(false)"
      /> 
    </template>
    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <CampaignList
      v-else-if="!hasNoEmailCampaigns"
      :campaigns="EmailCampaigns"
      :campaignType="email"
      @delete="handleDelete"
      @edit="handleEdit"
    />
    <EmailCampaignEmptyState
      v-else
      :title="t('CAMPAIGN.EMAIL.EMPTY_STATE.TITLE')"
      :subtitle="t('CAMPAIGN.EMAIL.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>
</template>
