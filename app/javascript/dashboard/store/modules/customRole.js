import { throwErrorMessage } from 'dashboard/store/utils/api';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import CustomRoleAPI from '../../api/customRole';

export const state = {
  records: [],
  uiFlags: {
    fetchingList: false,
    creatingItem: false,
    updatingItem: false,
    deletingItem: false,
  },
};

export const getters = {
  getCustomRoles($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  getCustomRole: async function getCustomRole({ commit }) {
    commit(types.default.SET_CUSTOM_ROLE_UI_FLAG, { fetchingList: true });
    try {
      const response = await CustomRoleAPI.get();
      commit(types.default.SET_CUSTOM_ROLE, response.data);
      commit(types.default.SET_CUSTOM_ROLE_UI_FLAG, { fetchingList: false });
    } catch (error) {
      commit(types.default.SET_CUSTOM_ROLE_UI_FLAG, { fetchingList: false });
    }
  },

  createCustomRole: async function createCustomRole({ commit }, customRoleObj) {
    commit(types.default.SET_CUSTOM_ROLE_UI_FLAG, { creatingItem: true });
    try {
      const response = await CustomRoleAPI.create(customRoleObj);
      commit(types.default.ADD_CUSTOM_ROLE, response.data);
      commit(types.default.SET_CUSTOM_ROLE_UI_FLAG, { creatingItem: false });
      return response.data;
    } catch (error) {
      commit(types.default.SET_CUSTOM_ROLE_UI_FLAG, { creatingItem: false });
      return throwErrorMessage(error);
    }
  },

  updateCustomRole: async function updateCustomRole(
    { commit },
    { id, ...updateObj }
  ) {
    commit(types.default.SET_CUSTOM_ROLE_UI_FLAG, { updatingItem: true });
    try {
      const response = await CustomRoleAPI.update(id, updateObj);
      commit(types.default.EDIT_CUSTOM_ROLE, response.data);
      commit(types.default.SET_CUSTOM_ROLE_UI_FLAG, { updatingItem: false });
      return response.data;
    } catch (error) {
      commit(types.default.SET_CUSTOM_ROLE_UI_FLAG, { updatingItem: false });
      return throwErrorMessage(error);
    }
  },

  deleteCustomRole: async function deleteCustomRole({ commit }, id) {
    commit(types.default.SET_CUSTOM_ROLE_UI_FLAG, { deletingItem: true });
    try {
      await CustomRoleAPI.delete(id);
      commit(types.default.DELETE_CUSTOM_ROLE, id);
      commit(types.default.SET_CUSTOM_ROLE_UI_FLAG, { deletingItem: true });
      return id;
    } catch (error) {
      commit(types.default.SET_CUSTOM_ROLE_UI_FLAG, { deletingItem: true });
      return throwErrorMessage(error);
    }
  },
};

export const mutations = {
  [types.default.SET_CUSTOM_ROLE_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.default.SET_CUSTOM_ROLE]: MutationHelpers.set,
  [types.default.ADD_CUSTOM_ROLE]: MutationHelpers.create,
  [types.default.EDIT_CUSTOM_ROLE]: MutationHelpers.update,
  [types.default.DELETE_CUSTOM_ROLE]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
