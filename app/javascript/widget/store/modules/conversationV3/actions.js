import { isEmptyObject } from 'widget/helpers/utils';
import ConversationsV3API from 'widget/api/conversationV3';

export const actions = {
  fetchAllConversations: async ({ commit }) => {
    try {
      commit('setUIFlag', { isFetching: true });
      const { data } = await ConversationsV3API.get();

      if (isEmptyObject(data)) return;

      [data].forEach(conversation => {
        const { id: conversationId, messages } = conversation;
        const { contact_last_seen_at: userLastSeenAt, status } = conversation;
        const lastMessage = messages[messages.length - 1];
        commit('addConversationEntry', conversation);
        commit('addConversationId', conversationId);
        commit('setConversationUIFlag', {
          uiFlags: {},
          conversationId,
        });
        commit('setConversationMeta', {
          meta: { userLastSeenAt, status },
          conversationId,
        });
        commit(
          'messageV3/addMessagesEntry',
          { conversationId, messages: [lastMessage] },
          { root: true }
        );
        commit('addMessageIdsToConversation', {
          conversationId,
          messages: [lastMessage],
        });
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  fetchOldMessagesIn: async ({ commit }, params) => {
    const { conversationId, beforeId } = params;

    try {
      commit('setConversationUIFlag', {
        uiFlags: { isFetching: true },
        conversationId,
      });
      const { data } = await ConversationsV3API.getMessages({
        before: beforeId,
      });

      // TODO: Filter them in getters
      // const messages = getNonDeletedMessages({ messages: data });
      const { payload: messages = [] } = data;
      commit(
        'messageV3/addMessagesEntry',
        { conversationId, messages },
        { root: true }
      );
      commit('prependMessageIdsToConversation', {
        conversationId,
        messages,
      });

      if (messages.length < 20) {
        commit('setConversationUIFlag', {
          conversationId,
          uiFlags: { allFetched: true },
        });
      }
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setConversationUIFlag', {
        conversationId,
        uiFlags: { isFetching: false },
      });
    }
  },

  addConversation: async ({ commit }, data) => {
    const { id: conversationId, messages } = data;
    const { contact_last_seen_at: userLastSeenAt } = data;

    commit('addConversationEntry', data);
    commit('addConversationId', conversationId);
    commit('setConversationUIFlag', {
      uiFlags: { isAgentTyping: false },
      conversationId,
    });
    commit('setConversationMeta', {
      meta: { userLastSeenAt },
      conversationId,
    });
    commit(
      'messageV3/addMessagesEntry',
      { conversationId, messages },
      { root: true }
    );
    commit('addMessageIdsToConversation', {
      conversationId,
      messages,
    });
    return conversationId;
  },

  createConversationWithMessage: async ({ commit }, params) => {
    commit('setUIFlag', { isCreating: true });
    try {
      const { data } = await ConversationsV3API.create(params);
      const { id: conversationId, messages } = data;
      const { contact_last_seen_at: userLastSeenAt } = data;

      commit('addConversationEntry', data);
      commit('addConversationId', conversationId);
      commit('setConversationUIFlag', {
        uiFlags: { isAgentTyping: false },
        conversationId,
      });
      commit('setConversationMeta', {
        meta: { userLastSeenAt },
        conversationId,
      });
      commit(
        'messageV3/addMessagesEntry',
        { conversationId, messages },
        { root: true }
      );
      commit('addMessageIdsToConversation', {
        conversationId,
        messages,
      });
      return conversationId;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isCreating: false });
    }
  },

  toggleAgentTypingIn({ commit }, data) {
    const { status, conversationId } = data;
    const isAgentTyping = status === 'on';

    commit('setConversationUIFlag', {
      uiFlags: { isAgentTyping },
      conversationId,
    });
  },

  toggleUserTypingIn: async ({ commit }, data) => {
    const { lastSeen, conversationId } = data;
    try {
      await ConversationsV3API.toggleTyping({ lastSeen });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setConversationUIFlag', {
        uiFlags: { isUserTyping: false },
        conversationId,
      });
    }
  },

  sendEmailTranscriptIn: async (_, data) => {
    try {
      await ConversationsV3API.emailTranscript(data);
    } catch (error) {
      // IgnoreError
    }
  },

  setUserLastSeenIn: async ({ commit, getters }, params) => {
    const { conversationId } = params;
    if (!getters.allMessagesCountIn(conversationId)) {
      return;
    }

    const userLastSeenAt = Date.now() / 1000;
    try {
      commit('setConversationMeta', {
        meta: { userLastSeenAt },
        conversationId,
      });
      await ConversationsV3API.setUserLastSeen({
        lastSeen: userLastSeenAt,
      });
    } catch (error) {
      // IgnoreError
    }
  },

  setConversationStatusIn: async ({ commit }, params) => {
    const { conversationId, status } = params;

    commit('setConversationMeta', {
      meta: { status },
      conversationId,
    });
  },

  clearConversations: ({ commit }) => {
    commit('clearConversations');
  },
};
