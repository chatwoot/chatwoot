import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import ChatStatusItemsAPI from '../../api/chat_status_items';

const state = {
  records: [],
  uiFlags: {
    fetchingList: false,
    fetchingItem: false,
    creatingItem: false,
    updatingItem: false,
    deletingItem: false,
  },
};

const getters = {
  getStatus(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

const actions = {
  getStatus: async function getStatus({ commit }) {
    commit(types.default.SET_STATUS_UI_FLAG, { isFetching: true });
    try {
      const response = await ChatStatusItemsAPI.get();
      commit(types.default.SET_STATUS, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.default.SET_STATUS_UI_FLAG, { isFetching: false });
    }
  },

  createStatus: async function createStatus({ commit }, STATUSObj) {
    commit(types.default.SET_STATUS_UI_FLAG, { creatingItem: true });
    try {
      const response = await ChatStatusItemsAPI.create(STATUSObj);
      commit(types.default.ADD_STATUS, response.data);
      commit(types.default.SET_STATUS_UI_FLAG, { creatingItem: false });
    } catch (error) {
      commit(types.default.SET_STATUS_UI_FLAG, { creatingItem: false });
    }
  },

  updateStatus: async function updateStatus({ commit }, { id, ...updateObj }) {
    commit(types.default.SET_STATUS_UI_FLAG, { updatingItem: true });
    try {
      const response = await ChatStatusItemsAPI.update(id, updateObj);
      commit(types.default.EDIT_STATUS, response.data);
      commit(types.default.SET_STATUS_UI_FLAG, { updatingItem: false });
    } catch (error) {
      commit(types.default.SET_STATUS_UI_FLAG, { updatingItem: false });
    }
  },

  deleteStatus: async function deleteStatus({ commit }, id) {
    commit(types.default.SET_STATUS_UI_FLAG, { deletingItem: true });
    try {
      await ChatStatusItemsAPI.delete(id);
      commit(types.default.DELETE_STATUS, id);
      commit(types.default.SET_STATUS_UI_FLAG, { deletingItem: true });
    } catch (error) {
      commit(types.default.SET_STATUS_UI_FLAG, { deletingItem: true });
    }
  },
};

const mutations = {
  [types.default.SET_STATUS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.default.SET_STATUS]: MutationHelpers.set,
  [types.default.ADD_STATUS]: MutationHelpers.create,
  [types.default.EDIT_STATUS]: MutationHelpers.update,
  [types.default.DELETE_STATUS]: MutationHelpers.destroy,
};

export default {
  state,
  getters,
  actions,
  mutations,
};
