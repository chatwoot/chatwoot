<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const emit = defineEmits(['delete']);

const { t } = useI18n();

const dialogRef = ref(null);
const currentPolicyId = ref(null);

const openDialog = policyId => {
  currentPolicyId.value = policyId;
  dialogRef.value.open();
};

const closeDialog = () => {
  dialogRef.value.close();
};

const handleDialogConfirm = () => {
  emit('delete', currentPolicyId.value);
};

defineExpose({ openDialog, closeDialog });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t('ASSIGNMENT_POLICY.DELETE_POLICY.TITLE')"
    :description="t('ASSIGNMENT_POLICY.DELETE_POLICY.DESCRIPTION')"
    :confirm-button-label="
      t('ASSIGNMENT_POLICY.DELETE_POLICY.CONFIRM_BUTTON_LABEL')
    "
    :cancel-button-label="
      t('ASSIGNMENT_POLICY.DELETE_POLICY.CANCEL_BUTTON_LABEL')
    "
    @confirm="handleDialogConfirm"
  />
</template>
