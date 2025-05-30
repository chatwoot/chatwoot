<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

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

const emit = defineEmits(['deleteSuccess', 'confirm']);

const { t } = useI18n();
const store = useStore();
const deleteDialogRef = ref(null);
const i18nKey = computed(() => props.type.toUpperCase());

const deleteEntity = async payload => {
  if (!payload) return;

  try {
    await store.dispatch(`aiAgent${props.type}/delete`, payload);
    emit('deleteSuccess');
    useAlert(t(`AI_AGENT.${i18nKey.value}.DELETE.SUCCESS_MESSAGE`));
  } catch (error) {
    useAlert(t(`AI_AGENT.${i18nKey.value}.DELETE.ERROR_MESSAGE`));
  }
};

const handleDialogConfirm = async () => {
  emit('confirm');
  await deleteEntity(props.deletePayload || props.entity.id);
  deleteDialogRef.value?.close();
};

defineExpose({ dialogRef: deleteDialogRef });
</script>

<template>
  <Dialog
    ref="deleteDialogRef"
    type="alert"
    :title="t(`AI_AGENT.${i18nKey}.DELETE.TITLE`)"
    :description="t(`AI_AGENT.${i18nKey}.DELETE.DESCRIPTION`)"
    :confirm-button-label="t(`AI_AGENT.${i18nKey}.DELETE.CONFIRM`)"
    @confirm="handleDialogConfirm"
  />
</template>
