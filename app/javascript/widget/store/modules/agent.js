import Vue from 'vue';
import { getAvailableAgents } from 'widget/api/agent';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';

const state = {
  records: [],
  uiFlags: {
    isError: false,
    hasFetched: false,
  },
};

export const getters = {
  getHasFetched: $state => $state.uiFlags.hasFetched,
  availableAgents: $state =>
    $state.records.filter(agent => agent.availability_status === 'online'),
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
  updatePresence: async ({ commit }, data) => {
    commit('updatePresence', data);
  },
};

export const mutations = {
  setAgents($state, data) {
    Vue.set($state, 'records', data);
  },
  updatePresence: MutationHelpers.updatePresence,
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
