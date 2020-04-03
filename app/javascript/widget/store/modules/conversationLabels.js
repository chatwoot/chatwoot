import conversationLabels from '../../api/conversationLabels';

const state = {};

export const getters = {};

export const actions = {
  create: async (_, label) => {
    try {
      await conversationLabels.create(label);
    } catch (error) {
      // Ingore error
    }
  },
  destroy: async (_, label) => {
    try {
      await conversationLabels.destroy(label);
    } catch (error) {
      // Ingore error
    }
  },
};

export const mutations = {};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
