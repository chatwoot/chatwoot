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
  campaignHasExecuted: false,
};

const resetCampaignTimers = (
  campaigns,
  currentURL,
  websiteToken,
  isInBusinessHours
) => {
  const formattedCampaigns = formatCampaigns({ campaigns });
  // Find all campaigns that matches the current URL
  const filteredCampaigns = filterCampaigns({
    campaigns: formattedCampaigns,
    currentURL,
    isInBusinessHours,
  });
  campaignTimer.initTimers({ campaigns: filteredCampaigns }, websiteToken);
};

export const getters = {
  getHasFetched: $state => $state.uiFlags.hasFetched,
  getCampaigns: $state => $state.records,
  getActiveCampaign: $state => $state.activeCampaign,
  getCampaignHasExecuted: $state => $state.campaignHasExecuted,
};

export const actions = {
  fetchCampaigns: async (
    { commit },
    { websiteToken, currentURL, isInBusinessHours }
  ) => {
    try {
      const { data: campaigns } = await getCampaigns(websiteToken);
      commit('setCampaigns', campaigns);
      commit('setError', false);
      commit('setHasFetched', true);
      resetCampaignTimers(
        campaigns,
        currentURL,
        websiteToken,
        isInBusinessHours
      );
    } catch (error) {
      commit('setError', true);
      commit('setHasFetched', true);
    }
  },
  initCampaigns: async (
    { getters: { getCampaigns: campaigns }, dispatch },
    { currentURL, websiteToken, isInBusinessHours }
  ) => {
    if (!campaigns.length) {
      dispatch('fetchCampaigns', {
        websiteToken,
        currentURL,
        isInBusinessHours,
      });
    } else {
      resetCampaignTimers(
        campaigns,
        currentURL,
        websiteToken,
        isInBusinessHours
      );
    }
  },
  startCampaign: async (
    {
      commit,
      rootState: {
        events: { isOpen },
      },
    },
    { websiteToken, campaignId }
  ) => {
    // Disable campaign execution if widget is opened
    if (!isOpen) {
      const { data: campaigns } = await getCampaigns(websiteToken);
      // Check campaign is disabled or not
      const campaign = campaigns.find(item => item.id === campaignId);
      if (campaign) {
        commit('setActiveCampaign', campaign);
      }
    }
  },

  executeCampaign: async ({ commit }, { campaignId, websiteToken }) => {
    try {
      await triggerCampaign({ campaignId, websiteToken });
      commit('setCampaignExecuted');
      commit('setActiveCampaign', {});
    } catch (error) {
      commit('setError', true);
    }
  },
  resetCampaign: async ({ commit }) => {
    try {
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
  setCampaignExecuted($state) {
    Vue.set($state, 'campaignHasExecuted', true);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
