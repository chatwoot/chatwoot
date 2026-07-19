<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events.js';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import SMSCampaignForm from 'dashboard/components-next/Campaigns/Pages/CampaignPage/SMSCampaign/SMSCampaignForm.vue';

const props = defineProps({
  selectedCampaign: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();
const dialogRef = ref(null);

const isEdit = () => Boolean(props.selectedCampaign?.id);

const persistCampaign = async campaignDetails => {
  try {
    if (isEdit()) {
      await store.dispatch('campaigns/update', {
        id: props.selectedCampaign.id,
        ...campaignDetails,
      });
    } else {
      await store.dispatch('campaigns/create', campaignDetails);
      useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
        type: CAMPAIGN_TYPES.ONE_OFF,
      });
    }

    const isDraft = campaignDetails.campaign_status === 'draft';
    useAlert(
      t(
        isDraft
          ? 'CAMPAIGN.SMS.CREATE.FORM.API.DRAFT_SUCCESS_MESSAGE'
          : 'CAMPAIGN.SMS.CREATE.FORM.API.SUCCESS_MESSAGE'
      )
    );
    dialogRef.value?.close();
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAMPAIGN.SMS.CREATE.FORM.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const handleSubmit = campaignDetails => {
  persistCampaign(campaignDetails);
};

const handleClose = () => emit('close');

const handleCancel = () => {
  dialogRef.value?.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="2xl"
    :title="
      isEdit()
        ? t('CAMPAIGN.SMS.EDIT.TITLE')
        : t('CAMPAIGN.SMS.CREATE.TITLE')
    "
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
    position="top"
    @close="handleClose"
  >
    <SMSCampaignForm
      :selected-campaign="selectedCampaign"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
    <template #footer />
  </Dialog>
</template>
