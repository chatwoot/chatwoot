<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events.js';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import LiveChatCampaignForm from 'dashboard/components-next/Campaigns/Pages/CampaignPage/LiveChatCampaign/LiveChatCampaignForm.vue';

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();
const dialogRef = ref(null);

const addCampaign = async campaignDetails => {
  try {
    await store.dispatch('campaigns/create', campaignDetails);

    useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
      type: CAMPAIGN_TYPES.ONGOING,
    });

    useAlert(t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.API.SUCCESS_MESSAGE'));
    dialogRef.value?.close();
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const handleClose = () => emit('close');

const handleCancel = () => {
  dialogRef.value?.close();
};

const handleSubmit = campaignDetails => {
  addCampaign(campaignDetails);
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="2xl"
    :title="t('CAMPAIGN.LIVE_CHAT.CREATE.TITLE')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
    position="top"
    @close="handleClose"
  >
    <LiveChatCampaignForm
      mode="create"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
    <template #footer />
  </Dialog>
</template>
