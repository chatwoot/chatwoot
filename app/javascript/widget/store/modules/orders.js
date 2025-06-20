import ShopifyOrdersAPI from '../../api/orders';

const state = {
  uiFlags: {
    isUpdating: false,
  },
  orders: [],
};

export const getters = {
  getUIFlags: $state => $state.uiFlags,
  getOrders: $state => $state.orders,
};

export const actions = {
  get: async ({ commit }) => {
    try {
      const response = await ShopifyOrdersAPI.get();
      console.log('recieved orders', response.data);
      commit('updateOrders', response.data.orders);
    } catch {
      // do nothing
    }
  },
};

export const mutations = {
  toggleUpdateStatus($state, status) {
    $state.uiFlags.isUpdating = status;
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
