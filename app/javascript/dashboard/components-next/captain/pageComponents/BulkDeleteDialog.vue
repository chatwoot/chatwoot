<script setup>
import { ref, computed } from 'vue';
// import { useStore } from 'dashboard/composables/store';
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
  hasAllSelected: {
    type: Boolean,
    default: false,
  },
  totalResponses: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['deleteSuccess']);

const { t } = useI18n();
// const store = useStore();
const bulkDeleteDialogRef = ref(null);
const i18nKey = computed(() => props.type.toUpperCase());

const bulkSelectedCount = computed(() => Array.from(props.bulkIds).length);

const handleBulkDelete = async ids => {
  if (!ids) return;

  try {
    // action
    // all = allResponseSelected
    emit('deleteSuccess');
    useAlert(
      t(`CAPTAIN.${i18nKey.value}.BULK_DELETE.SUCCESS_MESSAGE`, {
        count: !props.hasAllSelected ? bulkSelectedCount : props.totalResponses,
      })
    );
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
    :title="
      t(`CAPTAIN.${i18nKey}.BULK_DELETE.TITLE`, {
        count: !props.hasAllSelected ? bulkSelectedCount : props.totalResponses,
      })
    "
    :description="
      t(`CAPTAIN.${i18nKey}.BULK_DELETE.DESCRIPTION`, {
        count: !props.hasAllSelected ? bulkSelectedCount : props.totalResponses,
      })
    "
    :confirm-button-label="t(`CAPTAIN.${i18nKey}.BULK_DELETE.CONFIRM`)"
    @confirm="handleDialogConfirm"
  />
</template>
