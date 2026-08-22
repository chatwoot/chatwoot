<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import WhatsAppCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import WhatsAppCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/WhatsAppCampaignEmptyState.vue';
import { useRouter } from 'vue-router';

const { t } = useI18n();
const getters = useStoreGetters();
const router = useRouter();

const selectedCampaign = ref(null);
const editingCampaign = ref(null);
const whatsAppCampaignDialogRef = ref(null);

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

const goToAnalytics = campaign => {
  router.push({
    name: 'campaigns_whatsapp_analytics',
    params: { campaignId: campaign.id },
  });
};

const handleSelect = campaign => {
  if (
    campaign.campaign_status === 'draft' ||
    campaign.campaign_status === 'active'
  ) {
    handleEdit(campaign);
    return;
  }

  goToAnalytics(campaign);
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
      @analytics="goToAnalytics"
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
</template>
