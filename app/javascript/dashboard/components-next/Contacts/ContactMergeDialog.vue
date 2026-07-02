<script setup>
import { ref } from 'vue';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ContactMerge from 'dashboard/components-next/Contacts/ContactsSidebar/ContactMerge.vue';

defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['goToContactsList']);

const dialogRef = ref(null);

const open = () => {
  dialogRef.value?.open?.();
};

const close = () => {
  dialogRef.value?.close?.();
};

const handleGoToContactsList = () => {
  close();
  emit('goToContactsList');
};

defineExpose({ open, close });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
    width="2xl"
  >
    <ContactMerge
      :selected-contact="selectedContact"
      @go-to-contacts-list="handleGoToContactsList"
      @reset-tab="close"
    />
  </Dialog>
</template>
