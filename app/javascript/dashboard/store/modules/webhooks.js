import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import webHookAPI from '../../api/webhooks';

const state = {
  records: [],
  uiFlags: {
    fetchingList: false,
    creatingItem: false,
    deletingItem: false,
    updatingItem: false,
  },
};

export const getters = {
  getWebhooks(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  async get({ commit }) {
    commit(types.default.SET_WEBHOOK_UI_FLAG, { fetchingList: true });
    try {
      const response = await webHookAPI.get();
      commit(types.default.SET_WEBHOOK, response.data.payload.webhooks);
      commit(types.default.SET_WEBHOOK_UI_FLAG, { fetchingList: false });
    } catch (error) {
      commit(types.default.SET_WEBHOOK_UI_FLAG, { fetchingList: false });
    }
  },

  async create({ commit }, params) {
    commit(types.default.SET_WEBHOOK_UI_FLAG, { creatingItem: true });
    try {
      const response = await webHookAPI.create(params);
      const {
        payload: { webhook },
      } = response.data;
      commit(types.default.ADD_WEBHOOK, webhook);
      commit(types.default.SET_WEBHOOK_UI_FLAG, { creatingItem: false });
    } catch (error) {
      commit(types.default.SET_WEBHOOK_UI_FLAG, { creatingItem: false });
      throw error;
    }
  },

  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.default.SET_WEBHOOK_UI_FLAG, { updatingItem: true });
    try {
      const response = await webHookAPI.update(id, updateObj);
      commit(types.default.UPDATE_WEBHOOK, response.data.payload.webhook);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.default.SET_WEBHOOK_UI_FLAG, { updatingItem: false });
    }
  },

  async delete({ commit }, id) {
    commit(types.default.SET_WEBHOOK_UI_FLAG, { deletingItem: true });
    try {
      await webHookAPI.delete(id);
      commit(types.default.DELETE_WEBHOOK, id);
      commit(types.default.SET_WEBHOOK_UI_FLAG, { deletingItem: false });
    } catch (error) {
      commit(types.default.SET_WEBHOOK_UI_FLAG, { deletingItem: false });
      throw error;
    }
  },
};

export const mutations = {
  [types.default.SET_WEBHOOK_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_WEBHOOK]: MutationHelpers.set,
  [types.default.ADD_WEBHOOK]: MutationHelpers.create,
  [types.default.DELETE_WEBHOOK]: MutationHelpers.destroy,
  [types.default.UPDATE_WEBHOOK]: MutationHelpers.update,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
