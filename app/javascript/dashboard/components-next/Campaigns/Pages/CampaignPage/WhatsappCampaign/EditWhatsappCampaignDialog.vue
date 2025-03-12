<script setup>
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import EditWhatsappCampaignForm from './EditWhatsappCampaignForm.vue';

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
    throw error;
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
    <EditWhatsappCampaignForm
      :selected-campaign="selectedCampaign"
      @submit="handleSubmit"
      @cancel="handleClose"
    />
  </woot-modal>
</template>
