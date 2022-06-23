import types from '../mutation-types';
import BulkActionsAPI from '../../api/bulkActions';

export const state = {
  uiFlags: {
    isUpdating: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  process: async function processAction({ commit }, payload) {
    commit(types.SET_BULK_ACTIONS_FLAG, { isUpdating: true });
    try {
      await BulkActionsAPI.create(payload);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_BULK_ACTIONS_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.SET_BULK_ACTIONS_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
