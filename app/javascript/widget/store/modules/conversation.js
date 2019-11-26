/* eslint-disable no-param-reassign */
import Vue from 'vue';
import { sendMessageAPI, getConversationAPI } from 'widget/api/conversation';

export const DEFAULT_CONVERSATION = 'default';
const state = {
  conversations: {},
};

const getters = {
  getConversation: _state => _state.conversations,
  getConversationSize: _state => Object.keys(_state.conversations).length,
};

const actions = {
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
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
