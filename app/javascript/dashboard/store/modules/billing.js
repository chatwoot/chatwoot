import types from '../mutation-types';
import authAPI from '../../api/auth';
import billingAPI from '../../api/billing';

import { setUser, clearCookiesOnLogout } from '../utils/api';

const initialState = {
  currentUser: {
    id: null,
    account_id: null,
    accounts: [],
    email: null,
    name: null,
  },
  uiFlags: {
    isFetching: true,
  },
  billing: {
    myActiveSubscription: {},
    subscriptionHistories: [],
  },
};

// actions
export const actions = {
  createTopup: async ({ commit }, topupData) => {
    try {
      commit(types.SET_CURRENT_USER_UI_FLAGS, { isFetching: true });
      const response = await billingAPI.createTopup(topupData);
      // (Opsional) commit ke mutation jika mau update state
      // commit(types.ADD_NEW_SUBSCRIPTION, response.data);
      return response.data; // Ensure the action returns the response data
    } catch (error) {
      console.error('Error creating subscription topup:', error);
    } finally {
      commit(types.SET_CURRENT_USER_UI_FLAGS, { isFetching: false });
    }
  },
  createSubscription: async ({ commit }, subscriptionData) => {
    try {
      commit(types.SET_CURRENT_USER_UI_FLAGS, { isFetching: true });
      const response = await billingAPI.createSubscription(subscriptionData);
      // (Opsional) commit ke mutation jika mau update state
      // commit(types.ADD_NEW_SUBSCRIPTION, response.data);
      return response.data; // Ensure the action returns the response data
    } catch (error) {
      console.error('Error creating subscription:', error);
      return error;
    } finally {
      commit(types.SET_CURRENT_USER_UI_FLAGS, { isFetching: false });
    }
  },
  myActiveSubscription: async ({ commit }) => {
    try {
      commit(types.SET_CURRENT_USER_UI_FLAGS, { isFetching: false }); // Set loading
      const response = await billingAPI.myActiveSubscription();
      commit(types.SET_BILLING_MY_ACTIVE_SUBSCRIPTION, response.data);
      return response.data;
    } catch (error) {
      console.error('Error fetching subscription:', error);
    } finally {
      commit(types.SET_CURRENT_USER_UI_FLAGS, { isFetching: false }); // Selesai loading
    }
  },
  subscriptionHistories: async ({ commit }) => {
    try {
      commit(types.SET_CURRENT_USER_UI_FLAGS, { isFetching: false }); // Set loading
      const response = await billingAPI.transactionHistories();
      commit(types.SET_BILLING_SUBSCRIPTION_HISTORIES, response.data);
      return response.data;
    } catch (error) {
      console.error('Error fetching subscription:', error);
    } finally {
      commit(types.SET_CURRENT_USER_UI_FLAGS, { isFetching: false }); // Selesai loading
    }
  },
};

// mutations
export const mutations = {
  [types.SET_CURRENT_USER_UI_FLAGS](_state, { isFetching }) {
    _state.uiFlags = { isFetching };
  },
  [types.SET_BILLING_MY_ACTIVE_SUBSCRIPTION](state, subscriptionData) {
    state.billing.myActiveSubscription = subscriptionData;
  },
  [types.SET_BILLING_SUBSCRIPTION_HISTORIES](state, subscriptionData) {
    state.billing.subscriptionHistories = subscriptionData;
  },
};

export const getters = {
  isSubscriptionActive(state) {
    const userSubsStatus = state?.billing?.myActiveSubscription?.status;
    return userSubsStatus && userSubsStatus === 'active' ? true : false;  
  },
};

export default {
  state: initialState,
  actions,
  mutations,
  getters,
};
