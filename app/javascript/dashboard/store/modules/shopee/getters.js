export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getVouchers($state) {
    return Object.values($state.vouchers);
  },
  getOrders($state) {
    return Object.values($state.orders);
  },
  searchProducts($state) {
    return Object.values($state.products);
  },
};
