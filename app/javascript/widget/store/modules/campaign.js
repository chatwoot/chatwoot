import Vue from 'vue';
import { getCampaigns, triggerCampaign } from 'widget/api/campaign';
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
  activeCampaign: {},
};

const resetCampaignTimers = (campaigns, currentURL, websiteToken) => {
  const formattedCampaigns = formatCampaigns({ campaigns });
  // Find all campaigns that matches the current URL
  const filteredCampaigns = filterCampaigns({
    campaigns: formattedCampaigns,
    currentURL,
  });
  campaignTimer.initTimers({ campaigns: filteredCampaigns }, websiteToken);
};

export const getters = {
  getHasFetched: $state => $state.uiFlags.hasFetched,
  getCampaigns: $state => $state.records,
  getActiveCampaign: $state => $state.activeCampaign,
};

export const actions = {
  fetchCampaigns: async ({ commit }, { websiteToken, currentURL }) => {
    try {
      const { data: campaigns } = await getCampaigns(websiteToken);
      commit('setCampaigns', campaigns);
      commit('setError', false);
      commit('setHasFetched', true);
      resetCampaignTimers(campaigns, currentURL, websiteToken);
    } catch (error) {
      commit('setError', true);
      commit('setHasFetched', true);
    }
  },
  initCampaigns: async (
    { getters: { getCampaigns: campaigns }, dispatch },
    { currentURL, websiteToken }
  ) => {
    if (!campaigns.length) {
      dispatch('fetchCampaigns', { websiteToken, currentURL });
    } else {
      resetCampaignTimers(campaigns, currentURL, websiteToken);
    }
  },
  startCampaign: async ({ commit }, { websiteToken, campaignId }) => {
    const { data: campaigns } = await getCampaigns(websiteToken);
    const campaign = campaigns.find(item => item.id === campaignId);
    if (campaign) {
      commit('setActiveCampaign', campaign);
    }
  },

  executeCampaign: async ({ commit }, { campaignId, websiteToken }) => {
    try {
      await triggerCampaign({ campaignId, websiteToken });
      commit('setActiveCampaign', {});
    } catch (error) {
      commit('setError', true);
    }
  },
};

export const mutations = {
  setCampaigns($state, data) {
    Vue.set($state, 'records', data);
  },
  setActiveCampaign($state, data) {
    Vue.set($state, 'activeCampaign', data);
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
