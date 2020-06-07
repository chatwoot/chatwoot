import types from '../../mutation-types';
import ConversationApi from '../../../api/inbox/conversation';
// import MessageApi from '../../../api/inbox/message';

// actions
const actions = {
  fetchConversation: async ({ commit, dispatch }, conversationId) => {
    try {
      const { data: conversation } = await ConversationApi.show(conversationId);
      commit(types.ADD_CONVERSATION, conversation);
      dispatch('contacts/setContact', conversation.meta.sender);
      dispatch('messages/setMessages', {
        conversationId: conversation.id,
        messages: conversation.messages,
      });
    } catch (error) {
      // Ignore error
    }
  },
  fetchAllConversations: async ({ commit, dispatch }, params) => {
    commit(types.SET_CONVERSATION_UI_FLAG, { isFetching: true });
    try {
      const {
        data: {
          data: { payload: conversations, meta: metadata },
        },
      } = await ConversationApi.get(params);
      dispatch('conversationStats/set', metadata);
      dispatch('messages/setBulkMessages', conversations);
      dispatch('conversationPage/setCurrentPage', {
        filter: params.assigneeType,
        page: params.page,
      });
      dispatch(
        'contacts/setContacts',
        conversations.map(chat => chat.meta.sender)
      );
      commit(types.SET_ALL_CONVERSATION, conversations);
      if (!conversations.length) {
        dispatch('conversationPage/setEndReached', {
          filter: params.assigneeType,
        });
      }
    } finally {
      commit(types.SET_CONVERSATION_UI_FLAG, { isFetching: false });
    }
  },
  updateConversation({ commit }, conversation) {
    commit(types.UPDATE_CONVERSATION, conversation);
  },
  resetConversations({ commit }) {
    commit(types.RESET_CONVERSATION);
  },
};

export default actions;
