import conversationPublicAPI from 'widget/api/conversationPublic';

export const actions = {
  fetchAllConversations: async (
    { commit },
    { inboxIdentifier, contactIdentifier }
  ) => {
    try {
      commit('setUIFlag', { isFetching: true });
      const { data } = await conversationPublicAPI.get(
        inboxIdentifier,
        contactIdentifier
      );
      data.forEach(conversation => {
        const { id: conversationId, messages } = conversation;
        commit('addConversationEntry', conversation);
        commit('addConversationId', conversation.id);
        commit('messagev2/addMessagesEntry', { conversationId, messages }, { root: true });
        commit('addMessageIdsToConversation', { conversationId, messages });
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  createConversation: async (
    { commit },
    { inboxIdentifier, contactIdentifier }
  ) => {
    commit('setConversationUIFlag', { isCreating: true });
    try {
      const params = { inboxIdentifier, contactIdentifier };
      const { data } = await conversationPublicAPI.create(params);
      const { id: conversationId, messages } = data;

      commit('addConversationEntry', data);
      commit('addConversationId', conversationId);
      commit('messagev2/addMessagesEntry', { conversationId, messages }, { root: true });
      commit('addMessageIdsToConversation', { conversationId, messages });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setConversationUIFlag', { isCreating: false });
    }
  },
};
