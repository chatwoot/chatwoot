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
  bulkIds: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['deleteSuccess']);

const { t } = useI18n();
const store = useStore();
const bulkDeleteDialogRef = ref(null);
const i18nKey = computed(() => props.type.toUpperCase());

const handleBulkDelete = async ids => {
  if (!ids) return;

  try {
    await store.dispatch(
      'captainBulkActions/handleBulkDelete',
      Array.from(props.bulkIds)
    );

    emit('deleteSuccess');
    useAlert(t(`CAPTAIN.${i18nKey.value}.BULK_DELETE.SUCCESS_MESSAGE`));
  } catch (error) {
    useAlert(t(`CAPTAIN.${i18nKey.value}.BULK_DELETE.ERROR_MESSAGE`));
  }
};

const handleDialogConfirm = async () => {
  await handleBulkDelete(Array.from(props.bulkIds));
  bulkDeleteDialogRef.value?.close();
};

defineExpose({ dialogRef: bulkDeleteDialogRef });
</script>

<template>
  <Dialog
    ref="bulkDeleteDialogRef"
    type="alert"
    :title="t(`CAPTAIN.${i18nKey}.BULK_DELETE.TITLE`)"
    :description="t(`CAPTAIN.${i18nKey}.BULK_DELETE.DESCRIPTION`)"
    :confirm-button-label="t(`CAPTAIN.${i18nKey}.BULK_DELETE.CONFIRM`)"
    @confirm="handleDialogConfirm"
  />
</template>
