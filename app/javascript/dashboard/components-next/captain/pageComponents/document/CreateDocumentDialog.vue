<script setup>
import { ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import DocumentForm from './DocumentForm.vue';

const emit = defineEmits(['close', 'success']);

// Constants
const DOCUMENT_TYPE = {
  PDF: 'pdf',
  URL: 'url',
};

const store = useStore();
const { t } = useI18n();

const dialogRef = ref(null);
const documentForm = ref(null);

const handleSubmit = async newDocument => {
  try {
    await store.dispatch('captainDocuments/createDocument', newDocument);

    // Show appropriate success message based on document type
    const successMessage =
      newDocument.type === DOCUMENT_TYPE.PDF
        ? t('CAPTAIN.DOCUMENTS.CREATE.FORM.PDF_UPLOAD.SUCCESS_MESSAGE')
        : t('CAPTAIN.DOCUMENTS.CREATE.SUCCESS_MESSAGE');

    useAlert(successMessage);
    emit('success');
    dialogRef.value.close();
  } catch (error) {
    const errorMessage =
      error?.response?.data?.message ||
      t('CAPTAIN.DOCUMENTS.CREATE.ERROR_MESSAGE');
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
    :title="$t('CAPTAIN.DOCUMENTS.CREATE.TITLE')"
    :description="$t('CAPTAIN.DOCUMENTS.CREATE.DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <DocumentForm
      ref="documentForm"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
    <template #footer />
  </Dialog>
</template>
