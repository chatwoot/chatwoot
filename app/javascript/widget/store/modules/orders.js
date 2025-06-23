import ShopifyOrdersAPI from '../../api/orders';

const state = {
  uiFlags: {
    isUpdating: false,
    isFetching: false,
    noOrders: false,
  },
  orders: [],
};

export const getters = {
  getUiFlags: $state => $state.uiFlags,
  getOrders: $state => $state.orders,
};

export const actions = {
  get: async ({ commit }) => {
    try {
      commit('toggleIsFetchingStatus', true);

      const response = await ShopifyOrdersAPI.get();

      if(response.data.populated && response.data.orders.length === 0) {
        commit('toggleNoOrdersStatus', true);
      }
      commit('toggleIsFetchingStatus', false);
      
      console.log('recieved orders', response.data);

      commit('updateOrders', response.data.orders);
    } catch {
      // do nothing
    }
  },
};

export const mutations = {
  toggleNoOrdersStatus($state, status) {
    $state.uiFlags.noOrders = status;
  },

  toggleIsFetchingStatus($state, status) {
    $state.uiFlags.isFetching = status;
  },

  updateOrders($state, orders) {
    $state.orders = orders;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
