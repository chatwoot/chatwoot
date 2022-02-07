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
  },
  activeCampaign: {},
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
  getCampaigns: $state => $state.records,
  getActiveCampaign: $state => $state.activeCampaign,
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
      resetCampaignTimers(
        campaigns,
        currentURL,
        websiteToken,
        isInBusinessHours
      );
    } catch (error) {
      commit('setError', true);
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
        appConfig: { isWidgetOpen },
      },
    },
    { websiteToken, campaignId }
  ) => {
    // Disable campaign execution if widget is opened
    if (!isWidgetOpen) {
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
      commit(
        'conversation/setConversationUIFlag',
        { isCreating: true },
        { root: true }
      );
      await triggerCampaign({ campaignId, websiteToken });
      commit('setActiveCampaign', {});
    } catch (error) {
      commit('setError', true);
    } finally {
      commit(
        'conversation/setConversationUIFlag',
        { isCreating: false },
        { root: true }
      );
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
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
