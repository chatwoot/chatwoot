import Vue from 'vue';
import { getAvailableAgents } from 'widget/api/agent';

const state = {
  agents: [],
  uiFlags: {
    isError: false,
    hasFetched: false,
  },
};

export const getters = {
  availableAgents: $state =>
    $state.agents.filter(agent => agent.availability_status === 'online'),
};

export const actions = {
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

export const mutations = {
  setAgents($state, data) {
    Vue.set($state, 'agents', data);
  },
  setError($state, value) {
    Vue.set($state.uiFlags, 'isError', value);
  },
  setHasFetched($state, value) {
    Vue.set($state.uiFlags, 'hasFetched', value);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
