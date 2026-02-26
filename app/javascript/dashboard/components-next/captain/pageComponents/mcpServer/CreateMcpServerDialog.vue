<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import McpServerForm from './McpServerForm.vue';

const props = defineProps({
  selectedServer: {
    type: Object,
    default: () => ({}),
  },
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
});

const emit = defineEmits(['close', 'created']);
const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);

const dialogCopy = computed(() => {
  const copyMap = {
    create: {
      title: t('CAPTAIN_SETTINGS.MCP_SERVERS.CREATE.TITLE'),
      successMessage: t('CAPTAIN_SETTINGS.MCP_SERVERS.CREATE.SUCCESS_MESSAGE'),
      errorMessage: t('CAPTAIN_SETTINGS.MCP_SERVERS.CREATE.ERROR_MESSAGE'),
    },
    edit: {
      title: t('CAPTAIN_SETTINGS.MCP_SERVERS.EDIT.TITLE'),
      successMessage: t('CAPTAIN_SETTINGS.MCP_SERVERS.EDIT.SUCCESS_MESSAGE'),
      errorMessage: t('CAPTAIN_SETTINGS.MCP_SERVERS.EDIT.ERROR_MESSAGE'),
    },
  };

  return copyMap[props.type] || copyMap.create;
});

const updateServer = serverDetails =>
  store.dispatch('captainMcpServers/update', {
    id: props.selectedServer.id,
    ...serverDetails,
  });

const createServer = serverDetails =>
  store.dispatch('captainMcpServers/create', serverDetails);

const handleSubmit = async serverData => {
  try {
    let result;
    if (props.type === 'edit') {
      result = await updateServer(serverData);
    } else {
      result = await createServer(serverData);
    }
    useAlert(dialogCopy.value.successMessage);
    emit('created', result);
    dialogRef.value.close();
  } catch (error) {
    const errorMessage =
      parseAPIErrorResponse(error) || dialogCopy.value.errorMessage;
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
    width="xl"
    :title="dialogCopy.title"
    :description="$t('CAPTAIN_SETTINGS.MCP_SERVERS.FORM.HELP_TEXT')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <McpServerForm
      :mode="type"
      :server="selectedServer"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
    <template #footer />
  </Dialog>
</template>
