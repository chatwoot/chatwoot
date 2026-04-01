<script setup>
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events.js';

import LiveChatCampaignForm from 'dashboard/components-next/Campaigns/Pages/CampaignPage/LiveChatCampaign/LiveChatCampaignForm.vue';

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();

const addCampaign = async campaignDetails => {
  try {
    await store.dispatch('campaigns/create', campaignDetails);

    // tracking this here instead of the store to track the type of campaign
    useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
      type: CAMPAIGN_TYPES.ONGOING,
    });

    useAlert(t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAMPAIGN.LIVE_CHAT.CREATE.FORM.API.ERROR_MESSAGE');
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
    class="absolute top-10 z-50 flex max-h-[85vh] min-w-0 w-[25rem] flex-col gap-6 overflow-y-auto rounded-xl border border-outline-variant/10 bg-surface-container-low/95 p-6 shadow-lg backdrop-blur-md ltr:right-0 rtl:left-0"
  >
    <h3 class="text-base font-semibold text-on-surface">
      {{ t(`CAMPAIGN.LIVE_CHAT.CREATE.TITLE`) }}
    </h3>
    <LiveChatCampaignForm
      mode="create"
      @submit="handleSubmit"
      @cancel="handleClose"
    />
  </div>
</template>
