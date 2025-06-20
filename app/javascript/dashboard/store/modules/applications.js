import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import ApplicationsAPI from '../../api/applications';

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
  getApplications($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  async get({ commit }) {
    commit(types.SET_APPLICATIONS_UI_FLAG, { isFetching: true });
    try {
      const response = await ApplicationsAPI.get();
      commit(types.SET_APPLICATIONS, response.data);
    } catch (error) {
      // Handle error silently or use proper error handling
    } finally {
      commit(types.SET_APPLICATIONS_UI_FLAG, { isFetching: false });
    }
  },

  async show(context, id) {
    try {
      const response = await ApplicationsAPI.show(id);
      return response.data;
    } catch (error) {
      throw new Error(error);
    }
  },

  async create({ commit }, data) {
    commit(types.SET_APPLICATIONS_UI_FLAG, { isCreating: true });
    try {
      const response = await ApplicationsAPI.create(data);
      commit(types.ADD_APPLICATION, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_APPLICATIONS_UI_FLAG, { isCreating: false });
    }
  },

  async update({ commit }, { id, data }) {
    commit(types.SET_APPLICATIONS_UI_FLAG, { isUpdating: true });
    try {
      const response = await ApplicationsAPI.update(id, data);
      commit(types.EDIT_APPLICATION, response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_APPLICATIONS_UI_FLAG, { isUpdating: false });
    }
  },

  async delete({ commit }, id) {
    commit(types.SET_APPLICATIONS_UI_FLAG, { isDeleting: true });
    try {
      await ApplicationsAPI.delete(id);
      commit(types.DELETE_APPLICATION, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_APPLICATIONS_UI_FLAG, { isDeleting: false });
    }
  },

  async updateLastUsed({ commit }, id) {
    try {
      const response = await ApplicationsAPI.updateLastUsed(id);
      commit(types.EDIT_APPLICATION, response.data);
    } catch (error) {
      // Handle error silently
    }
  },
};

export const mutations = {
  [types.SET_APPLICATIONS_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [types.SET_APPLICATIONS]: MutationHelpers.set,
  [types.ADD_APPLICATION]: MutationHelpers.create,
  [types.EDIT_APPLICATION]: MutationHelpers.update,
  [types.DELETE_APPLICATION]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
