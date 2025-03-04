<script setup>
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events.js';
import WhatsappCampaignForm from './WhatsappCampaignForm.vue';

const emit = defineEmits(['close']);
const store = useStore();
const { t } = useI18n();

const addCampaign = async campaignDetails => {
  try {
    await store.dispatch('campaigns/create', campaignDetails);
    useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
      type: CAMPAIGN_TYPES.WHATSAPP,
    });
    useAlert(t('CAMPAIGN.ADD.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.response?.data?.message || t('CAMPAIGN.ADD.API.ERROR_MESSAGE');
    useAlert(errorMessage);
    throw error; // Re-throw to handle in the form if needed
  }
};

const handleSubmit = campaignDetails => {
  addCampaign(campaignDetails);
  emit('close');
};

const handleClose = () => emit('close');
</script>

<template>
  <woot-modal :show="true" @close="handleClose">
    <WhatsappCampaignForm @submit="handleSubmit" @cancel="handleClose" />
  </woot-modal>
</template>
