import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import CampaignsAPI from '../../api/campaigns';

export const state = {
  records: [],
  uiFlags: {
    isCreating: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  create: async function createCampaigns({ commit }, campaignObj) {
    commit(types.SET_CAMPAIGN_UI_FLAG, { isCreating: true });
    try {
      const response = await CampaignsAPI.create(campaignObj);
      commit(types.ADD_CAMPAIGN, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CAMPAIGN_UI_FLAG, { isCreating: false });
    }
  },
};

export const mutations = {
  [types.SET_CAMPAIGN_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.ADD_CAMPAIGN]: MutationHelpers.create,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
