import Vue from 'vue';

export const mutations = {
  setUIFlag($state, uiFlags) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...uiFlags,
    };
  },

  addConversationEntry($state, conversation) {
    if (!conversation.id) return;

    Vue.set($state.conversations.byId, conversation.id, {
      ...conversation,
      messages: [],
    });
  },

  addConversationId($state, conversationId) {
    $state.conversations.allIds.push(conversationId);
  },

  updateConversationEntry($state, conversation, content_attributes = {}) {
    if (!conversation.id) return;
    if (!$state.conversations.allIds.includes(conversation.id)) return;

    Vue.set($state.conversations.byId, conversation.id, {
      ...conversation,
      content_attributes: {
        ...(conversation.content_attributes || {}),
        ...content_attributes,
      },
    });
  },

  removeConversationEntry($state, conversationId) {
    if (!conversationId) return;

    Vue.set($state.conversations.byId, conversationId, undefined);
  },

  removeConversationId($state, conversationId) {
    $state.conversations.allIds = $state.conversations.allIds.filter(
      id => id !== conversationId
    );
  },

  setConversationUIFlag($state, { conversationId, uiFlags }) {
    const flags = $state.conversations.uiFlags.byId[conversationId];
    $state.conversations.uiFlags.byId[conversationId] = {
      ...flags,
      ...uiFlags,
    };
  },

  addMessageIdsToConversation($state, { conversationId, messages }) {
    const conversationById = $state.conversations.byId[conversationId];
    if (!conversationById) return;

    const messageIds = messages.map(message => message.id);
    const updatedMessageIds = [...conversationById.messages, ...messageIds];
    Vue.set(conversationById, 'messages', updatedMessageIds);
  },

  removeMessageIdFromConversation($state, { conversationId, messageId }) {
    if (!messageId || !conversationId) return;

    const conversationById = $state.conversations.byId[conversationId];
    if (!conversationById) return;

    conversationById.messages = conversationById.messages.filter(
      id => id !== messageId
    );
  },
};
