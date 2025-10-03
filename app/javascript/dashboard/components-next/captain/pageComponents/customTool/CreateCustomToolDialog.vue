<script setup>
import { ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import CustomToolForm from './CustomToolForm.vue';

const emit = defineEmits(['close']);
const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);

const i18nKey = 'CAPTAIN.CUSTOM_TOOLS.CREATE';

const handleSubmit = async newTool => {
  try {
    await store.dispatch('captainCustomTools/create', newTool);
    useAlert(t(`${i18nKey}.SUCCESS_MESSAGE`));
    dialogRef.value.close();
  } catch (error) {
    const errorMessage =
      parseAPIErrorResponse(error) || t(`${i18nKey}.ERROR_MESSAGE`);
    useAlert(errorMessage);
  }
};

const handleClose = () => {
  emit('close');
};

const handleCancel = () => {
  dialogRef.value.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="2xl"
    :title="$t(`${i18nKey}.TITLE`)"
    :description="$t('CAPTAIN.CUSTOM_TOOLS.FORM_DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <CustomToolForm @submit="handleSubmit" @cancel="handleCancel" />
    <template #footer />
  </Dialog>
</template>
