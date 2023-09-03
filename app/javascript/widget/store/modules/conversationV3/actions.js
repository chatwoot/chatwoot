import { isEmptyObject } from 'widget/helpers/utils';

import ConversationsV3API from 'widget/api/conversationV3';
import Conversation from 'widget/store/modules/models/Conversation';
import ConversationMeta from 'widget/store/modules/models/ConversationMeta';

export const actions = {
  fetchAllConversations: async ({ commit }) => {
    try {
      commit('setUIFlag', { isFetching: true });
      const { data } = await ConversationsV3API.get();
      Conversation.insertOrUpdate({ data });

      if (isEmptyObject(data)) return;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  fetchOldMessagesIn: async (store, params) => {
    const { conversationId, beforeId } = params;

    try {
      ConversationMeta.insertOrUpdate({
        data: {
          id: conversationId,
          isFetching: true,
        },
      });
      const { data } = await ConversationsV3API.getMessages({
        before: beforeId,
      });

      const { payload: messages = [] } = data;
      Conversation.update({
        where: conversationId,
        data: {
          messages,
        },
      });

      if (messages.length < 20) {
        ConversationMeta.update({
          where: conversationId,
          data: {
            allFetched: true,
          },
        });
      }
    } catch (error) {
      throw new Error(error);
    } finally {
      ConversationMeta.update({
        where: conversationId,
        data: {
          isFetching: false,
        },
      });
    }
  },

  addConversation: async (store, data) => {
    const { id: conversationId } = data;
    Conversation.insert({ data });

    return conversationId;
  },

  createConversationWithMessage: async ({ commit }, params) => {
    commit('setUIFlag', { isCreating: true });
    try {
      const { data } = await ConversationsV3API.create(params);
      Conversation.insert({ data });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isCreating: false });
    }
  },

  toggleAgentTypingIn(store, data) {
    const { status, conversationId } = data;
    const isAgentTyping = status === 'on';

    ConversationMeta.update({
      where: conversationId,
      data: {
        isAgentTyping,
      },
    });
  },

  toggleUserTypingIn: async (store, data) => {
    const { typingStatus, conversationId } = data;
    try {
      await ConversationsV3API.toggleTyping({ typingStatus });
      ConversationMeta.update({
        where: conversationId,
        data: {
          isUserTyping: typingStatus,
        },
      });
    } catch (error) {
      throw new Error(error);
    }
  },

  sendEmailTranscriptIn: async (_, data) => {
    try {
      await ConversationsV3API.emailTranscript(data);
    } catch (error) {
      // IgnoreError
    }
  },

  setUserLastSeenIn: async (store, params) => {
    const { conversationId } = params;

    const userLastSeenAt = Date.now() / 1000;
    try {
      await ConversationsV3API.setUserLastSeen({
        lastSeen: userLastSeenAt,
      });
      Conversation.update({
        where: conversationId,
        data: {
          contact_last_seen_at: userLastSeenAt,
        },
      });
    } catch (error) {
      // IgnoreError
    }
  },

  setConversationStatusIn: async (store, params) => {
    const { conversationId, status } = params;

    Conversation.update({
      where: conversationId,
      data: {
        status,
      },
    });
  },

  clearConversations: ({ commit }) => {
    commit('clearConversations');
  },
};
