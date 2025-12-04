import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import UserAssignmentsAPI from '../../api/userAssignments';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
  },
};

export const getters = {
  getAssignments(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  get: async function get({ commit }) {
    commit(types.SET_USER_ASSIGNMENT_UI_FLAG, { isFetching: true });
    try {
      const response = await UserAssignmentsAPI.get();
      commit(types.SET_USER_ASSIGNMENTS, response.data);
      return response;
    } catch (error) {
      return null;
    } finally {
      commit(types.SET_USER_ASSIGNMENT_UI_FLAG, { isFetching: false });
    }
  },
  create: async function create({ commit }, data) {
    commit(types.SET_USER_ASSIGNMENT_UI_FLAG, { isCreating: true });
    try {
      const response = await UserAssignmentsAPI.create(data);
      commit(types.ADD_USER_ASSIGNMENT, response.data);
      return response;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_USER_ASSIGNMENT_UI_FLAG, { isCreating: false });
    }
  },
  delete: async function deleteAssignment({ commit }, id) {
    commit(types.SET_USER_ASSIGNMENT_UI_FLAG, { isDeleting: true });
    try {
      await UserAssignmentsAPI.delete(id);
      commit(types.DELETE_USER_ASSIGNMENT, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_USER_ASSIGNMENT_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_USER_ASSIGNMENT_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.SET_USER_ASSIGNMENTS]: MutationHelpers.set,
  [types.ADD_USER_ASSIGNMENT]: MutationHelpers.create,
  [types.DELETE_USER_ASSIGNMENT]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
