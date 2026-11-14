<script setup>
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { CAMPAIGN_TYPES } from 'shared/constants/campaign.js';
import { CAMPAIGNS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events.js';

import SMSCampaignForm from 'dashboard/components-next/Campaigns/Pages/CampaignPage/SMSCampaign/SMSCampaignForm.vue';
import { requestErrorMessage } from 'dashboard/helper/requestErrorMessage';

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();

const FIELD_LABELS = {
  title: 'CAMPAIGN.SMS.CREATE.FORM.TITLE.LABEL',
  message: 'CAMPAIGN.SMS.CREATE.FORM.MESSAGE.LABEL',
};

const addCampaign = async campaignDetails => {
  try {
    await store.dispatch('campaigns/create', campaignDetails);

    // tracking this here instead of the store to track the type of campaign
    useTrack(CAMPAIGNS_EVENTS.CREATE_CAMPAIGN, {
      type: CAMPAIGN_TYPES.ONE_OFF,
    });

    useAlert(t('CAMPAIGN.SMS.CREATE.FORM.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage = requestErrorMessage(
      error,
      t,
      'CAMPAIGN.SMS.CREATE.FORM.API.ERROR_MESSAGE',
      FIELD_LABELS
    );
    useAlert(errorMessage);
  }
};

const handleSubmit = campaignDetails => {
  addCampaign(campaignDetails);
};

const handleClose = () => emit('close');
</script>

<template>
  <div
    class="w-[25rem] z-50 min-w-0 absolute top-10 ltr:right-0 rtl:left-0 bg-n-alpha-3 backdrop-blur-[100px] p-6 rounded-xl border border-n-weak shadow-md flex flex-col gap-6"
  >
    <h3 class="text-base font-medium text-n-slate-12">
      {{ t(`CAMPAIGN.SMS.CREATE.TITLE`) }}
    </h3>
    <SMSCampaignForm @submit="handleSubmit" @cancel="handleClose" />
  </div>
</template>
