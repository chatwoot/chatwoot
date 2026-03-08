<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageBulkActions } from 'dashboard/composables/useMessageBulkActions';
import Button from 'next/button/Button.vue';

const props = defineProps({
  messages: { type: Array, default: () => [] },
  conversationId: { type: Number, required: true },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const {
  selectedMessageIds,
  hasSelectedMessages,
  resetBulkActions,
  bulkDownloadAttachments,
  bulkCopyText,
  bulkDeleteMessages,
} = useMessageBulkActions();

const selectedCount = computed(() => selectedMessageIds.value.length);

const onClose = () => {
  resetBulkActions();
  emit('close');
};

const onDownloadAll = () => {
  bulkDownloadAttachments(props.messages);
};

const onCopyAll = () => {
  bulkCopyText(props.messages);
};

const onDeleteAll = () => {
  bulkDeleteMessages(props.conversationId);
};
</script>

<template>
  <div
    v-if="hasSelectedMessages"
    class="flex items-center justify-between px-4 py-2 bg-n-slate-2 dark:bg-n-slate-3 border-b border-n-weak"
  >
    <div class="flex items-center gap-2">
      <span class="text-sm font-medium text-n-slate-12">
        {{
          t('CONVERSATION.BULK_MESSAGE_ACTIONS.SELECTED_COUNT', {
            count: selectedCount,
          })
        }}
      </span>
    </div>
    <div class="flex items-center gap-1">
      <Button
        variant="ghost"
        size="small"
        color="slate"
        icon="i-lucide-download"
        @click="onDownloadAll"
      >
        {{ $t('CONVERSATION.DOWNLOAD') }}
      </Button>
      <Button
        variant="ghost"
        size="small"
        color="slate"
        icon="i-lucide-copy"
        @click="onCopyAll"
      >
        {{ $t('CONVERSATION.CONTEXT_MENU.COPY') }}
      </Button>
      <Button
        variant="ghost"
        size="small"
        color="slate"
        icon="i-lucide-trash-2"
        @click="onDeleteAll"
      >
        {{ $t('CONVERSATION.CONTEXT_MENU.DELETE') }}
      </Button>
      <Button
        variant="ghost"
        size="small"
        color="slate"
        icon="i-lucide-x"
        @click="onClose"
      />
    </div>
  </div>
</template>
