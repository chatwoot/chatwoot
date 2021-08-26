import {
  createConversationAPI,
  sendMessageAPI,
  sendAttachmentAPI,
  // getMessagesAPI,
  // toggleTyping,
  // setUserLastSeenAt,
  getConversationAPI,
  getConversationsAPI,
} from 'widget/api/conversation';
import { refreshActionCableConnector } from '../../../helpers/actionCable';

import {
  createTemporaryMessage,
  createTemporaryAttachmentMessage,
} from './helpers';

// Get activeConversation and pass it down to each action call, to
// target the right converdation
export const actions = {
  fetchAllConversations: async ({ commit }) => {
    try {
      commit('setUIFlag', { isFetching: true });
      const { data } = await getConversationsAPI();
      data.forEach(conversation => {
        const { id: conversationId, messages } = conversation;
        commit('addConversationEntry', conversation);
        commit('addConversationId', conversation.id);
        commit('addMessagesEntry', { conversationId, messages });
        commit('addMessageIds', { conversationId, messages });
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },
  fetchConversationById: async ({ commit }, params) => {
    const { conversationId } = params;
    try {
      commit('setConversationUIFlag', { isFetching: true });
      const { data } = await getConversationAPI(conversationId);

      const { messages } = data;
      commit('updateConversationEntry', data);
      commit('addMessagesEntry', { conversationId, messages });
      commit('addMessageIds', { conversationId, messages });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setConversationUIFlag', { isFetching: false });
    }
  },
  createConversation: async ({ commit }, params) => {
    commit('setConversationUIFlag', { isCreating: true });
    try {
      const { data } = await createConversationAPI(params);
      const { id: conversationId, messages } = data;

      commit('addConversationEntry', data);
      commit('addConversationId', conversationId);
      commit('addMessagesEntry', { conversationId, messages });
      commit('addMessageIds', { conversationId, messages });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setConversationUIFlag', { isCreating: false });
    }
  },
  sendMessage: async ({ commit }, params) => {
    const { content, conversationId } = params;
    const message = createTemporaryMessage({ content });
    const messages = [message];
    commit('addMessagesEntry', { conversationId, messages });
    commit('addMessageIds', { conversationId, messages });
    await sendMessageAPI(content, conversationId);
  },
  sendAttachment: async ({ commit }, params) => {
    const {
      attachment: { thumbUrl, fileType },
      conversationId,
    } = params;
    const message = createTemporaryAttachmentMessage({ thumbUrl, fileType });
    const messages = [message];
    commit('addMessagesEntry', { conversationId, messages });
    commit('addMessageIds', { conversationId, messages });
    try {
      const { data } = await sendAttachmentAPI(params);
      commit('updateAttachmentMessageStatus', {
        message: data,
        tempId: tempMessage.id,
      });
    } catch (error) {
      // Show error
    }
  },
  // fetchOldConversations: async ({ commit }, { before } = {}) => {
  //   try {
  //     commit('setConversationListLoading', true);
  //     const { data } = await getMessagesAPI({ before });
  //     const formattedMessages = getNonDeletedMessages({ messages: data });
  //     commit('setMessagesInConversation', formattedMessages);
  //     commit('setConversationListLoading', false);
  //   } catch (error) {
  //     commit('setConversationListLoading', false);
  //   }
  // },
  // clearConversations: ({ commit }) => {
  //   commit('clearConversations');
  // },
  // addOrUpdateMessage: async ({ commit }, data) => {
  //   const { id, content_attributes } = data;
  //   if (content_attributes && content_attributes.deleted) {
  //     commit('deleteMessage', id);
  //     return;
  //   }
  //   commit('pushMessageToConversation', data);
  // },
  // toggleAgentTyping({ commit }, data) {
  //   commit('toggleAgentTypingStatus', data);
  // },
  // toggleUserTyping: async (_, data) => {
  //   try {
  //     await toggleTyping(data);
  //   } catch (error) {
  //     // IgnoreError
  //   }
  // },
  // setUserLastSeen: async ({ commit, getters: appGetters }) => {
  //   if (!appGetters.getConversationSize) {
  //     return;
  //   }
  //   const lastSeen = Date.now() / 1000;
  //   try {
  //     commit('setMetaUserLastSeenAt', lastSeen);
  //     await setUserLastSeenAt({ lastSeen });
  //   } catch (error) {
  //     // IgnoreError
  //   }
  // },
};
