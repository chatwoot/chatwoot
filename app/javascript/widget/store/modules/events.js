import events from 'widget/api/events';

const state = {
  isOpen: false,
}

const actions = {
  create: async (_, { name }) => {
    try {
      await events.create(name);
    } catch (error) {
      // Ignore error
    }
  },
};

const mutations = {
  toggleOpen($state) {
    $state.isOpen = !$state.isOpen;
  }
};

export default {
  namespaced: true,
  state,
  getters: {},
  actions,
  mutations,
};
