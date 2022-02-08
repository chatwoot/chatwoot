/* eslint no-param-reassign: 0 */
import axios from 'axios';
import Vue from 'vue';
import * as types from '../mutation-types';
import authAPI from '../../api/auth';
import createAxios from '../../helper/APIHelper';
import actionCable from '../../helper/actionCable';
import { setUser, getHeaderExpiry, clearCookiesOnLogout } from '../utils/api';
import { DEFAULT_REDIRECT_URL } from '../../constants';

const state = {
  currentUser: {
    id: null,
    account_id: null,
    channel: null,
    email: null,
    name: null,
    provider: null,
    uid: null,
    subscription: {
      state: null,
      expiry: null,
    },
  },
  currentAccountId: null,
};

// getters
export const getters = {
  isLoggedIn($state) {
    return !!$state.currentUser.id;
  },

  getCurrentUserID(_state) {
    return _state.currentUser.id;
  },

  getUISettings(_state) {
    return _state.currentUser.ui_settings || {};
  },

  getCurrentUserAvailability(_state) {
    const { accounts = [] } = _state.currentUser;
    const [currentAccount = {}] = accounts.filter(
      account => account.id === _state.currentAccountId
    );
    return currentAccount.availability;
  },

  getCurrentAccountId(_, __, rootState) {
    if (rootState.route.params && rootState.route.params.accountId) {
      return Number(rootState.route.params.accountId);
    }
    return null;
  },

  getCurrentRole(_state) {
    const { accounts = [] } = _state.currentUser;
    const [currentAccount = {}] = accounts.filter(
      account => account.id === _state.currentAccountId
    );
    return currentAccount.role;
  },

  getCurrentUser(_state) {
    return _state.currentUser;
  },

  getMessageSignature(_state) {
    const { message_signature: messageSignature } = _state.currentUser;

    return messageSignature || '';
  },
};

// actions
export const actions = {
  login({ commit }, credentials) {
    return new Promise((resolve, reject) => {
      authAPI
        .login(credentials)
        .then(() => {
          commit(types.default.SET_CURRENT_USER);
          window.axios = createAxios(axios);
          actionCable.init(Vue);
          window.location = DEFAULT_REDIRECT_URL;
          resolve();
        })
        .catch(error => {
          reject(error);
        });
    });
  },
  async validityCheck(context) {
    try {
      const response = await authAPI.validityCheck();
      setUser(response.data.payload.data, getHeaderExpiry(response), {
        setUserInSDK: true,
      });
      context.commit(types.default.SET_CURRENT_USER);
    } catch (error) {
      if (error?.response?.status === 401) {
        clearCookiesOnLogout();
      }
    }
  },
  setUser({ commit, dispatch }) {
    if (authAPI.isLoggedIn()) {
      commit(types.default.SET_CURRENT_USER);
      dispatch('validityCheck');
    } else {
      commit(types.default.CLEAR_USER);
    }
  },
  logout({ commit }) {
    commit(types.default.CLEAR_USER);
  },

  updateProfile: async ({ commit }, params) => {
    // eslint-disable-next-line no-useless-catch
    try {
      const response = await authAPI.profileUpdate(params);
      setUser(response.data, getHeaderExpiry(response));
      commit(types.default.SET_CURRENT_USER);
    } catch (error) {
      throw error;
    }
  },

  deleteAvatar: async ({ commit }) => {
    try {
      await authAPI.deleteAvatar();
      commit(types.default.SET_CURRENT_USER);
    } catch (error) {
      // Ignore error
    }
  },

  updateUISettings: async ({ commit }, params) => {
    try {
      commit(types.default.SET_CURRENT_USER_UI_SETTINGS, params);
      const response = await authAPI.updateUISettings(params);
      setUser(response.data, getHeaderExpiry(response));
      commit(types.default.SET_CURRENT_USER);
    } catch (error) {
      // Ignore error
    }
  },

  updateAvailability: async ({ commit, dispatch }, params) => {
    try {
      const response = await authAPI.updateAvailability(params);
      const userData = response.data;
      const { id } = userData;
      setUser(userData, getHeaderExpiry(response));
      commit(types.default.SET_CURRENT_USER);
      dispatch('agents/updatePresence', { [id]: params.availability });
    } catch (error) {
      // Ignore error
    }
  },

  setCurrentAccountId({ commit }, accountId) {
    commit(types.default.SET_CURRENT_ACCOUNT_ID, accountId);
  },

  setCurrentUserAvailability({ commit, state: $state }, data) {
    if (data[$state.currentUser.id]) {
      commit(
        types.default.SET_CURRENT_USER_AVAILABILITY,
        data[$state.currentUser.id]
      );
    }
  },
};

// mutations
export const mutations = {
  [types.default.SET_CURRENT_USER_AVAILABILITY](_state, availability) {
    Vue.set(_state.currentUser, 'availability', availability);
  },
  [types.default.CLEAR_USER](_state) {
    _state.currentUser.id = null;
  },
  [types.default.SET_CURRENT_USER](_state) {
    const currentUser = {
      ...authAPI.getAuthData(),
      ...authAPI.getCurrentUser(),
    };

    Vue.set(_state, 'currentUser', currentUser);
  },
  [types.default.SET_CURRENT_USER_UI_SETTINGS](_state, { uiSettings }) {
    Vue.set(_state, 'currentUser', {
      ..._state.currentUser,
      ui_settings: {
        ..._state.currentUser.ui_settings,
        ...uiSettings,
      },
    });
  },
  [types.default.SET_CURRENT_ACCOUNT_ID](_state, accountId) {
    Vue.set(_state, 'currentAccountId', Number(accountId));
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
