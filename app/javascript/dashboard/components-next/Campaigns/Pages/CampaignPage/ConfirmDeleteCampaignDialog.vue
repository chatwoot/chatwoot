<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

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

const description = computed(() =>
  props.selectedCampaign?.inbox?.channel_type === INBOX_TYPES.WHATSAPP
    ? t('CAMPAIGN.CONFIRM_DELETE.WHATSAPP_DESCRIPTION')
    : t('CAMPAIGN.CONFIRM_DELETE.DESCRIPTION')
);

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
    :description="description"
    :confirm-button-label="t('CAMPAIGN.CONFIRM_DELETE.CONFIRM')"
    @confirm="handleDialogConfirm"
  />
</template>
