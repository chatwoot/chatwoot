<script setup>
import { ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import DocumentForm from './DocumentForm.vue';

const emit = defineEmits(['close', 'success']);
const store = useStore();

const dialogRef = ref(null);
const documentForm = ref(null);

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

    // Emit success event to refresh the list
    emit('success');
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
