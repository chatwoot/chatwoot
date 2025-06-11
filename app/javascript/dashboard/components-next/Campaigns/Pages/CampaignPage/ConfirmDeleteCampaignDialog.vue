<script setup>
import { ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  selectedCampaign: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);

const deleteCampaign = async id => {
  if (!id) return;

  try {
    await store.dispatch('campaigns/delete', id);
    useAlert(t('CAMPAIGN.CONFIRM_DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('CAMPAIGN.CONFIRM_DELETE.API.ERROR_MESSAGE'));
  }
};

const handleDialogConfirm = async () => {
  await deleteCampaign(props.selectedCampaign.id);
  dialogRef.value?.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t('CAMPAIGN.CONFIRM_DELETE.TITLE')"
    :description="t('CAMPAIGN.CONFIRM_DELETE.DESCRIPTION')"
    :confirm-button-label="t('CAMPAIGN.CONFIRM_DELETE.CONFIRM')"
    @confirm="handleDialogConfirm"
  />
</template>
