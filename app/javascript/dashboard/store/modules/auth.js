/* eslint no-param-reassign: 0 */
import axios from 'axios';
import moment from 'moment';
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
};

// getters
export const getters = {
  isLoggedIn($state) {
    return !!$state.currentUser.id;
  },

  getCurrentUserID(_state) {
    return _state.currentUser.id;
  },

  getCurrentUser(_state) {
    return _state.currentUser;
  },

  getSubscription(_state) {
    return _state.currentUser.subscription === undefined
      ? null
      : _state.currentUser.subscription;
  },

  getTrialLeft(_state) {
    const createdAt =
      _state.currentUser.subscription === undefined
        ? moment()
        : _state.currentUser.subscription.expiry * 1000;
    const daysLeft = moment(createdAt).diff(moment(), 'days');
    return daysLeft < 0 ? 0 : daysLeft;
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
};

// mutations
const mutations = {
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
};

export default {
  state,
  getters,
  actions,
  mutations,
};
