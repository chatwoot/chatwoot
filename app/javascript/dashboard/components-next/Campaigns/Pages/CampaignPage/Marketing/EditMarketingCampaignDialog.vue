<script setup>
import { ref, computed } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import MarketingCampaignForm from './MarketingCampaignForm.vue';

const props = defineProps({
  selectedCampaign: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const marketingCampaignFormRef = ref(null);

const uiFlags = useMapGetter('marketingCampaigns/getUIFlags');
const isUpdatingCampaign = computed(() => uiFlags.value.isUpdating);

const isInvalidForm = computed(
  () => marketingCampaignFormRef.value?.isSubmitDisabled
);

const selectedCampaignId = computed(() => props.selectedCampaign.id);

const updateCampaign = async campaignDetails => {
  try {
    await store.dispatch('marketingCampaigns/update', {
      id: selectedCampaignId.value,
      ...campaignDetails,
    });

    useAlert(t('CAMPAIGN.MARKETING.EDIT.FORM.API.SUCCESS_MESSAGE'));
    dialogRef.value.close();
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAMPAIGN.MARKETING.EDIT.FORM.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const handleSubmit = () => {
  updateCampaign(marketingCampaignFormRef.value.prepareCampaignDetails());
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="t('CAMPAIGN.MARKETING.EDIT.TITLE')"
    :is-loading="isUpdatingCampaign"
    :disable-confirm-button="isUpdatingCampaign || isInvalidForm"
    overflow-y-auto
    @confirm="handleSubmit"
  >
    <MarketingCampaignForm
      ref="marketingCampaignFormRef"
      mode="edit"
      :selected-campaign="selectedCampaign"
      :show-action-buttons="false"
      @submit="handleSubmit"
    />
  </Dialog>
</template>
