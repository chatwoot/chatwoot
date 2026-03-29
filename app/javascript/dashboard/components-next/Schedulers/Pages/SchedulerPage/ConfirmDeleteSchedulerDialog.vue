<script setup>
import { ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  selectedScheduler: {
    type: Object,
    default: null,
  },
});

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);

const deleteScheduler = async id => {
  if (!id) return;

  try {
    await store.dispatch('schedulers/delete', id);
    useAlert(t('SCHEDULER.DELETE.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('SCHEDULER.DELETE.ERROR_MESSAGE'));
  }
};

const handleDialogConfirm = async () => {
  await deleteScheduler(props.selectedScheduler.id);
  dialogRef.value?.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t('SCHEDULER.DELETE.TITLE')"
    :description="t('SCHEDULER.DELETE.DESCRIPTION')"
    :confirm-button-label="t('SCHEDULER.DELETE.CONFIRM')"
    @confirm="handleDialogConfirm"
  />
</template>
