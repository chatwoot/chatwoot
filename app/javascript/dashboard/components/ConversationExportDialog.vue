<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  appliedFilters: {
    type: Array,
    default: () => [],
  },
  activeFolder: {
    type: Object,
    default: null,
  },
  // Basic list context (status / assignee / inbox / team / labels / type)
  // when no advanced filters or folder are active — mirrors ConversationFinder params.
  listFilters: {
    type: Object,
    default: () => ({}),
  },
  isExporting: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['export']);

const { t } = useI18n();

const dialogRef = ref(null);
const selectedFormat = ref('xlsx');

const formatOptions = computed(() => [
  {
    value: 'xlsx',
    label: t('CHAT_LIST.EXPORT_CONVERSATION.FORMAT_XLSX'),
  },
  {
    value: 'csv',
    label: t('CHAT_LIST.EXPORT_CONVERSATION.FORMAT_CSV'),
  },
]);

const exportConversations = () => {
  let query = { payload: [] };

  if (props.activeFolder?.query) {
    query = props.activeFolder.query;
  } else if (props.appliedFilters?.length > 0) {
    query = filterQueryGenerator(props.appliedFilters);
  } else {
    // Match what the conversation list shows via ConversationFinder
    query = { payload: [], ...props.listFilters };
  }

  emit('export', {
    ...query,
    export_format: selectedFormat.value,
  });
};

const handleDialogConfirm = () => {
  exportConversations();
  dialogRef.value?.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CHAT_LIST.EXPORT_CONVERSATION.TITLE')"
    :description="t('CHAT_LIST.EXPORT_CONVERSATION.DESCRIPTION')"
    :confirm-button-label="t('CHAT_LIST.EXPORT_CONVERSATION.CONFIRM')"
    :is-loading="isExporting"
    :disable-confirm-button="isExporting"
    @confirm="handleDialogConfirm"
  >
    <fieldset class="flex flex-col gap-2">
      <legend class="text-sm font-medium text-n-slate-12">
        {{ t('CHAT_LIST.EXPORT_CONVERSATION.FORMAT_LABEL') }}
      </legend>
      <label
        v-for="option in formatOptions"
        :key="option.value"
        class="flex items-center gap-2 text-sm text-n-slate-11 cursor-pointer"
      >
        <input
          v-model="selectedFormat"
          type="radio"
          name="conversation-export-format"
          :value="option.value"
          class="accent-n-brand"
        />
        {{ option.label }}
      </label>
    </fieldset>
  </Dialog>
</template>
