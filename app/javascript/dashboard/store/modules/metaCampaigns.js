import MetaCampaignsAPI from '../../api/metaCampaigns';

const state = {
  campaigns: [],
  campaignDetails: null,
  summary: {},
  uiFlags: {
    isFetchingCampaigns: false,
    isFetchingDetails: false,
    isFetchingSummary: false,
  },
};

export const getters = {
  getCampaigns(_state) {
    return _state.campaigns;
  },
  getCampaignDetails(_state) {
    return _state.campaignDetails;
  },
  getSummary(_state) {
    return _state.summary;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  async fetchCampaigns({ commit }, params) {
    commit('SET_CAMPAIGNS_UI_FLAG', { isFetchingCampaigns: true });
    try {
      const response = await MetaCampaignsAPI.getCampaigns(params);
      commit('SET_CAMPAIGNS', response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('SET_CAMPAIGNS_UI_FLAG', { isFetchingCampaigns: false });
    }
  },

  async fetchCampaignDetails({ commit }, { sourceId, params }) {
    commit('SET_CAMPAIGNS_UI_FLAG', { isFetchingDetails: true });
    try {
      const response = await MetaCampaignsAPI.getCampaignDetails(
        sourceId,
        params
      );
      commit('SET_CAMPAIGN_DETAILS', response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('SET_CAMPAIGNS_UI_FLAG', { isFetchingDetails: false });
    }
  },

  async fetchSummary({ commit }, params) {
    commit('SET_CAMPAIGNS_UI_FLAG', { isFetchingSummary: true });
    try {
      const response = await MetaCampaignsAPI.getSummary(params);
      commit('SET_SUMMARY', response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('SET_CAMPAIGNS_UI_FLAG', { isFetchingSummary: false });
    }
  },
};

export const mutations = {
  SET_CAMPAIGNS(_state, campaigns) {
    _state.campaigns = campaigns;
  },
  SET_CAMPAIGN_DETAILS(_state, details) {
    _state.campaignDetails = details;
  },
  SET_SUMMARY(_state, summary) {
    _state.summary = summary;
  },
  SET_CAMPAIGNS_UI_FLAG(_state, flags) {
    _state.uiFlags = { ..._state.uiFlags, ...flags };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
