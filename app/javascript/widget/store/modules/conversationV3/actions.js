import endPoints from 'widget/api/endPoints';

import ConversationsV3API from 'widget/api/conversationV3';
import Conversation from 'widget/models/Conversation';
import ConversationMeta from 'widget/models/ConversationMeta';
import Message from 'widget/models/Message';

export const actions = {
  fetchAllConversations: async ({ commit }) => {
    try {
      commit('setUIFlag', { isFetching: true });
      Conversation.api().get(
        `/api/v1/widget/conversations${window.location.search}`
      );
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
      const result = await Message.api().get(
        `/api/v1/widget/messages${window.location.search}&before=${beforeId}`
      );

      if (result.entities.messages.length < 20) {
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
      const { content } = params;
      const urlData = endPoints.createConversation(content);
      Conversation.api().post(urlData.url, urlData.params);
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
