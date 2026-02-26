<script setup>
import { ref } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ConnectMcpServerForm from './ConnectMcpServerForm.vue';

const props = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['close']);
const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);

const handleSubmit = async payload => {
  try {
    await store.dispatch('captainAssistantMcpServers/create', {
      assistantId: props.assistantId,
      ...payload,
    });
    useAlert(t('CAPTAIN.MCP_SERVERS.CREATE.SUCCESS_MESSAGE'));
    dialogRef.value.close();
  } catch (error) {
    const errorMessage =
      error?.message || t('CAPTAIN.MCP_SERVERS.CREATE.ERROR_MESSAGE');
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
    type="create"
    :title="$t('CAPTAIN.MCP_SERVERS.CREATE.TITLE')"
    :description="$t('CAPTAIN.MCP_SERVERS.FORM_DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <ConnectMcpServerForm
      :assistant-id="assistantId"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
    <template #footer />
  </Dialog>
</template>
