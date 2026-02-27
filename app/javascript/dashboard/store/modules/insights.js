import InsightsAPI from '../../api/insights';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getInsights: $state => $state.records,
  getUIFlags: $state => $state.uiFlags,
};

export const actions = {
  get: async ({ commit }) => {
    commit('SET_UI_FLAG', { isFetching: true });
    try {
      const response = await InsightsAPI.get();
      commit('SET_RECORDS', response.data);
    } catch (error) {
      // Handle error
    } finally {
      commit('SET_UI_FLAG', { isFetching: false });
    }
  },
  create: async ({ commit }, insightData) => {
    commit('SET_UI_FLAG', { isCreating: true });
    try {
      const response = await InsightsAPI.create(insightData);
      commit('ADD_RECORD', response.data);
    } catch (error) {
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateData }) => {
    commit('SET_UI_FLAG', { isUpdating: true });
    try {
      const response = await InsightsAPI.update(id, updateData);
      commit('UPDATE_RECORD', response.data);
    } catch (error) {
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit('SET_UI_FLAG', { isDeleting: true });
    try {
      await InsightsAPI.delete(id);
      commit('DELETE_RECORD', id);
    } catch (error) {
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isDeleting: false });
    }
  },
};

export const mutations = {
  SET_RECORDS($state, data) {
    $state.records = data;
  },
  ADD_RECORD($state, data) {
    $state.records.push(data);
  },
  UPDATE_RECORD($state, data) {
    const index = $state.records.findIndex(r => r.id === data.id);
    if (index !== -1) {
      $state.records.splice(index, 1, data);
    }
  },
  DELETE_RECORD($state, id) {
    $state.records = $state.records.filter(r => r.id !== id);
  },
  SET_UI_FLAG($state, flags) {
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
