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

const resetCampaignTimers = (campaigns, currentURL) => {
  const formattedCampaigns = formatCampaigns({ campaigns });
  // Find all campaigns that matches the current URL
  const filteredCampaigns = filterCampaigns({
    campaigns: formattedCampaigns,
    currentURL,
  });
  campaignTimer.initTimers({ campaigns: filteredCampaigns });
};

export const getters = {
  getHasFetched: $state => $state.uiFlags.hasFetched,
  getCampaigns: $state => $state.records,
};

export const actions = {
  fetchCampaigns: async ({ commit }, { websiteToken, currentURL }) => {
    try {
      const { data: campaigns } = await getCampaigns(websiteToken);
      commit('setCampaigns', campaigns);
      commit('setError', false);
      commit('setHasFetched', true);
      resetCampaignTimers(campaigns, currentURL);
    } catch (error) {
      commit('setError', true);
      commit('setHasFetched', true);
    }
  },
  startCampaigns: async (
    { getters: { getCampaigns: campaigns }, dispatch },
    { currentURL, websiteToken }
  ) => {
    if (!campaigns.length) {
      dispatch('fetchCampaigns', { websiteToken, currentURL });
    } else {
      resetCampaignTimers(campaigns, currentURL);
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
