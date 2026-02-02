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

const i18nKey = computed(
  () => `CAPTAIN_SETTINGS.MCP_SERVERS.${props.type.toUpperCase()}`
);

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
    useAlert(t(`${i18nKey.value}.SUCCESS_MESSAGE`));
    emit('created', result);
    dialogRef.value.close();
  } catch (error) {
    const errorMessage =
      parseAPIErrorResponse(error) || t(`${i18nKey.value}.ERROR_MESSAGE`);
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
    :title="$t(`${i18nKey}.TITLE`)"
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
