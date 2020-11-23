/* eslint no-param-reassign: 0 */
import axios from 'axios';
import Vue from 'vue';
import * as types from '../mutation-types';
import authAPI from '../../api/auth';
import createAxios from '../../helper/APIHelper';
import actionCable from '../../helper/actionCable';
import { setUser, getHeaderExpiry, clearCookiesOnLogout } from '../utils/api';

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

  getCurrentUserAvailabilityStatus(_state) {
    return _state.currentUser.availability_status;
  },

  getCurrentAccountId(_state) {
    return _state.currentAccountId;
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
          window.location = '/';
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
      setUser(response.data.payload.data, getHeaderExpiry(response));
      context.commit(types.default.SET_CURRENT_USER);
    } catch (error) {
      if (error.response.status === 401) {
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
    try {
      const response = await authAPI.profileUpdate(params);
      setUser(response.data, getHeaderExpiry(response));
      commit(types.default.SET_CURRENT_USER);
    } catch (error) {
      // Ignore error
    }
  },

  updateAvailability: ({ commit, dispatch }, { availability }) => {
    authAPI.updateAvailability({ availability }).then(response => {
      const userData = response.data;
      const { id, availability_status: availabilityStatus } = userData;
      setUser(userData, getHeaderExpiry(response));
      commit(types.default.SET_CURRENT_USER);
      dispatch('agents/updatePresence', { [id]: availabilityStatus });
    });
  },

  setCurrentAccountId({ commit }, accountId) {
    commit(types.default.SET_CURRENT_ACCOUNT_ID, accountId);
  },

  setCurrentUserAvailabilityStatus({ commit, state: $state }, data) {
    if (data[$state.currentUser.id]) {
      commit(
        types.default.SET_CURRENT_USER_AVAILABILITY,
        data[$state.currentUser.id]
      );
    }
  },
};

// mutations
const mutations = {
  [types.default.SET_CURRENT_USER_AVAILABILITY](_state, status) {
    Vue.set(_state.currentUser, 'availability_status', status);
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
