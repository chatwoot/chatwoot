import {
  appendItems,
  appendItemIds,
  updateItemEntry,
  removeItemEntry,
  removeItemId,
  setItemUIFlag,
} from 'shared/helpers/vuex/mutationHelpers';

export const mutations = {
  addMessagesEntry($state, { messages = [] }) {
    appendItems($state, 'messages', messages);
  },

  addMessageIds($state, { messages }) {
    appendItemIds($state, 'messages', messages);
  },

  updateMessageEntry($state, message) {
    updateItemEntry($state, 'messages', message);
  },

  removeMessageEntry($state, messageId) {
    removeItemEntry($state, 'messages', messageId);
  },

  removeMessageId($state, messageId) {
    removeItemId($state, 'messages', messageId);
  },

  setMessageUIFlag($state, { messageId, uiFlags }) {
    setItemUIFlag($state, 'messages', messageId, uiFlags);
  },
};
