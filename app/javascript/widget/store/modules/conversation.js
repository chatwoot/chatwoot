/* eslint-disable no-param-reassign */
import Vue from 'vue';
import { sendMessageAPI, getConversationAPI } from 'widget/api/conversation';
import { MESSAGE_TYPE } from 'widget/helpers/constants';
import getUuid from '../../helpers/uuid';

export const createTemporaryMessage = content => {
  const timestamp = new Date().getTime();
  return {
    id: getUuid(),
    content,
    status: 'in_progress',
    created_at: timestamp,
    message_type: MESSAGE_TYPE.INCOMING,
  };
};

export const findUndeliveredMessage = (messageInbox, { content }) =>
  Object.values(messageInbox).filter(
    message => message.content === content && message.status === 'in_progress'
  );

export const DEFAULT_CONVERSATION = 'default';
const state = {
  conversations: {},
  uiFlags: {
    allMessagesLoaded: false,
    isFetchingList: false,
  },
};

const getters = {
  getConversation: _state => _state.conversations,
  getConversationSize: _state => Object.keys(_state.conversations).length,
  getUIFlags: _state => _state.uiFlags,
  getEarliestMessage: _state => {
    const conversation = Object.values(_state.conversations);
    if (conversation.length) {
      return conversation[0];
    }
    return {};
  },
};

const actions = {
  sendMessage: async ({ commit }, params) => {
    const { content } = params;
    commit('pushMessageToConversations', createTemporaryMessage(content));
    await sendMessageAPI(content);
  },

  fetchOldConversations: async ({ commit }, { before } = {}) => {
    try {
      commit('setConversationListLoading', true);
      const { data } = await getConversationAPI({ before });
      commit('initMessagesInConversation', data);
      commit('setConversationListLoading', false);
    } catch (error) {
      commit('setConversationListLoading', false);
    }
  },

  addMessage({ commit }, data) {
    commit('pushMessageToConversations', data);
  },
};

const mutations = {
  initInboxInConversations($state, lastConversation) {
    Vue.set($state.conversations, lastConversation, {});
  },

  pushMessageToConversations($state, message) {
    const { id, status, message_type: type } = message;
    const messagesInbox = $state.conversations;
    const isMessageIncoming = type === MESSAGE_TYPE.INCOMING;
    const isTemporaryMessage = status === 'in_progress';

    if (!isMessageIncoming || isTemporaryMessage) {
      Vue.set(messagesInbox, id, message);
      return;
    }

    const [messageInConversation] = findUndeliveredMessage(
      messagesInbox,
      message
    );

    if (!messageInConversation) {
      Vue.set(messagesInbox, id, message);
    } else {
      Vue.delete(messagesInbox, messageInConversation.id);
      Vue.set(messagesInbox, id, message);
    }
  },

  initMessagesInConversation($state, payload) {
    if (!payload.length) {
      $state.uiFlags.allMessagesLoaded = true;
      return;
    }

    payload.map(message => Vue.set($state.conversations, message.id, message));
  },

  setConversationListLoading($state, status) {
    $state.uiFlags.isFetchingList = status;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
