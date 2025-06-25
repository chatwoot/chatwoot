import { getAvailableAgents } from 'widget/api/agent';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import { getFromCache, setCache } from 'shared/helpers/cache';

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

const CACHE_KEY_PREFIX = 'chatwoot_available_agents_';

export const actions = {
  fetchAvailableAgents: async ({ commit }, websiteToken) => {
    try {
      const cachedData = getFromCache(`${CACHE_KEY_PREFIX}${websiteToken}`);
      if (cachedData) {
        commit('setAgents', cachedData);
        commit('setError', false);
        commit('setHasFetched', true);
        return;
      }

      const { data } = await getAvailableAgents(websiteToken);
      const { payload = [] } = data;
      setCache(`${CACHE_KEY_PREFIX}${websiteToken}`, payload);
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
    $state.records = data;
  },
  updatePresence: MutationHelpers.updatePresence,
  setError($state, value) {
    $state.uiFlags.isError = value;
  },
  setHasFetched($state, value) {
    $state.uiFlags.hasFetched = value;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
