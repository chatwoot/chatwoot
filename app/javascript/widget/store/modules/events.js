import events from 'widget/api/events';

const actions = {
  create: async (_, { name }) => {
    try {
      await events.create(name);
    } catch (error) {
      console.log(error);
    }
  },
};

export default {
  namespaced: true,
  state: {},
  getters: {},
  actions,
  mutations: {},
};
