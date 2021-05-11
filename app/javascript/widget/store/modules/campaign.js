import Vue from 'vue';
import { getCampaigns } from 'widget/api/campaign';
import { startTimer } from 'widget/helpers/campaignTimer';

const state = {
  records: [],
  uiFlags: {
    isError: false,
    hasFetched: false,
  },
};

export const getters = {
  getHasFetched: $state => $state.uiFlags.hasFetched,
  fetchCampaigns: $state => $state.records,
};

export const actions = {
  fetchCampaigns: async ({ commit }, websiteToken) => {
    try {
      const { data } = await getCampaigns(websiteToken);
      startTimer({ allCampaigns: data });
      commit('setCampaigns', data);
      commit('setError', false);
      commit('setHasFetched', true);
    } catch (error) {
      commit('setError', true);
      commit('setHasFetched', true);
    }
  },
};

export const mutations = {
  setCampaigns($state, data) {
    Vue.set($state, 'records', data);
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
