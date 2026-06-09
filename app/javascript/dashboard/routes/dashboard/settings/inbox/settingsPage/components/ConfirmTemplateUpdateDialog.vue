<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const emit = defineEmits(['confirm']);

const { t } = useI18n();
const dialogRef = ref(null);

const handleDialogConfirm = () => {
  emit('confirm');
  dialogRef.value?.close();
};

defineExpose({
  dialogRef,
  open: () => dialogRef.value?.open(),
  close: () => dialogRef.value?.close(),
});
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t('INBOX_MGMT.CSAT.TEMPLATE_UPDATE_DIALOG.TITLE')"
    :description="t('INBOX_MGMT.CSAT.TEMPLATE_UPDATE_DIALOG.DESCRIPTION')"
    :confirm-button-label="t('INBOX_MGMT.CSAT.TEMPLATE_UPDATE_DIALOG.CONFIRM')"
    :cancel-button-label="t('INBOX_MGMT.CSAT.TEMPLATE_UPDATE_DIALOG.CANCEL')"
    @confirm="handleDialogConfirm"
  />
</template>
