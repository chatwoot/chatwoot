import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import MacrosAPI from '../../api/macros';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  uiFlags: {
    isFetchingItem: false,
    isFetching: false,
    isCreating: false,
    isDeleting: false,
    isUpdating: false,
    isExecuting: false,
  },
};

export const getters = {
  getMacros($state) {
    return $state.records;
  },
  getMacro: $state => id => {
    return $state.records.find(record => record.id === Number(id));
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async function getMacros({ commit }) {
    commit(types.SET_MACROS_UI_FLAG, { isFetching: true });
    try {
      const response = await MacrosAPI.get();
      commit(types.SET_MACROS, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_MACROS_UI_FLAG, { isFetching: false });
    }
  },
  getSingleMacro: async function getMacroById({ commit }, macroId) {
    commit(types.SET_MACROS_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await MacrosAPI.show(macroId);
      commit(types.ADD_MACRO, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_MACROS_UI_FLAG, { isFetchingItem: false });
    }
  },
  create: async function createMacro({ commit }, macrosObj) {
    commit(types.SET_MACROS_UI_FLAG, { isCreating: true });
    try {
      const response = await MacrosAPI.create(macrosObj);
      commit(types.ADD_MACRO, response.data.payload);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_MACROS_UI_FLAG, { isCreating: false });
    }
  },
  execute: async function executeMacro({ commit }, macrosObj) {
    commit(types.SET_MACROS_UI_FLAG, { isExecuting: true });
    try {
      await MacrosAPI.executeMacro(macrosObj);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_MACROS_UI_FLAG, { isExecuting: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_MACROS_UI_FLAG, { isUpdating: true });
    try {
      const response = await MacrosAPI.update(id, updateObj);
      commit(types.EDIT_MACRO, response.data.payload);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_MACROS_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_MACROS_UI_FLAG, { isDeleting: true });
    try {
      await MacrosAPI.delete(id);
      commit(types.DELETE_MACRO, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_MACROS_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_MACROS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.ADD_MACRO]: MutationHelpers.setSingleRecord,
  [types.SET_MACROS]: MutationHelpers.set,
  [types.EDIT_MACRO]: MutationHelpers.update,
  [types.DELETE_MACRO]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
