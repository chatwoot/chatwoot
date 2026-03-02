<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  agent: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close', 'deleted']);

const { t } = useI18n();
const store = useStore();
const dialogRef = ref(null);
const isDeleting = ref(false);

const handleConfirm = async () => {
  isDeleting.value = true;
  try {
    await store.dispatch('aiAgents/delete', props.agent.id);
    emit('deleted');
    dialogRef.value.close();
  } catch (error) {
    useAlert(error?.message || t('AI_AGENTS.DELETE.ERROR_MESSAGE'));
  } finally {
    isDeleting.value = false;
  }
};

const handleClose = () => emit('close');

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t('AI_AGENTS.DELETE.TITLE')"
    :description="t('AI_AGENTS.DELETE.DESCRIPTION', { agentName: agent.name })"
    :confirm-button-label="t('AI_AGENTS.DELETE.CONFIRM')"
    :is-loading="isDeleting"
    @confirm="handleConfirm"
    @close="handleClose"
  />
</template>
