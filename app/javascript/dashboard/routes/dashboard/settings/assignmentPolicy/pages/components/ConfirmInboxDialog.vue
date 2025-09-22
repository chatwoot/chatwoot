<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const emit = defineEmits(['add']);

const { t } = useI18n();

const dialogRef = ref(null);
const currentInbox = ref(null);

const openDialog = inbox => {
  currentInbox.value = inbox;
  dialogRef.value.open();
};

const closeDialog = () => {
  dialogRef.value.close();
};

const handleDialogConfirm = () => {
  emit('add', currentInbox.value.id);
};

defineExpose({ openDialog, closeDialog });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="
      t(
        'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.EDIT.CONFIRM_ADD_INBOX_DIALOG.TITLE'
      )
    "
    :description="
      t(
        'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.EDIT.CONFIRM_ADD_INBOX_DIALOG.DESCRIPTION',
        {
          inboxName: currentInbox?.name,
        }
      )
    "
    :confirm-button-label="
      t(
        'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.EDIT.CONFIRM_ADD_INBOX_DIALOG.CONFIRM_BUTTON_LABEL'
      )
    "
    :cancel-button-label="
      t(
        'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.EDIT.CONFIRM_ADD_INBOX_DIALOG.CANCEL_BUTTON_LABEL'
      )
    "
    @confirm="handleDialogConfirm"
  />
</template>
