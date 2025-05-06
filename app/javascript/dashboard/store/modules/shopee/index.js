import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  meta: {},
  records: {},
  uiFlags: {
    isFetchingOrders: false,
    isFetchingVouchers: false,
    isSearchingProducts: false,
    isSendingOrderMessage: false,
    isSendingVoucherMessage: false,
    isSendingProductMessage: false,
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
