/* eslint no-console: 0 */
/* eslint-env browser */
/* eslint no-param-reassign: 0 */
import axios from 'axios';
import moment from 'moment';
import Vue from 'vue';
import * as types from '../mutation-types';
import router from '../../routes';
import authAPI from '../../api/auth';
import createAxios from '../../helper/APIHelper';
import actionCable from '../../helper/actionCable';
// initial state
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
const getters = {
  isLoggedIn(_state) {
    return _state.currentUser.id !== null;
  },

  getCurrentUserID(_state) {
    return _state.currentUser.id;
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
const actions = {
  login({ commit }, credentials) {
    return new Promise((resolve, reject) => {
      authAPI
        .login(credentials)
        .then(() => {
          commit(types.default.SET_CURRENT_USER);
          window.axios = createAxios(axios);
          actionCable.init(Vue);
          router.replace({ name: 'home' });
          resolve();
        })
        .catch(error => {
          reject(error);
        });
    });
  },
  validityCheck(context) {
    if (context.getters.isLoggedIn) {
      authAPI.validityCheck();
    }
  },
  set_user({ commit }) {
    if (authAPI.isLoggedIn()) {
      commit(types.default.SET_CURRENT_USER);
    } else {
      commit(types.default.CLEAR_USER);
    }
  },
  logout({ commit }) {
    commit(types.default.CLEAR_USER);
  },
};

// mutations
const mutations = {
  [types.default.CLEAR_USER](_state) {
    _state.currentUser.id = null;
  },
  [types.default.SET_CURRENT_USER](_state) {
    Object.assign(_state.currentUser, authAPI.getAuthData());
    Object.assign(_state.currentUser, authAPI.getCurrentUser());
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
