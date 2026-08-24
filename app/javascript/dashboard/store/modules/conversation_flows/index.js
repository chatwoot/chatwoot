import ConversationFlowsApi from '../../api/conversationFlows';

const state = {
  flows: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
  },
};

export const getters = {
  getFlows: flowState => flowState.flows,
  getUIFlags: flowState => flowState.uiFlags,
};

export const actions = {
  fetchFlows: async ({ commit }) => {
    commit('setUIFlags', { isFetching: true });
    try {
      const { data } = await ConversationFlowsApi.getFlows();
      commit('setFlows', data);
    } finally {
      commit('setUIFlags', { isFetching: false });
    }
  },

  createFlow: async ({ commit }, params) => {
    commit('setUIFlags', { isCreating: true });
    try {
      const { data } = await ConversationFlowsApi.createFlow(params);
      commit('addFlow', data);
      return data;
    } finally {
      commit('setUIFlags', { isCreating: false });
    }
  },

  updateFlow: async ({ commit }, { id, ...params }) => {
    commit('setUIFlags', { isUpdating: true });
    try {
      const { data } = await ConversationFlowsApi.updateFlow(id, params);
      commit('updateFlow', data);
      return data;
    } finally {
      commit('setUIFlags', { isUpdating: false });
    }
  },

  deleteFlow: async ({ commit }, id) => {
    await ConversationFlowsApi.deleteFlow(id);
    commit('removeFlow', id);
  },

  toggleFlow: async ({ commit }, id) => {
    const { data } = await ConversationFlowsApi.toggleFlow(id);
    commit('updateFlow', data);
  },
};

export const mutations = {
  setFlows($state, flows) {
    $state.flows = flows;
  },
  addFlow($state, flow) {
    $state.flows.unshift(flow);
  },
  updateFlow($state, updated) {
    const index = $state.flows.findIndex(f => f.id === updated.id);
    if (index !== -1) {
      $state.flows.splice(index, 1, updated);
    }
  },
  removeFlow($state, id) {
    $state.flows = $state.flows.filter(f => f.id !== id);
  },
  setUIFlags($state, flags) {
    $state.uiFlags = { ...$state.uiFlags, ...flags };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
