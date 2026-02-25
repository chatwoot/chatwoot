<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import CustomToolForm from './CustomToolForm.vue';

const props = defineProps({
  selectedTool: {
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

const updateTool = toolDetails =>
  store.dispatch('captainCustomTools/update', {
    id: props.selectedTool.id,
    ...toolDetails,
  });

const i18nKey = computed(
  () => `CAPTAIN.CUSTOM_TOOLS.${props.type.toUpperCase()}`
);

const createTool = toolDetails =>
  store.dispatch('captainCustomTools/create', toolDetails);

const handleSubmit = async updatedTool => {
  try {
    if (props.type === 'edit') {
      await updateTool(updatedTool);
    } else {
      await createTool(updatedTool);
    }
    useAlert(t(`${i18nKey.value}.SUCCESS_MESSAGE`));
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
    width="2xl"
    :title="$t(`${i18nKey}.TITLE`)"
    :description="$t('CAPTAIN.CUSTOM_TOOLS.FORM_DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <CustomToolForm
      :mode="type"
      :tool="selectedTool"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
    <template #footer />
  </Dialog>
</template>
