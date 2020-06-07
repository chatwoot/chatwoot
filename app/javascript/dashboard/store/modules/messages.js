import Vue from 'vue';
import types from '../mutation-types';
import MessageApi from '../../api/inbox/message';

const state = {
  records: {},
  uiFlags: {
    dataFetchComplete: {},
  },
};

export const getters = {
  getMessages: $state => conversationId => {
    const messages = Object.values(
      $state.records[Number(conversationId)] || {}
    );
    return messages.sort((m1, m2) => m1.id - m2.id);
  },
};

export const actions = {
  addMessage({ commit }, message) {
    commit(types.ADD_MESSAGE, message);
  },
  setBulkMessages({ commit }, conversations) {
    commit(types.SET_BULK_MESSAGES, conversations);
  },
  setMessages({ commit }, { conversationId, messages }) {
    commit(types.SET_MESSAGES, { conversationId, messages });
  },
  resetMessages({ commit }) {
    commit(types.RESET_MESSAGES);
  },

  sendAttachment: async ({ commit }, data) => {
    try {
      const response = await MessageApi.sendAttachment(data);
      commit(types.default.ADD_MESSAGE, response.data);
    } catch (error) {
      // Handle error
    }
  },

  sendMessage: async ({ commit }, data) => {
    try {
      const response = await MessageApi.create(data);
      commit(types.default.ADD_MESSAGE, response.data);
    } catch (error) {
      // Handle error
    }
  },
  fetchPreviousMessages: async (
    { commit, dispatch },
    { conversationId, before }
  ) => {
    try {
      const {
        data: { payload: messages },
      } = await MessageApi.getPreviousMessages({ conversationId, before });
      commit(types.SET_MESSAGES, { conversationId, messages });
      if (messages.length < 20) {
        dispatch(
          'conversationMetadata/setMessagesLoaded',
          { conversationId },
          { root: true }
        );
      }
    } catch (error) {
      // Handle error
    }
  },
};

export const mutations = {
  [types.SET_BULK_MESSAGES]($state, conversations) {
    conversations.forEach(conversation => {
      const { id: conversationId, messages } = conversation;

      if (!$state.records[conversationId]) {
        Vue.set($state.records, conversationId, {});
      }

      messages.forEach(message => {
        Vue.set($state.records[conversationId], message.id, message);
      });
    });
  },
  [types.SET_MESSAGES]($state, { conversationId, messages }) {
    if (!$state.records[conversationId]) {
      Vue.set($state.records, conversationId, {});
    }

    messages.forEach(message => {
      Vue.set($state.records[conversationId], message.id, message);
    });
  },
  [types.ADD_MESSAGE]($state, message) {
    const conversationId = message.conversation_id;

    if (!$state.records[conversationId]) {
      return;
    }

    Vue.set($state.records[conversationId], message.id, message);
  },
  [types.RESET_MESSAGES]($state) {
    $state.records = {};
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
