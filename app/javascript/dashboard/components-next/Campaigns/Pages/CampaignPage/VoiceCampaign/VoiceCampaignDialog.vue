<script setup>
import { onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events.js';

import VoiceCampaignForm from './VoiceCampaignForm.vue';

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();

onMounted(() => {
  store.dispatch('inboxes/get');
  store.dispatch('labels/get');
});

const addCampaign = async campaignDetails => {
  try {
    await store.dispatch('campaigns/create', {
      ...campaignDetails,
      campaign_type: CAMPAIGN_TYPES.VOICE,
    });
    
    // tracking this here instead of the store to track the type of campaign
    useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
      type: CAMPAIGN_TYPES.VOICE,
    });
    
    useAlert(t('CAMPAIGN.VOICE.CREATE.FORM.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage = error?.response?.message || t('CAMPAIGN.VOICE.CREATE.FORM.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const handleClose = () => emit('close');

const handleSubmit = campaignDetails => {
  addCampaign(campaignDetails);
  handleClose();
};
</script>

<template>
  <div
    class="w-[25rem] z-50 min-w-0 absolute top-10 ltr:right-0 rtl:left-0 bg-n-alpha-3 backdrop-blur-[100px] p-6 rounded-xl border border-slate-50 dark:border-slate-900 shadow-md flex flex-col gap-6 max-h-[85vh] overflow-y-auto"
  >
    <h3 class="text-base font-medium text-slate-900 dark:text-slate-50">
      {{ t(`CAMPAIGN.VOICE.CREATE.TITLE`) }}
    </h3>
    <VoiceCampaignForm
      @submit="handleSubmit"
      @cancel="handleClose"
    />
  </div>
</template>