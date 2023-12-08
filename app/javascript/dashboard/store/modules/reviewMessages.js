import Vue from 'vue';
import BootstrapAPI from '../../api/bootstrap';
import db from '../../database';

const state = {
  messages: {},
  groupedByConversation: {},
};

const MUTATIONS = {
  SET_MESSAGES: 'SET_MESSAGES',
};

export const getters = {
  getAll: $state => $state.messages,
  getGroupedAll: $state => $state.messages,
  getProcessedAll: $state =>
    Object.keys($state.messages)
      .sort((c1, c2) => c1 - c2)
      .map(conversationId => ({
        ...$state.messages[conversationId],
      })),
  getOne: $state => id => $state.messages[id],
};

export const actions = {
  async bootstrap({ commit }) {
    const oldMessages = await db.messages.toArray();
    commit(MUTATIONS.SET_MESSAGES, oldMessages);

    // const { data } = await BootstrapAPI.messages();
    // db.messages.bulkPut(data);
    // commit(MUTATIONS.SET_MESSAGES, data);
  },
};

export const mutations = {
  [MUTATIONS.SET_MESSAGES]($state, messages) {
    messages.forEach(message => {
      Vue.set($state.messages, message.id, message);
      Vue.set($state.groupedByConversation, message.conversation_id, message);
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
