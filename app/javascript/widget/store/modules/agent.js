import Vue from 'vue';
import { getAvailableAgents } from 'widget/api/agent';

const state = {
  agents: [],
  isError: false,
  hasFetched: false,
};

const getters = {
  availableAgents: $state => $state.agents,
};

const actions = {
  fetchAvailableAgents: async ({ commit }, websiteToken) => {
    try {
      const { data } = await getAvailableAgents(websiteToken);
      const { payload = [] } = data;
      commit('setAgents', payload);
      commit('setError', false);
      commit('setHasFetched', true);
    } catch (error) {
      commit('setError', true);
      commit('setHasFetched', true);
    }
  },
};

const mutations = {
  setAgents($state, data) {
    Vue.set($state, 'agents', data);
  },
  setError($state, value) {
    Vue.set($state, 'isError', value);
  },
  setHasFetched($state, value) {
    Vue.set($state, 'hasFetched', value);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
