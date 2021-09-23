import Vue from 'vue';

export const mutations = {
  addMessagesEntry($state, { messages = [] }) {
    const allMessages = $state.messages;
    const newMessages = messages.reduce(
      (obj, message) => ({
        ...obj,
        [message.id]: message,
      }),
      {}
    );
    const updatedMessages = { ...allMessages, ...newMessages };
    Vue.set($state.messages, 'byId', updatedMessages);
  },

  updateMessageEntry($state, message) {
    const messageId = message.id;
    if (!messageId) return;

    const messageById = $state.messages.byId[messageId];
    if (!messageById) return;
    if (messageId !== message.id) return;

    Vue.set($state.messages.byId, messageId, { ...message });
  },

  removeMessageEntry($state, messageId) {
    if (!messageId) return;

    Vue.delete($state.messages.byId, messageId);
  },

  removeMessageId($state, messageId) {
    if (!messageId) return;

    $state.messages.allIds = $state.messages.allIds.filter(
      id => id !== messageId
    );
  },

  setMessageUIFlag($state, { messageId, uiFlags }) {
    const flags = $state.messages.uiFlags.byId[messageId];
    $state.messages.uiFlags.byId[messageId] = {
      ...flags,
      ...uiFlags,
    };
  },
};
