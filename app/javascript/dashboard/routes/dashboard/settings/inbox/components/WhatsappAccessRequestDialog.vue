<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const MAX_USE_CASE_LENGTH = 2000;

const { t } = useI18n();
const store = useStore();
const dialogRef = ref(null);
const useCase = ref('');
const isSubmitting = ref(false);
const errorMessage = ref('');

const submit = async () => {
  if (isSubmitting.value || !useCase.value.trim()) return;

  isSubmitting.value = true;
  errorMessage.value = '';
  try {
    await store.dispatch(
      'accounts/requestWhatsappEmbeddedSignupAccess',
      useCase.value.trim()
    );
    dialogRef.value.close();
  } catch {
    errorMessage.value = t(
      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ACCESS_REQUEST.ERROR'
    );
  } finally {
    isSubmitting.value = false;
  }
};

const open = () => {
  errorMessage.value = '';
  dialogRef.value.open();
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ACCESS_REQUEST.BUTTON')"
    :description="
      t(
        'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ACCESS_REQUEST.FORM_DESCRIPTION'
      )
    "
    :confirm-button-label="
      t('INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ACCESS_REQUEST.SUBMIT')
    "
    :disable-confirm-button="!useCase.trim()"
    :is-loading="isSubmitting"
    @confirm="submit"
  >
    <TextArea
      id="whatsapp-use-case"
      v-model="useCase"
      :label="
        t(
          'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ACCESS_REQUEST.USE_CASE_LABEL'
        )
      "
      :placeholder="
        t(
          'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.ACCESS_REQUEST.USE_CASE_PLACEHOLDER'
        )
      "
      :max-length="MAX_USE_CASE_LENGTH"
      :disabled="isSubmitting"
      :message="errorMessage"
      :message-type="errorMessage ? 'error' : 'info'"
      show-character-count
      autofocus
    />
  </Dialog>
</template>
