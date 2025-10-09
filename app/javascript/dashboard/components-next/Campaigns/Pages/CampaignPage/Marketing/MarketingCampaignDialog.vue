<script setup>
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import MarketingCampaignForm from './MarketingCampaignForm.vue';

const emit = defineEmits(['close']);
const store = useStore();
const { t } = useI18n();

const addCampaign = async campaignDetails => {
  try {
    await store.dispatch('marketingCampaigns/create', campaignDetails);

    useAlert(t('CAMPAIGN.MARKETING.CREATE.FORM.API.SUCCESS_MESSAGE'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAMPAIGN.MARKETING.CREATE.FORM.API.ERROR_MESSAGE');
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
    class="w-[25rem] z-50 min-w-0 absolute top-10 ltr:right-0 rtl:left-0 bg-n-alpha-3 backdrop-blur-[100px] p-6 rounded-xl border border-n-weak shadow-md flex flex-col gap-6 max-h-[85vh] overflow-y-auto"
  >
    <h3 class="text-base font-medium text-n-slate-12">
      {{ t(`CAMPAIGN.MARKETING.CREATE.TITLE`) }}
    </h3>
    <MarketingCampaignForm
      mode="create"
      @submit="handleSubmit"
      @cancel="handleClose"
    />
  </div>
</template>
