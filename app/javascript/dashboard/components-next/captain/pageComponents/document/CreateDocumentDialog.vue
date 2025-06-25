<script setup>
import { ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import DocumentForm from './DocumentForm.vue';

const emit = defineEmits(['close']);
const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const documentForm = ref(null);

const i18nKey = 'CAPTAIN.DOCUMENTS.CREATE';

const handleSubmit = async newDocument => {
  try {
    if (newDocument.type === 'pdf') {
      // Handle PDF upload
      const formData = new FormData();
      formData.append('pdf_document', newDocument.pdf_document);
      formData.append('assistant_id', newDocument.assistant_id);

      await store.dispatch('captainDocuments/uploadPdf', formData);
      useAlert('PDF uploaded successfully! Processing will begin shortly.');
    } else {
      // Handle URL creation
      await store.dispatch('captainDocuments/create', {
        document: {
          external_link: newDocument.external_link,
          assistant_id: newDocument.assistant_id,
        },
      });
      useAlert('Document created successfully!');
    }
    dialogRef.value.close();
  } catch (error) {
    const errorMessage =
      error?.response?.data?.message ||
      'Failed to create document. Please try again.';
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
    title="Create New Document"
    description="Add a new document from a website URL or by uploading a PDF file"
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
