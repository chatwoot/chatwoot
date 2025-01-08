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
});

const { t } = useI18n();
const store = useStore();
const dialogRef = ref(null);
const i18nKey = computed(() => props.type.toUpperCase());

const deleteEntity = async id => {
  if (!id) return;

  try {
    await store.dispatch(`captain${props.type}/delete`, id);
    useAlert(t(`CAPTAIN.${i18nKey.value}.DELETE.SUCCESS_MESSAGE`));
  } catch (error) {
    useAlert(t(`CAPTAIN.${i18nKey.value}.DELETE.ERROR_MESSAGE`));
  }
};

const handleDialogConfirm = async () => {
  await deleteEntity(props.entity.id);
  dialogRef.value?.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t(`CAPTAIN.${i18nKey}.DELETE.TITLE`)"
    :description="t(`CAPTAIN.${i18nKey}.DELETE.DESCRIPTION`)"
    :confirm-button-label="t(`CAPTAIN.${i18nKey}.DELETE.CONFIRM`)"
    @confirm="handleDialogConfirm"
  />
</template>
