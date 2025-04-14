<script setup>
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events.js';

import EditEmailCampaignForm from 'dashboard/components-next/Campaigns/Pages/CampaignPage/EmailCampaign/EditEmailCampaignForm.vue';

const props = defineProps({
  selectedCampaign: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();

const updateCampaign = async campaignDetails => {
  try {
    await store.dispatch('campaigns/update', {
      id: props.selectedCampaign.id,
      ...campaignDetails,
    });

    useAlert(t('CAMPAIGN.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.response?.data?.message || t('CAMPAIGN.EDIT.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const handleSubmit = campaignDetails => {
  updateCampaign(campaignDetails);
  emit('close');
};

const handleClose = () => emit('close');
</script>

<template>
  <woot-modal :show="true" @close="handleClose">
    <EditEmailCampaignForm
      :selected-campaign="selectedCampaign"
      @submit="handleSubmit"
      @cancel="handleClose"
    />
  </woot-modal>
</template>
