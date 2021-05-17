import Vue from 'vue';
import { getCampaigns } from 'widget/api/campaign';
import campaignTimer from 'widget/helpers/campaignTimer';
import {
  formatCampaigns,
  filterCampaigns,
} from 'widget/helpers/campaignHelper';
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
  initCampaigns: async (_, { allCampaigns, currentURL }) => {
    const formattedCampaigns = formatCampaigns({
      campagins: allCampaigns,
    });
    // Find all campaigns that matches the current URL
    const filteredCampaigns = filterCampaigns({
      campagins: formattedCampaigns,
      currentURL,
    });
    campaignTimer.initTimers({ allCampaigns: filteredCampaigns });
  },
  fetchCampaigns: async (
    { commit, dispatch },
    { websiteToken, currentURL }
  ) => {
    try {
      const { data } = await getCampaigns(websiteToken);
      dispatch('initCampaigns', { allCampaigns: data, currentURL });
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
