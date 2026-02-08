<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ResponseForm from './ResponseForm.vue';

const props = defineProps({
  selectedResponse: {
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
const responseForm = ref(null);

const updateResponse = responseDetails =>
  store.dispatch('captainResponses/update', {
    id: props.selectedResponse.id,
    ...responseDetails,
  });

const i18nKey = computed(() => `CAPTAIN.RESPONSES.${props.type.toUpperCase()}`);

const createResponse = responseDetails =>
  store.dispatch('captainResponses/create', responseDetails);

const handleSubmit = async updatedResponse => {
  try {
    if (props.type === 'edit') {
      await updateResponse(updatedResponse);
    } else {
      await createResponse(updatedResponse);
    }
    useAlert(t(`${i18nKey.value}.SUCCESS_MESSAGE`));
    dialogRef.value.close();
  } catch (error) {
    const errorMessage =
      error?.response?.message || t(`${i18nKey.value}.ERROR_MESSAGE`);
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
    :title="$t(`${i18nKey}.TITLE`)"
    :description="$t('CAPTAIN.RESPONSES.FORM_DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <ResponseForm
      ref="responseForm"
      :mode="type"
      :response="selectedResponse"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
    <template #footer />
  </Dialog>
</template>
