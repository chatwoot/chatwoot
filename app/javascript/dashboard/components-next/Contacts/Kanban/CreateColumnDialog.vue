<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:show', 'create']);

const { t } = useI18n();

const dialogRef = ref(null);
const columnName = ref('');

const canCreate = computed(() => {
  return columnName.value.trim().length > 0;
});

const resetForm = () => {
  columnName.value = '';
};

// Watch para controlar abertura/fechamento do dialog
watch(
  () => props.show,
  newValue => {
    // Usar nextTick para garantir que o DOM foi atualizado
    if (newValue) {
      setTimeout(() => {
        dialogRef.value?.open();
      }, 0);
    } else {
      dialogRef.value?.close();
    }
  },
  { immediate: true }
);

const handleCreate = async () => {
  if (!canCreate.value) return;

  try {
    emit('create', { name: columnName.value.trim() });
    resetForm();
    emit('update:show', false);
  } catch (error) {
    useAlert(t('KANBAN.CREATE_COLUMN_ERROR'));
  }
};

const handleClose = () => {
  resetForm();
  emit('update:show', false);
};
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('KANBAN.CREATE_COLUMN_TITLE')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <div class="flex flex-col gap-4">
      <div>
        <label class="block mb-2 text-sm font-medium text-n-slate-12">
          * {{ t('KANBAN.COLUMN_NAME_LABEL') }}
        </label>
        <input
          v-model="columnName"
          type="text"
          :placeholder="t('KANBAN.COLUMN_NAME_PLACEHOLDER')"
          class="w-full px-3 py-2 text-sm border rounded-lg bg-n-background border-n-weak text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-weak"
          @keyup.enter="handleCreate"
        />
      </div>
    </div>
    <template #footer>
      <div class="flex justify-end gap-2">
        <Button
          :label="t('KANBAN.CANCEL')"
          variant="ghost"
          color="slate"
          @click="handleClose"
        />
        <Button
          :label="t('KANBAN.ADD')"
          variant="solid"
          color="teal"
          :is-loading="isLoading"
          :disabled="!canCreate || isLoading"
          @click="handleCreate"
        />
      </div>
    </template>
  </Dialog>
</template>
