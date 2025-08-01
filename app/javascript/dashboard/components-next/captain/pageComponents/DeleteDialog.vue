<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Auth from 'dashboard/api/auth';
import { useAccount } from 'dashboard/composables/useAccount';
import { getAgentManagerBaseUrl } from 'dashboard/constants/agentManager';

const props = defineProps({
  type: {
    type: String,
    required: true,
  },
  entity: {
    type: Object,
    required: true,
  },
  deletePayload: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['deleteSuccess']);

const { t } = useI18n();
const store = useStore();
const deleteDialogRef = ref(null);
const i18nKey = computed(() => props.type.toUpperCase());
const { accountId } = useAccount();

const deleteEntity = async payload => {
  if (!payload) return;
  try {
    const authData = Auth.getAuthData();
    let url = '';
    const baseUrl = getAgentManagerBaseUrl();
    if (props.type === 'Assistants') {
      url = `${baseUrl}/agent-manager/api/v1/agents/${payload}`;
    } else if (props.type === 'Documents') {
      url = `${baseUrl}/agent-manager/api/v1/datasources/${payload}`;
    }
    const response = await fetch(url, {
      method: 'DELETE',
      headers: {
        'X-CHATWOOT-ACCOUNT-ID': accountId.value,
        'Access-Token': authData['access-token'],
        'Authorization': `${authData['token-type']} ${authData['access-token']}`,
      },
    });
    if (!response.ok) throw new Error('Failed to delete entity');
    emit('deleteSuccess');
    useAlert(t(`CAPTAIN.${i18nKey.value}.DELETE.SUCCESS_MESSAGE`));
  } catch (error) {
    useAlert(t(`CAPTAIN.${i18nKey.value}.DELETE.ERROR_MESSAGE`));
  }
};

const handleDialogConfirm = async () => {
  await deleteEntity(props.deletePayload || props.entity.id);
  deleteDialogRef.value?.close();
};

defineExpose({ dialogRef: deleteDialogRef });
</script>

<template>
  <Dialog
    ref="deleteDialogRef"
    type="alert"
    :title="t(`CAPTAIN.${i18nKey}.DELETE.TITLE`)"
    :description="t(`CAPTAIN.${i18nKey}.DELETE.DESCRIPTION`)"
    :confirm-button-label="t(`CAPTAIN.${i18nKey}.DELETE.CONFIRM`)"
    @confirm="handleDialogConfirm"
  />
</template>
