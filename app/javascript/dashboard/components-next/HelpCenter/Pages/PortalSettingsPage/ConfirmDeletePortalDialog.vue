<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

defineProps({
  activePortalName: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['deletePortal']);

const { t } = useI18n();

const dialogRef = ref(null);

const handleDialogConfirm = () => {
  emit('deletePortal');
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="
      t(
        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.DIALOG.HEADER',
        {
          portalName: activePortalName,
        }
      )
    "
    :description="
      t(
        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.DIALOG.DESCRIPTION'
      )
    "
    :confirm-button-label="
      t(
        'HELP_CENTER.PORTAL_SETTINGS.CONFIGURATION_FORM.DELETE_PORTAL.DIALOG.CONFIRM_BUTTON_LABEL'
      )
    "
    @confirm="handleDialogConfirm"
  />
</template>
