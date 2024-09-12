import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import CustomApiAPI from '../../api/customApi';

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
  get: async function getCustomApi({ commit }) {
    commit(types.SET_CUSTOM_API_UI_FLAG, { isFetching: true });
    try {
      const response = await CustomApiAPI.get();

      commit(types.SET_CUSTOM_API, response.data);

      commit(types.SET_CUSTOM_API_UI_FLAG, { isFetching: false });
    } catch (error) {
      data;
      // Ignore error
    } finally {
      commit(types.SET_CUSTOM_API_UI_FLAG, { isFetching: false });
    }
  },
  create: async function createCustomApi({ commit }, appObj) {
    commit(types.SET_CUSTOM_API_UI_FLAG, { isCreating: true });
    try {
      const response = await CustomApiAPI.create(appObj);
      commit(types.CREATE_CUSTOM_API, response.data);
    } catch (error) {
      const errorMessage = error?.response?.data?.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_CUSTOM_API_UI_FLAG, { isCreating: false });
    }
  },
  update: async function updateCustomApi({ commit }, { id, ...updateObj }) {
    commit(types.SET_CUSTOM_API_UI_FLAG, { isUpdating: true });
    try {
      const response = await CustomApiAPI.update(id, updateObj);
      commit(types.EDIT_CUSTOM_API, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CUSTOM_API_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async function deleteCustomApi({ commit }, id) {
    commit(types.SET_CUSTOM_API_UI_FLAG, { isDeleting: true });
    try {
      await CustomApiAPI.delete(id);
      commit(types.DELETE_CUSTOM_API, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CUSTOM_API_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_CUSTOM_API_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_CUSTOM_API]: MutationHelpers.set,
  [types.CREATE_CUSTOM_API]: MutationHelpers.create,
  [types.EDIT_CUSTOM_API]: MutationHelpers.update,
  [types.DELETE_CUSTOM_API]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
