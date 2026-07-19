<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import WhatsAppCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignDialog.vue';
import WhatsAppCampaignReportDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignReportDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import WhatsAppCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/WhatsAppCampaignEmptyState.vue';

const { t } = useI18n();
const getters = useStoreGetters();

const selectedCampaign = ref(null);
const editingCampaign = ref(null);
const reportCampaign = ref(null);
const whatsAppCampaignDialogRef = ref(null);
const [showReportDialog, toggleReportDialog] = useToggle();

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);

const confirmDeleteCampaignDialogRef = ref(null);

const WhatsAppCampaigns = computed(
  () => getters['campaigns/getWhatsAppCampaigns'].value
);

const hasNoWhatsAppCampaigns = computed(
  () => WhatsAppCampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const openCreateDialog = () => {
  editingCampaign.value = null;
  whatsAppCampaignDialogRef.value?.dialogRef.open();
};

const handleEdit = campaign => {
  editingCampaign.value = campaign;
  whatsAppCampaignDialogRef.value?.dialogRef.open();
};

const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};

const handleSelect = campaign => {
  if (campaign.campaign_status === 'draft') {
    handleEdit(campaign);
    return;
  }
  reportCampaign.value = campaign;
  toggleReportDialog(true);
};

const handleCloseReport = () => {
  toggleReportDialog(false);
  reportCampaign.value = null;
};

const handleCloseDialog = () => {
  editingCampaign.value = null;
};
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.WHATSAPP.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.WHATSAPP.NEW_CAMPAIGN')"
    @click="openCreateDialog"
  >
    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <CampaignList
      v-else-if="!hasNoWhatsAppCampaigns"
      :campaigns="WhatsAppCampaigns"
      clickable-cards
      @edit="handleEdit"
      @delete="handleDelete"
      @select="handleSelect"
    />
    <WhatsAppCampaignEmptyState
      v-else
      :title="t('CAMPAIGN.WHATSAPP.EMPTY_STATE.TITLE')"
      :subtitle="t('CAMPAIGN.WHATSAPP.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>
  <WhatsAppCampaignDialog
    ref="whatsAppCampaignDialogRef"
    :selected-campaign="editingCampaign"
    @close="handleCloseDialog"
  />
  <WhatsAppCampaignReportDialog
    v-if="showReportDialog && reportCampaign"
    :campaign="reportCampaign"
    @close="handleCloseReport"
  />
</template>
