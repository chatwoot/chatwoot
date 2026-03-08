import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useBulkDownload } from './useBulkDownload';
import { copyTextToClipboard } from 'shared/helpers/clipboard';

export function useMessageBulkActions() {
  const store = useStore();
  const { t } = useI18n();

  const selectedMessageIds = useMapGetter(
    'messageBulkActions/getSelectedMessageIds'
  );
  const hasSelectedMessages = useMapGetter(
    'messageBulkActions/hasSelectedMessages'
  );
  const isMessageSelected = useMapGetter(
    'messageBulkActions/isMessageSelected'
  );

  const { downloadAllFiles } = useBulkDownload();

  function selectMessage(messageId) {
    store.dispatch('messageBulkActions/setSelectedMessageIds', messageId);
  }

  function deSelectMessage(messageId) {
    store.dispatch('messageBulkActions/removeSelectedMessageIds', messageId);
  }

  function toggleMessageSelection(messageId) {
    store.dispatch('messageBulkActions/toggleMessageSelection', messageId);
  }

  function resetBulkActions() {
    store.dispatch('messageBulkActions/clearSelectedMessageIds');
  }

  function selectAllMessages(messages) {
    const messageIds = messages.map(msg => msg.id);
    store.dispatch('messageBulkActions/setSelectedMessageIds', messageIds);
  }

  async function bulkDownloadAttachments(messages) {
    const selectedIds = selectedMessageIds.value;
    const selectedMessages = messages.filter(msg =>
      selectedIds.includes(msg.id)
    );

    const allAttachments = selectedMessages.flatMap(
      msg => msg.attachments || []
    );
    if (allAttachments.length === 0) {
      useAlert(t('CONVERSATION.BULK_MESSAGE_ACTIONS.NO_ATTACHMENTS'));
      return;
    }

    const result = await downloadAllFiles(allAttachments);
    if (result.failed > 0) {
      useAlert(t('CONVERSATION.BULK_DOWNLOAD_ERROR'));
    }
    resetBulkActions();
  }

  async function bulkCopyText(messages) {
    const selectedIds = selectedMessageIds.value;
    const selectedMessages = messages.filter(msg =>
      selectedIds.includes(msg.id)
    );

    const textContents = selectedMessages
      .map(msg => msg.content)
      .filter(Boolean)
      .join('\n\n---\n\n');

    if (!textContents) {
      useAlert(t('CONVERSATION.BULK_MESSAGE_ACTIONS.NO_TEXT'));
      return;
    }

    try {
      await copyTextToClipboard(textContents);
      useAlert(t('CONVERSATION.BULK_MESSAGE_ACTIONS.COPY_SUCCESS'));
    } catch {
      useAlert(t('CONVERSATION.BULK_MESSAGE_ACTIONS.COPY_ERROR'));
    }
    resetBulkActions();
  }

  async function bulkDeleteMessages(conversationId) {
    const selectedIds = selectedMessageIds.value;
    if (selectedIds.length === 0) return;

    try {
      await Promise.all(
        selectedIds.map(messageId =>
          store.dispatch('conversations/deleteMessage', {
            conversationId,
            messageId,
          })
        )
      );
      useAlert(t('CONVERSATION.BULK_MESSAGE_ACTIONS.DELETE_SUCCESS'));
    } catch {
      useAlert(t('CONVERSATION.BULK_MESSAGE_ACTIONS.DELETE_ERROR'));
    }
    resetBulkActions();
  }

  return {
    selectedMessageIds,
    hasSelectedMessages,
    isMessageSelected,
    selectMessage,
    deSelectMessage,
    toggleMessageSelection,
    resetBulkActions,
    selectAllMessages,
    bulkDownloadAttachments,
    bulkCopyText,
    bulkDeleteMessages,
  };
}
