import EnterpriseAccountAPI from 'dashboard/api/enterprise/account';
import { throwErrorMessage } from '../utils/api';

const state = {
  topupOptions: [],
  uiFlags: {
    isLoading: false,
    isProcessing: false,
  },
};

export const getters = {
  topupOptions($state) {
    return $state.topupOptions;
  },
  uiFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  async fetchTopupOptions({ commit }) {
    commit('SET_UI_FLAG', { isLoading: true });
    try {
      const response = await EnterpriseAccountAPI.getV2TopupOptions();
      commit('SET_TOPUP_OPTIONS', response.data.topup_options);
      return response.data.topup_options;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isLoading: false });
    }
  },

  async purchaseTopup({ commit }, { credits }) {
    commit('SET_UI_FLAG', { isProcessing: true });
    try {
      const response = await EnterpriseAccountAPI.purchaseTopup(credits);
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isProcessing: false });
    }
  },
};

export const mutations = {
  SET_UI_FLAG($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  SET_TOPUP_OPTIONS($state, options) {
    $state.topupOptions = options || [];
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
