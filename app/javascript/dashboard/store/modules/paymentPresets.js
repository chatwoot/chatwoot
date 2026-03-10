import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import PaymentPresetsAPI from '../../api/paymentPresets';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
  },
};

export const getters = {
  getPresets(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  get: async function getPresets({ commit }) {
    commit(types.SET_PAYMENT_PRESET_UI_FLAG, { isFetching: true });
    try {
      const response = await PaymentPresetsAPI.get();
      commit(types.SET_PAYMENT_PRESETS, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_PAYMENT_PRESET_UI_FLAG, { isFetching: false });
    }
  },

  create: async function createPreset({ commit }, presetObj) {
    commit(types.SET_PAYMENT_PRESET_UI_FLAG, { isCreating: true });
    try {
      const response = await PaymentPresetsAPI.create(presetObj);
      commit(types.ADD_PAYMENT_PRESET, response.data);
    } catch (error) {
      throw new Error(error?.response?.data?.message || error);
    } finally {
      commit(types.SET_PAYMENT_PRESET_UI_FLAG, { isCreating: false });
    }
  },

  delete: async function deletePreset({ commit }, id) {
    commit(types.SET_PAYMENT_PRESET_UI_FLAG, { isDeleting: true });
    try {
      await PaymentPresetsAPI.delete(id);
      commit(types.DELETE_PAYMENT_PRESET, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PAYMENT_PRESET_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_PAYMENT_PRESET_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.SET_PAYMENT_PRESETS]: MutationHelpers.set,
  [types.ADD_PAYMENT_PRESET]: MutationHelpers.create,
  [types.DELETE_PAYMENT_PRESET]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
