<script setup>
import { ref, computed, defineExpose } from 'vue';
import { useI18n } from 'vue-i18n';
import { messageTimestamp } from 'shared/helpers/timeHelper';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  currentContent: {
    type: String,
    default: '',
  },
  currentEditedAt: {
    type: Number,
    default: null,
  },
  previousContents: {
    type: Array,
    default: () => [],
  },
});

const { t } = useI18n();
const dialogRef = ref(null);

const open = () => dialogRef.value?.open();
const close = () => dialogRef.value?.close();

defineExpose({ open, close });

const history = computed(() => {
  const entries = (props.previousContents || []).map(entry => ({
    content: entry.content,
    editedAt: entry.editedAt,
  }));

  return [
    {
      content: props.currentContent,
      editedAt: props.currentEditedAt,
      isCurrent: true,
    },
    ...entries.slice().reverse(),
  ];
});

const formatTimestamp = timestamp => {
  if (!timestamp) return '';
  return messageTimestamp(timestamp, 'LLL d, h:mm a');
};
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CONVERSATION.EDIT_HISTORY.TITLE')"
    :description="t('CONVERSATION.EDIT_HISTORY.DESCRIPTION')"
    :show-confirm-button="false"
    :cancel-button-label="t('CONVERSATION.EDIT_HISTORY.CLOSE')"
    width="lg"
    overflow-y-auto
  >
    <div class="flex flex-col gap-3 max-h-96 overflow-y-auto">
      <div
        v-for="(entry, index) in history"
        :key="index"
        class="rounded-lg bg-n-alpha-2 p-3 flex flex-col gap-1"
      >
        <div class="flex items-center justify-between text-xs text-n-slate-11">
          <span class="font-medium">
            {{
              entry.isCurrent
                ? t('CONVERSATION.EDIT_HISTORY.CURRENT')
                : t('CONVERSATION.EDIT_HISTORY.PREVIOUS')
            }}
          </span>
          <time v-if="entry.editedAt">{{
            formatTimestamp(entry.editedAt)
          }}</time>
        </div>
        <p class="text-sm text-n-slate-12 whitespace-pre-wrap break-words m-0">
          {{ entry.content }}
        </p>
      </div>
      <p
        v-if="history.length === 1"
        class="text-sm text-n-slate-11 text-center"
      >
        {{ t('CONVERSATION.EDIT_HISTORY.EMPTY') }}
      </p>
    </div>
  </Dialog>
</template>
