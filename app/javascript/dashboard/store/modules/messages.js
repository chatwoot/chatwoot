import Vue from 'vue';
import * as types from '../mutation-types';

const state = {
  records: {},
};

export const getters = {
  getMessages: $state => conversationId => {
    const messages = Object.values($state.records[conversationId] || {});
    return messages.sort((m1, m2) => m1.id - m2.id);
  },
};

export const actions = {
  setMessages({ commit }, { conversationId, messages }) {
    commit(types.default.SET_ACTIVE_INBOX, { conversationId, messages });
  },
};

export const mutations = {
  [types.default.SET_MESSAGES]($state, { conversationId, messages }) {
    if (!$state.records[conversationId]) {
      $state.records[conversationId] = {};
    }

    messages.forEach(message => {
      Vue.set($state.records[conversationId], message.id, message);
    });
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
