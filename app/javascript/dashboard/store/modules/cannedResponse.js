import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import CannedResponseAPI from '../../api/cannedResponse';

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
  getCannedResponses(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

const actions = {
  getCannedResponse: async function getCannedResponse(
    { commit },
    { searchKey } = {}
  ) {
    commit(types.default.SET_CANNED_UI_FLAG, { fetchingList: true });
    try {
      const response = await CannedResponseAPI.get({ searchKey });
      commit(types.default.SET_CANNED, response.data);
      commit(types.default.SET_CANNED_UI_FLAG, { fetchingList: false });
    } catch (error) {
      commit(types.default.SET_CANNED_UI_FLAG, { fetchingList: false });
    }
  },

  createCannedResponse: async function createCannedResponse(
    { commit },
    cannedObj
  ) {
    commit(types.default.SET_CANNED_UI_FLAG, { creatingItem: true });
    try {
      const response = await CannedResponseAPI.create(cannedObj);
      commit(types.default.ADD_CANNED, response.data);
      commit(types.default.SET_CANNED_UI_FLAG, { creatingItem: false });
    } catch (error) {
      commit(types.default.SET_CANNED_UI_FLAG, { creatingItem: false });
    }
  },

  updateCannedResponse: async function updateCannedResponse(
    { commit },
    { id, ...updateObj }
  ) {
    commit(types.default.SET_CANNED_UI_FLAG, { updatingItem: true });
    try {
      const response = await CannedResponseAPI.update(id, updateObj);
      commit(types.default.EDIT_CANNED, response.data);
      commit(types.default.SET_CANNED_UI_FLAG, { updatingItem: false });
    } catch (error) {
      commit(types.default.SET_CANNED_UI_FLAG, { updatingItem: false });
    }
  },

  deleteCannedResponse: async function deleteCannedResponse({ commit }, id) {
    commit(types.default.SET_CANNED_UI_FLAG, { deletingItem: true });
    try {
      await CannedResponseAPI.delete(id);
      commit(types.default.DELETE_CANNED, id);
      commit(types.default.SET_CANNED_UI_FLAG, { deletingItem: true });
    } catch (error) {
      commit(types.default.SET_CANNED_UI_FLAG, { deletingItem: true });
    }
  },
};

const mutations = {
  [types.default.SET_CANNED_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.default.SET_CANNED]: MutationHelpers.set,
  [types.default.ADD_CANNED]: MutationHelpers.create,
  [types.default.EDIT_CANNED]: MutationHelpers.update,
  [types.default.DELETE_CANNED]: MutationHelpers.destroy,
};

export default {
  state,
  getters,
  actions,
  mutations,
};
