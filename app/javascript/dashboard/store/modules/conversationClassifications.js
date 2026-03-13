import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import ConversationClassificationsAPI from '../../api/conversationClassifications';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getAll(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getById: _state => id => {
    return _state.records.find(r => r.id === Number(id)) || null;
  },
};

export const actions = {
  get: async function get({ commit }) {
    commit('SET_UI_FLAG', { isFetching: true });
    try {
      const response = await ConversationClassificationsAPI.get();
      commit('SET_RECORDS', response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit('SET_UI_FLAG', { isFetching: false });
    }
  },

  create: async function create({ commit }, params) {
    commit('SET_UI_FLAG', { isCreating: true });
    try {
      const response = await ConversationClassificationsAPI.create(params);
      commit('ADD_RECORD', response.data);
    } catch (error) {
      const errorMessage = error?.response?.data?.message;
      throw new Error(errorMessage);
    } finally {
      commit('SET_UI_FLAG', { isCreating: false });
    }
  },

  update: async function update({ commit }, { id, ...params }) {
    commit('SET_UI_FLAG', { isUpdating: true });
    try {
      const response = await ConversationClassificationsAPI.update(id, params);
      commit('EDIT_RECORD', response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('SET_UI_FLAG', { isUpdating: false });
    }
  },

  delete: async function deleteRecord({ commit }, id) {
    commit('SET_UI_FLAG', { isDeleting: true });
    try {
      await ConversationClassificationsAPI.delete(id);
      commit('DELETE_RECORD', id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('SET_UI_FLAG', { isDeleting: false });
    }
  },
};

export const mutations = {
  SET_UI_FLAG(_state, data) {
    _state.uiFlags = { ..._state.uiFlags, ...data };
  },
  SET_RECORDS: MutationHelpers.set,
  ADD_RECORD: MutationHelpers.create,
  EDIT_RECORD: MutationHelpers.update,
  DELETE_RECORD: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
