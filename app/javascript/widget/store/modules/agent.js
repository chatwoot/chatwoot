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
  fetchAvailableAgents: async ({ commit }) => {
    try {
      const { data } = await getAvailableAgents();
      commit('setAgents', data);
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
