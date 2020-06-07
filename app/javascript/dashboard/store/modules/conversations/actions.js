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
      dispatch('conversationPage/setCurrentPage', {
        filter: params.assigneeType,
        page: params.page,
      });
      dispatch(
        'contacts/setContacts',
        conversations.map(chat => chat.meta.sender)
      );
      dispatch('setConversations', conversations);
      if (!conversations.length) {
        dispatch('conversationPage/setEndReached', {
          filter: params.assigneeType,
        });
      }
    } finally {
      commit(types.SET_CONVERSATION_UI_FLAG, { isFetching: false });
    }
  },
  updateConversation({ commit, getters }, conversation) {
    const currentInboxId = getters['conversationFilter/getCurrentInboxId'];
    if (currentInboxId && currentInboxId !== conversation.inbox_id) {
      return;
    }
    commit(types.UPDATE_CONVERSATION, conversation);
  },
  resetConversations({ commit }) {
    commit(types.RESET_CONVERSATION);
  },
  setConversations({ commit, dispatch }, conversations) {
    dispatch('messages/setBulkMessages', conversations);
    commit(types.SET_ALL_CONVERSATION, conversations);
  },
  toggleStatus: async ({ commit }, data) => {
    try {
      const {
        data: {
          payload: { current_status: status, conversation_id: conversationId },
        },
      } = await ConversationApi.toggleStatus(data);
      commit(types.RESOLVE_CONVERSATION, { conversationId, status });
    } catch (error) {
      // Handle error
    }
  },

  assignAgent: async ({ commit }, { conversationId, agentId }) => {
    try {
      const response = await ConversationApi.assignAgent({
        conversationId,
        agentId,
      });
      commit(types.ASSIGN_AGENT, { conversationId, assignee: response.data });
    } catch (error) {
      // Handle error
    }
  },

  muteConversation: async ({ commit }, conversationId) => {
    try {
      await ConversationApi.mute(conversationId);
      commit(types.default.MUTE_CONVERSATION);
    } catch (error) {
      //
    }
  },
};

export default actions;
