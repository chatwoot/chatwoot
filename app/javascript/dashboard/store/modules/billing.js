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
  createSubscription: async ({ commit }, subscriptionData) => {
    try {
      commit(types.SET_CURRENT_USER_UI_FLAGS, { isFetching: true });
      const response = await billingAPI.createSubscription(subscriptionData);
      console.log('Subscription created:', response.data);
      // (Opsional) commit ke mutation jika mau update state
      // commit(types.ADD_NEW_SUBSCRIPTION, response.data);
      return response.data; // Ensure the action returns the response data
    } catch (error) {
      console.error('Error creating subscription:', error);
    } finally {
      commit(types.SET_CURRENT_USER_UI_FLAGS, { isFetching: false });
    }
  },
  myActiveSubscription: async ({ commit }) => {
    try {
      console.log('Mengirim request ke API...');
      commit(types.SET_CURRENT_USER_UI_FLAGS, { isFetching: false }); // Set loading
      const response = await billingAPI.myActiveSubscription();
      console.log('Response API:', response);
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
      console.log('Mengirim request ke API...');
      commit(types.SET_CURRENT_USER_UI_FLAGS, { isFetching: false }); // Set loading
      const response = await billingAPI.subscriptionHistories();
      console.log('Response API:', response);
      commit(types.SET_BILLING_SUBSCRIPTION_HISTORIES, response.data);
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

export default {
  state: initialState,
  actions,
  mutations,
};
