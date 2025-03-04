<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import WhatsappCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsappCampaign/WhatsappCampaignDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import EditWhatsappCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsappCampaign/EditWhatsappCampaignDialog.vue';
import WhatsappCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/WhatsappCampaignEmptyState.vue';
import CampaignReportModal from 'dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsappCampaign/CampaignReportModal.vue';

const { t } = useI18n();
const getters = useStoreGetters();

const selectedCampaign = ref(null);
const [showWhatsappCampaignDialog, toggleWhatsappCampaignDialog] = useToggle();
const [showEditWhatsappCampaignDialog, toggleEditWhatsappCampaignDialog] =
  useToggle();
const showReportModal = ref(false); // Control modal visibility
const selectedReportCampaign = ref(null); // Track selected campaign for report

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);

const confirmDeleteCampaignDialogRef = ref(null);

const WhatsappCampaigns = computed(() =>
  getters['campaigns/getCampaigns'].value(CAMPAIGN_TYPES.WHATSAPP)
);

const hasNoWhatsappCampaigns = computed(() => {
  return WhatsappCampaigns.value?.length === 0 && !isFetchingCampaigns.value;
});

const handleEdit = campaign => {
  selectedCampaign.value = campaign;
  toggleEditWhatsappCampaignDialog(true);
};

const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};

const viewReport = campaign => {
  selectedReportCampaign.value = campaign;
  showReportModal.value = true;
};

const closeReportModal = () => {
  showReportModal.value = false;
};
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.WHATSAPP.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.WHATSAPP.NEW_CAMPAIGN')"
    @click="toggleWhatsappCampaignDialog()"
    @close="toggleWhatsappCampaignDialog(false)"
  >
    <template #action>
      <WhatsappCampaignDialog
        v-if="showWhatsappCampaignDialog"
        @close="toggleWhatsappCampaignDialog(false)"
      />
    </template>
    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <CampaignList
      v-else-if="!hasNoWhatsappCampaigns"
      :campaigns="WhatsappCampaigns"
      :campaignType="'whatsapp'"
      @report="viewReport"
      @edit="handleEdit"
      @delete="handleDelete"
    />
    <WhatsappCampaignEmptyState
      v-else
      :title="t('CAMPAIGN.WHATSAPP.EMPTY_STATE.TITLE')"
      :subtitle="t('CAMPAIGN.WHATSAPP.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />
    <EditWhatsappCampaignDialog
      v-if="showEditWhatsappCampaignDialog"
      :selected-campaign="selectedCampaign"
      @close="toggleEditWhatsappCampaignDialog(false)"
    />
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
    <CampaignReportModal
      v-if="showReportModal"
      :campaign="selectedReportCampaign"
      @close="closeReportModal"
    />
  </CampaignLayout>
</template>
