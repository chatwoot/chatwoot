import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import DashassistShopifyAPI from '../../api/dashassistShopify';
import { throwErrorMessage } from '../utils/api';

console.log('Dashassist Shopify Store: Module is being loaded');

const state = {
  store: null,
  uiFlags: {
    isFetching: false,
    isUpdating: false,
  },
};

const getters = {
  getStore: state => state.store,
  getUIFlags: state => state.uiFlags,
};

const actions = {
  async getStoreByInboxId({ commit }, inboxId) {
    console.log('Dashassist Shopify Store: getStoreByInboxId action called with inboxId:', inboxId);
    commit(types.SET_UI_FLAG, { isFetching: true });
    try {
      console.log('Dashassist Shopify Store: Calling API getStoreByInboxId...');
      const response = await DashassistShopifyAPI.getStoreByInboxId(inboxId);
      console.log('API Response:', response);
      const store = response.data;
      console.log('Store data:', store);
      commit('SET_STORE', store);
      return store;
    } catch (error) {
      console.error('Dashassist Shopify Store: Error in getStoreByInboxId action:', error);
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isFetching: false });
    }
  },

  async toggleChatBot({ commit }, { storeId, enabled }) {
    commit(types.SET_UI_FLAG, { isUpdating: true });
    try {
      const response = await DashassistShopifyAPI.toggleChatBot(storeId, enabled);
      const store = response.data;
      commit('SET_STORE', store);
      return store;
    } catch (error) {
      return throwErrorMessage(error);
    } finally {
      commit(types.SET_UI_FLAG, { isUpdating: false });
    }
  },

  testAction({ commit }, payload) {
    console.log('Dashassist Shopify Store: testAction called with payload:', payload);
    // Optionally, commit a mutation to see if state changes too
    // commit(types.SET_UI_FLAG, { testFlag: true });
  },
};

const mutations = {
  SET_STORE(state, store) {
    state.store = store;
  },
  [types.SET_UI_FLAG](state, data) {
    state.uiFlags = { ...state.uiFlags, ...data };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
}; 