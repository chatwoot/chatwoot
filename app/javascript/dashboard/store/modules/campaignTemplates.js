import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import CampaignTemplatesAPI from '../../api/campaignTemplates';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getCampaignTemplates(_state) {
    return _state.records;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.SET_CAMPAIGN_TEMPLATE_UI_FLAG, { isFetching: true });
    try {
      const response = await CampaignTemplatesAPI.get();
      commit(types.SET_CAMPAIGN_TEMPLATES, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_CAMPAIGN_TEMPLATE_UI_FLAG, { isFetching: false });
    }
  },
  create: async ({ commit }, templateObj) => {
    commit(types.SET_CAMPAIGN_TEMPLATE_UI_FLAG, { isCreating: true });
    try {
      const response = await CampaignTemplatesAPI.create(templateObj);
      commit(types.ADD_CAMPAIGN_TEMPLATE, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CAMPAIGN_TEMPLATE_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_CAMPAIGN_TEMPLATE_UI_FLAG, { isUpdating: true });
    try {
      const response = await CampaignTemplatesAPI.update(id, updateObj);
      commit(types.EDIT_CAMPAIGN_TEMPLATE, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CAMPAIGN_TEMPLATE_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_CAMPAIGN_TEMPLATE_UI_FLAG, { isDeleting: true });
    try {
      await CampaignTemplatesAPI.delete(id);
      commit(types.DELETE_CAMPAIGN_TEMPLATE, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CAMPAIGN_TEMPLATE_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_CAMPAIGN_TEMPLATE_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.ADD_CAMPAIGN_TEMPLATE]: MutationHelpers.create,
  [types.SET_CAMPAIGN_TEMPLATES]: MutationHelpers.set,
  [types.EDIT_CAMPAIGN_TEMPLATE]: MutationHelpers.update,
  [types.DELETE_CAMPAIGN_TEMPLATE]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
