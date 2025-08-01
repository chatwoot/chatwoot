<script setup>
import { ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import Auth from 'dashboard/api/auth';
import { useAccount } from 'dashboard/composables/useAccount';
import { getAgentManagerBaseUrl } from 'dashboard/constants/agentManager';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import DocumentForm from './DocumentForm.vue';

const emit = defineEmits(['close', 'created']);
const { t } = useI18n();
const store = useStore();
const { accountId } = useAccount();
const isLoading = ref(false);

const dialogRef = ref(null);
const documentForm = ref(null);

const i18nKey = 'CAPTAIN.DOCUMENTS.CREATE';

const handleSubmit = async newDocument => {
  try {
    isLoading.value = true;
    const authData = Auth.getAuthData();
    let response;
    const baseUrl = getAgentManagerBaseUrl();
    if (newDocument instanceof FormData) {
      response = await fetch(`${baseUrl}/agent-manager/api/v1/datasources`, {
        method: 'POST',
        body: newDocument,
        headers: {
          'X-CHATWOOT-ACCOUNT-ID': accountId.value,
          'Access-Token': authData['access-token'],
          'Authorization': `${authData['token-type']} ${authData['access-token']}`,
        },
      });
    } else {
      response = await fetch(`${baseUrl}/agent-manager/api/v1/datasources`, {
        method: 'POST',
        body: JSON.stringify(newDocument),
        headers: {
          'Content-Type': 'application/json',
          'X-CHATWOOT-ACCOUNT-ID': accountId.value,
          'Access-Token': authData['access-token'],
          'Authorization': `${authData['token-type']} ${authData['access-token']}`,
        },
      });
    }
    if (!response.ok) throw new Error('Failed to create document');
    useAlert(t(`${i18nKey}.SUCCESS_MESSAGE`));
    dialogRef.value.close();
    emit('created');
  } catch (error) {
    const errorMessage = error?.response?.message || t(`${i18nKey}.ERROR_MESSAGE`);
    useAlert(errorMessage);
  } finally {
    isLoading.value = false;
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
    :title="$t(`${i18nKey}.TITLE`)"
    :description="$t('CAPTAIN.DOCUMENTS.FORM_DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <DocumentForm
      ref="documentForm"
      @submit="handleSubmit"
      @cancel="handleCancel"
      :is-loading="isLoading"
    />
    <template #footer />
  </Dialog>
</template>
