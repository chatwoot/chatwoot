import WhiskerAi from '../../api/whiskerAi';

const state = {
  providers: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
  },
};

export const getters = {
  getProviders: agentState => agentState.providers,
  getUIFlags: agentState => agentState.uiFlags,
};

export const actions = {
  fetchProviders: async ({ commit }) => {
    commit('setUIFlags', { isFetching: true });
    try {
      const { data } = await WhiskerAi.getProviders();
      commit('setProviders', data);
    } finally {
      commit('setUIFlags', { isFetching: false });
    }
  },

  createProvider: async ({ commit }, params) => {
    commit('setUIFlags', { isCreating: true });
    try {
      const { data } = await WhiskerAi.createProvider(params);
      commit('addProvider', data);
      return data;
    } finally {
      commit('setUIFlags', { isCreating: false });
    }
  },

  updateProvider: async ({ commit }, { id, ...params }) => {
    commit('setUIFlags', { isUpdating: true });
    try {
      const { data } = await WhiskerAi.updateProvider(id, params);
      commit('updateProvider', data);
      return data;
    } finally {
      commit('setUIFlags', { isUpdating: false });
    }
  },

  deleteProvider: async ({ commit }, id) => {
    await WhiskerAi.deleteProvider(id);
    commit('removeProvider', id);
  },

  setPrimaryProvider: async ({ commit }, id) => {
    const { data } = await WhiskerAi.setPrimary(id);
    commit('setPrimary', data);
  },
};

export const mutations = {
  setProviders($state, providers) {
    $state.providers = providers;
  },
  addProvider($state, provider) {
    $state.providers.push(provider);
  },
  updateProvider($state, updated) {
    const index = $state.providers.findIndex(p => p.id === updated.id);
    if (index !== -1) {
      $state.providers.splice(index, 1, updated);
    }
  },
  removeProvider($state, id) {
    $state.providers = $state.providers.filter(p => p.id !== id);
  },
  setPrimary($state, primary) {
    $state.providers = $state.providers.map(p => ({
      ...p,
      is_primary: p.id === primary.id,
    }));
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
