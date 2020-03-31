import events from 'widget/api/events';

const state = {};

const getters = {};

const actions = {
  create: async (_, { name }) => {
    try {
      await events.create(name);
    } catch (error) {
      // Ignore error
    }
  },
};

const mutations = {};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
