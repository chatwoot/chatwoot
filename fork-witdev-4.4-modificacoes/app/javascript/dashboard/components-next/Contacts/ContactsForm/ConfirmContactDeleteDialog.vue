<script setup>
import { ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['goToContactsList']);

const { t } = useI18n();
const store = useStore();
const route = useRoute();

const dialogRef = ref(null);

const deleteContact = async id => {
  if (!id) return;

  try {
    await store.dispatch('contacts/delete', id);
    useAlert(t('CONTACTS_LAYOUT.DETAILS.DELETE_DIALOG.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('CONTACTS_LAYOUT.DETAILS.DELETE_DIALOG.API.ERROR_MESSAGE'));
  }
};

const handleDialogConfirm = async () => {
  emit('goToContactsList');
  await deleteContact(route.params.contactId || props.selectedContact.id);
  dialogRef.value?.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t('CONTACTS_LAYOUT.DETAILS.DELETE_DIALOG.TITLE')"
    :description="t('CONTACTS_LAYOUT.DETAILS.DELETE_DIALOG.DESCRIPTION')"
    :confirm-button-label="t('CONTACTS_LAYOUT.DETAILS.DELETE_DIALOG.CONFIRM')"
    @confirm="handleDialogConfirm"
  />
</template>
