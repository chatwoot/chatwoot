<script setup>
import { ref, computed } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import Auth from 'dashboard/api/auth';
import { useAccount } from 'dashboard/composables/useAccount';
import { getAgentManagerBaseUrl } from 'dashboard/constants/agentManager';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import AssistantForm from './AssistantForm.vue';

const props = defineProps({
  selectedAssistant: {
    type: Object,
    default: () => ({}),
  },
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
});
const emit = defineEmits(['close']);
const { t } = useI18n();
const { accountId } = useAccount();

const dialogRef = ref(null);
const assistantForm = ref(null);

const i18nKey = computed(
  () => `CAPTAIN.ASSISTANTS.${props.type.toUpperCase()}`
);

const createAssistant = async assistantDetails => {
  const authData = Auth.getAuthData();
  const headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-CHATWOOT-ACCOUNT-ID': accountId.value,
    'Access-Token': authData['access-token'],
    'Authorization': `${authData['token-type']} ${authData['access-token']}`,
  };
  console.debug('[CreateAssistantDialog] Creating assistant with payload:', assistantDetails);
  const baseUrl = getAgentManagerBaseUrl();
  const response = await fetch(`${baseUrl}/agent-manager/api/v1/agents`, {
    method: 'POST',
    headers,
    body: JSON.stringify(assistantDetails),
  });
  console.debug('[CreateAssistantDialog] Create response status:', response.status);
  if (!response.ok) {
    const errorText = await response.text();
    console.error('[CreateAssistantDialog] Create failed:', errorText);
    throw new Error('Failed to create assistant');
  }
};

const updateAssistant = async assistantDetails => {
  const authData = Auth.getAuthData();
  const headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-CHATWOOT-ACCOUNT-ID': accountId.value,
    'Access-Token': authData['access-token'],
    'Authorization': `${authData['token-type']} ${authData['access-token']}`,
  };
  // Ensure id is present in the payload for update
  const payload = { ...assistantDetails, id: props.selectedAssistant.id };
  console.debug('[CreateAssistantDialog] Upserting assistant with payload:', payload);
  const baseUrl = getAgentManagerBaseUrl();
  const response = await fetch(`${baseUrl}/agent-manager/api/v1/agents`, {
    method: 'POST',
    headers,
    body: JSON.stringify(payload),
  });
  console.debug('[CreateAssistantDialog] Upsert response status:', response.status);
  if (!response.ok) {
    const errorText = await response.text();
    console.error('[CreateAssistantDialog] Upsert failed:', errorText);
    throw new Error('Failed to update assistant');
  }
};

const handleSubmit = async updatedAssistant => {
  console.debug('[CreateAssistantDialog] handleSubmit called with:', updatedAssistant);
  try {
    if (props.type === 'edit') {
      await updateAssistant(updatedAssistant);
    } else {
      await createAssistant(updatedAssistant);
    }
    useAlert(t(`${i18nKey.value}.SUCCESS_MESSAGE`));
    emit('close');
  } catch (error) {
    const errorMessage = error?.message || t(`${i18nKey.value}.ERROR_MESSAGE`);
    useAlert(errorMessage);
    console.error('[CreateAssistantDialog] handleSubmit error:', error);
  }
};

const handleClose = () => {
  emit('close');
};

const handleCancel = () => {
  emit('close');
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    :title="t(`${i18nKey}.TITLE`)"
    :description="t('CAPTAIN.ASSISTANTS.FORM_DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
    @close="handleClose"
  >
    <AssistantForm
      ref="assistantForm"
      :mode="type"
      :assistant="selectedAssistant"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
    <template #footer />
  </Dialog>
</template>
