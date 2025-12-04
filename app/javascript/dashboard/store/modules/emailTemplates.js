import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import EmailTemplatesAPI from '../../api/emailTemplates';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isUpdating: false,
  },
};

export const getters = {
  getTemplates(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  get: async function get({ commit }) {
    commit(types.SET_EMAIL_TEMPLATE_UI_FLAG, { isFetching: true });
    try {
      const response = await EmailTemplatesAPI.get();
      commit(types.SET_EMAIL_TEMPLATES, response.data);
      return response;
    } catch (error) {
      return null;
    } finally {
      commit(types.SET_EMAIL_TEMPLATE_UI_FLAG, { isFetching: false });
    }
  },
  activate: async function activate({ commit }, id) {
    commit(types.SET_EMAIL_TEMPLATE_UI_FLAG, { isUpdating: true });
    try {
      const response = await EmailTemplatesAPI.activate(id);
      return response;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_EMAIL_TEMPLATE_UI_FLAG, { isUpdating: false });
    }
  },
  deactivate: async function deactivate({ commit }, id) {
    commit(types.SET_EMAIL_TEMPLATE_UI_FLAG, { isUpdating: true });
    try {
      const response = await EmailTemplatesAPI.deactivate(id);
      return response;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_EMAIL_TEMPLATE_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.SET_EMAIL_TEMPLATE_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.SET_EMAIL_TEMPLATES]: MutationHelpers.set,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
