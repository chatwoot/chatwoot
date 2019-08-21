/* eslint no-console: 0 */
/* eslint no-param-reassign: 0 */
/* eslint no-shadow: 0 */
import * as types from '../mutation-types';
import Billing from '../../api/billing';

const state = {
  fetchingStatus: false,
  billingDetails: {},
  status: null,
};

const getters = {
  getBillingDetails(_state) {
    return _state.billingDetails;
  },
  billingFetchStatus(_state) {
    return _state.fetchingStatus;
  },
};

const actions = {
  fetchSubscription({ commit }) {
    commit(types.default.TOGGLE_SUBSCRIPTION_LOADING, true);
    Billing.getSubscription()
      .then(billingDetails => {
        commit(types.default.SET_SUBSCRIPTION, billingDetails.data);
        commit(
          types.default.TOGGLE_SUBSCRIPTION_LOADING,
          false,
          billingDetails.status
        );
      })
      .catch(error => {
        const { response } = error;
        commit(
          types.default.TOGGLE_SUBSCRIPTION_LOADING,
          false,
          response.status
        );
      });
  },
};

const mutations = {
  [types.default.SET_SUBSCRIPTION](_state, billingDetails) {
    _state.billingDetails = billingDetails;
  },
  [types.default.TOGGLE_SUBSCRIPTION_LOADING](_state, flag, apiStatus) {
    _state.fetchingStatus = flag;
    _state.status = apiStatus;
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
