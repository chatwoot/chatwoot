/* eslint-disable no-param-reassign */
import Vue from 'vue';
import { MESSAGE_STATUS } from 'widget/helpers/constants';
import { sendMessageAPI, getConversationAPI } from 'widget/api/conversation';

export const DEFAULT_CONVERSATION = 'default';
const state = {
  conversations: {},
};

const getters = {
  getConversation: _state => _state.conversations,
};

const actions = {
  initConversations({ commit }, lastConversation) {
    commit('auth/setLastConversation', lastConversation, { root: true });
    commit('initInboxInConversations', lastConversation);
  },

  sendMessage: async (_, params) => {
    const { content } = params;
    await sendMessageAPI(content);
  },

  fetchOldConversations: async ({ commit }) => {
    try {
      const { data } = await getConversationAPI();
      commit('initMessagesInConversation', data);
    } catch (error) {
      // Handle error
      // commit('updateMessageStatusToFailed', { lastConversation, id });
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
    const { id } = message;
    const messagesInbox = $state.conversations;
    Vue.set(messagesInbox, id, message);
  },

  initMessagesInConversation(_state, payload) {
    if (!payload.length) {
      return;
    }

    payload.map(message => Vue.set(_state.conversations, message.id, message));
  },

  updateConversationId($state, data) {
    const { oldConversationId, apiConversationId } = data;
    const conversation = $state.conversations[oldConversationId];
    Vue.set($state.conversations, apiConversationId, conversation);
    Vue.delete($state.conversations, oldConversationId);
  },

  updateMessageStatusToSuccess($state, data) {
    const { apiConversationId, id } = data;
    $state.conversations[apiConversationId][id].status = MESSAGE_STATUS.SUCCESS;
  },

  updateMessageStatusToFailed($state, data) {
    const { apiConversationId, id } = data;
    $state.conversations[apiConversationId][id].status = MESSAGE_STATUS.FAILED;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
