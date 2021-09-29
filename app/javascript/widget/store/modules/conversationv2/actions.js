import conversationPublicAPI from 'widget/api/conversationPublic';
import MessagePublicAPI from 'widget/api/messagePublic';

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
        commit(
          'messageV2/addMessagesEntry',
          { conversationId, messages },
          { root: true }
        );
        commit('addMessageIdsToConversation', {
          conversationId,
          messages,
        });
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  fetchConversationById: async ({ commit }, params) => {
    const { conversationId, inboxIdentifier, contactIdentifier } = params;
    try {
      commit('setConversationUIFlag', { isFetching: true });
      const { data } = await MessagePublicAPI.get(
        inboxIdentifier,
        contactIdentifier,
        conversationId
      );

      const { messages } = data;
      commit('updateConversationEntry', data);
      commit(
        'messageV2/addMessagesEntry',
        { conversationId, messages },
        { root: true }
      );
      commit('addMessageIdsToConversation', { conversationId, messages });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setConversationUIFlag', {
        conversationId,
        uiFlags: { isFetching: false },
      });
    }
  },

  createConversation: async (
    { commit },
    { inboxIdentifier, contactIdentifier }
  ) => {
    commit('setUIFlag', { isCreating: true });
    try {
      const params = { inboxIdentifier, contactIdentifier };
      const { data } = await conversationPublicAPI.create(params);
      const { id: conversationId, messages } = data;

      commit('addConversationEntry', data);
      commit('addConversationId', conversationId);
      commit(
        'messageV2/addMessagesEntry',
        { conversationId, messages },
        { root: true }
      );
      commit('addMessageIdsToConversation', {
        conversationId,
        messages,
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isCreating: false });
    }
  },
};
