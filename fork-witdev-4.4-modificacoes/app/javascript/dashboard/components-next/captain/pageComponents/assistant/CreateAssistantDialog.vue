<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

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
const store = useStore();

const dialogRef = ref(null);
const assistantForm = ref(null);

const updateAssistant = assistantDetails =>
  store.dispatch('captainAssistants/update', {
    id: props.selectedAssistant.id,
    ...assistantDetails,
  });

const i18nKey = computed(
  () => `CAPTAIN.ASSISTANTS.${props.type.toUpperCase()}`
);

const createAssistant = assistantDetails =>
  store.dispatch('captainAssistants/create', assistantDetails);

const handleSubmit = async updatedAssistant => {
  try {
    if (props.type === 'edit') {
      await updateAssistant(updatedAssistant);
    } else {
      await createAssistant(updatedAssistant);
    }
    useAlert(t(`${i18nKey.value}.SUCCESS_MESSAGE`));
    dialogRef.value.close();
  } catch (error) {
    const errorMessage = error?.message || t(`${i18nKey.value}.ERROR_MESSAGE`);
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
