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
    myActiveSubscription: [],
  },
};

// actions
export const actions = {
  myActiveSubscription: async ({ commit }) => {
    try {
      console.log('Mengirim request ke API...');
      commit(types.SET_CURRENT_USER_UI_FLAGS, { isFetching: false }); // Set loading
      const response = await billingAPI.myActiveSubscription();
      console.log('Response API:', response);
      commit(types.SET_BILLING_MY_ACTIVE_SUBSCRIPTION, response.data);
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
};

export default {
  state: initialState,
  actions,
  mutations,
};
