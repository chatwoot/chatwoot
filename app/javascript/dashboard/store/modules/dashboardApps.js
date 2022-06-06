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
};

export const mutations = {
  [types.SET_DASHBOARD_APPS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_DASHBOARD_APPS]: MutationHelpers.set,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
