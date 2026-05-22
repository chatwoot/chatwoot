<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';
import BulkDeleteDialog from 'dashboard/components-next/captain/pageComponents/BulkDeleteDialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  selectedIds: { type: Set, default: () => new Set() },
  documents: { type: Array, default: () => [] },
});

const emit = defineEmits([
  'update:selectedIds',
  'bulkSyncQueued',
  'bulkDeleteSucceeded',
]);

const { t } = useI18n();
const store = useStore();

const bulkDeleteDialog = ref(null);

const isSyncableDocument = doc =>
  !doc.pdf_document && doc.status === 'available' && !doc.sync_in_progress;

const syncableSelectedIds = computed(() => {
  if (!props.selectedIds.size) return [];
  return props.documents
    .filter(doc => props.selectedIds.has(doc.id) && isSyncableDocument(doc))
    .map(doc => doc.id);
});

const hasSyncableSelection = computed(
  () => syncableSelectedIds.value.length > 0
);

const selectAllLabel = computed(() => {
  const count = props.documents.length;
  const isAllSelected = props.selectedIds.size === count && count > 0;
  return isAllSelected
    ? t('CAPTAIN.DOCUMENTS.UNSELECT_ALL', { count })
    : t('CAPTAIN.DOCUMENTS.SELECT_ALL', { count });
});

const selectedCountLabel = computed(() =>
  t('CAPTAIN.DOCUMENTS.SELECTED', { count: props.selectedIds.size })
);

const handleBulkSync = async () => {
  const ids = syncableSelectedIds.value;
  if (!ids.length) return;

  try {
    const response = await store.dispatch('captainBulkActions/handleBulkSync', {
      ids,
    });
    const queuedCount = response?.count ?? response?.ids?.length ?? 0;
    let message = t('CAPTAIN.DOCUMENTS.BULK_SYNC.ZERO_MESSAGE');

    if (queuedCount === 1) {
      message = t('CAPTAIN.DOCUMENTS.BULK_SYNC.SUCCESS_MESSAGE_ONE');
    } else if (queuedCount > 1) {
      message = t('CAPTAIN.DOCUMENTS.BULK_SYNC.SUCCESS_MESSAGE', {
        count: queuedCount,
      });
    }

    useAlert(message);
    emit('update:selectedIds', new Set());
    if (queuedCount > 0) emit('bulkSyncQueued');
  } catch (error) {
    useAlert(t('CAPTAIN.DOCUMENTS.BULK_SYNC.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <div>
    <BulkSelectBar
      :model-value="selectedIds"
      :all-items="documents"
      :select-all-label="selectAllLabel"
      :selected-count-label="selectedCountLabel"
      :delete-label="$t('CAPTAIN.DOCUMENTS.BULK_DELETE_BUTTON')"
      class="w-fit"
      :class="{ 'mb-2': selectedIds.size > 0 }"
      @update:model-value="emit('update:selectedIds', $event)"
      @bulk-delete="bulkDeleteDialog.dialogRef.open()"
    >
      <template v-if="hasSyncableSelection" #secondaryActions>
        <Button
          :label="$t('CAPTAIN.DOCUMENTS.BULK_SYNC_BUTTON')"
          sm
          slate
          ghost
          icon="i-lucide-refresh-cw"
          class="!px-1.5"
          @click="handleBulkSync"
        />
      </template>
    </BulkSelectBar>
    <BulkDeleteDialog
      ref="bulkDeleteDialog"
      :bulk-ids="selectedIds"
      type="AssistantDocument"
      @delete-success="emit('bulkDeleteSucceeded')"
    />
  </div>
</template>
