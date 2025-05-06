import QuickReplies from '../../api/quickReplies';

export const state = () => ({
  quickReplies: [],
});

export const getters = {
  quickReplies: state => state.quickReplies,
};

export const mutations = {
  setQuickReplies(state, quickReplies) {
    state.quickReplies = quickReplies;
  },
};

export const actions = {
  async get({ commit }, { search } = {}) {
    try {
      const response = await QuickReplies.show({ search });
      commit('setQuickReplies', response.data);
    } catch (error) {
      console.error('Failed to fetch quick replies:', error);
    }
  },

  create(_, { name, content }) {
    return QuickReplies.create({ name, content });
  },

  update(_, { id, name, content }) {
    return QuickReplies.update({ id, name, content });
  },

  destroy(_, { id }) {
    return QuickReplies.destroy({ id });
  },
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions,
};
