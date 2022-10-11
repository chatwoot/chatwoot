import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import DashboardAppsAPI from '../../api/dashboardApps';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getRecords(_state) {
    return _state.records;
  },
};

export const actions = {
  get: async function getDashboardApps({ commit }) {
    commit(types.SET_DASHBOARD_APPS_UI_FLAG, { isFetching: true });
    try {
      const response = await DashboardAppsAPI.get();
      commit(types.SET_DASHBOARD_APPS, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_DASHBOARD_APPS_UI_FLAG, { isFetching: false });
    }
  },
  create: async function createApp({ commit }, appObj) {
    commit(types.SET_DASHBOARD_APPS_UI_FLAG, { isCreating: true });
    try {
      const response = await DashboardAppsAPI.create(appObj);
      commit(types.CREATE_DASHBOARD_APP, response.data);
    } catch (error) {
      const errorMessage = error?.response?.data?.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_DASHBOARD_APPS_UI_FLAG, { isCreating: false });
    }
  },
  update: async function updateApp({ commit }, { id, ...updateObj }) {
    commit(types.SET_DASHBOARD_APPS_UI_FLAG, { isUpdating: true });
    try {
      const response = await DashboardAppsAPI.update(id, updateObj);
      commit(types.EDIT_DASHBOARD_APP, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_DASHBOARD_APPS_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async function deleteApp({ commit }, id) {
    commit(types.SET_DASHBOARD_APPS_UI_FLAG, { isDeleting: true });
    try {
      await DashboardAppsAPI.delete(id);
      commit(types.DELETE_DASHBOARD_APP, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_DASHBOARD_APPS_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_DASHBOARD_APPS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_DASHBOARD_APPS]: MutationHelpers.set,
  [types.CREATE_DASHBOARD_APP]: MutationHelpers.create,
  [types.EDIT_DASHBOARD_APP]: MutationHelpers.update,
  [types.DELETE_DASHBOARD_APP]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
