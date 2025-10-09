import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import MarketingCampaignsAPI from '../../api/marketingCampaigns';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

const getters = {
  getMarketingCampaigns: $state => $state.records,
  getUIFlags: $state => $state.uiFlags,
};

const actions = {
  get: async ({ commit }) => {
    commit(types.SET_MARKETING_CAMPAIGN_FETCHING_STATUS, true);
    try {
      const response = await MarketingCampaignsAPI.get();
      commit(types.SET_MARKETING_CAMPAIGNS, response.data);
      commit(types.SET_MARKETING_CAMPAIGN_FETCHING_STATUS, false);
    } catch (error) {
      commit(types.SET_MARKETING_CAMPAIGN_FETCHING_STATUS, false);
      throw new Error(error);
    }
  },
  create: async ({ commit }, payload) => {
    commit(types.SET_MARKETING_CAMPAIGN_CREATING_STATUS, true);
    try {
      const response = await MarketingCampaignsAPI.create(payload);
      commit(types.ADD_MARKETING_CAMPAIGN, response.data);
      commit(types.SET_MARKETING_CAMPAIGN_CREATING_STATUS, false);
    } catch (error) {
      commit(types.SET_MARKETING_CAMPAIGN_CREATING_STATUS, false);
      throw new Error(error);
    }
  },
  update: async ({ commit }, { id, ...payload }) => {
    commit(types.SET_MARKETING_CAMPAIGN_UPDATING_STATUS, true);
    try {
      const response = await MarketingCampaignsAPI.update(id, payload);
      commit(types.EDIT_MARKETING_CAMPAIGN, response.data);
      commit(types.SET_MARKETING_CAMPAIGN_UPDATING_STATUS, false);
    } catch (error) {
      commit(types.SET_MARKETING_CAMPAIGN_UPDATING_STATUS, false);
      throw new Error(error);
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_MARKETING_CAMPAIGN_DELETING_STATUS, true);
    try {
      await MarketingCampaignsAPI.delete(id);
      commit(types.DELETE_MARKETING_CAMPAIGN, id);
      commit(types.SET_MARKETING_CAMPAIGN_DELETING_STATUS, false);
    } catch (error) {
      commit(types.SET_MARKETING_CAMPAIGN_DELETING_STATUS, false);
      throw new Error(error);
    }
  },
};

export const mutations = {
  [types.SET_MARKETING_CAMPAIGN_FETCHING_STATUS]($state, status) {
    $state.uiFlags.isFetching = status;
  },
  [types.SET_MARKETING_CAMPAIGN_CREATING_STATUS]($state, status) {
    $state.uiFlags.isCreating = status;
  },
  [types.SET_MARKETING_CAMPAIGN_UPDATING_STATUS]($state, status) {
    $state.uiFlags.isUpdating = status;
  },
  [types.SET_MARKETING_CAMPAIGN_DELETING_STATUS]($state, status) {
    $state.uiFlags.isDeleting = status;
  },

  [types.SET_MARKETING_CAMPAIGNS]: MutationHelpers.set,
  [types.ADD_MARKETING_CAMPAIGN]: MutationHelpers.create,
  [types.EDIT_MARKETING_CAMPAIGN]: MutationHelpers.update,
  [types.DELETE_MARKETING_CAMPAIGN]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
