<script setup>
import { ref } from 'vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import DatePicker from 'dashboard/components-next/DatePicker/DatePicker.vue';

const emit = defineEmits(['chooseTime']);

const dialogRef = ref(null);
const datePickerRef = ref(null);
const today = new Date();

const onApply = dateTime => {
  dialogRef.value?.close();
  emit('chooseTime', dateTime);
};

const onClear = () => {
  dialogRef.value?.close();
};

const onDialogClose = () => {
  datePickerRef.value?.resetState();
};

const open = () => {
  dialogRef.value?.open();
};

const close = () => {
  dialogRef.value?.close();
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="$t('CONVERSATION.CUSTOM_SNOOZE.TITLE')"
    :show-confirm-button="false"
    :show-cancel-button="false"
    width="2xl"
    @close="onDialogClose"
  >
    <DatePicker
      ref="datePickerRef"
      :min-date="today"
      @apply="onApply"
      @clear="onClear"
    />
  </Dialog>
</template>
