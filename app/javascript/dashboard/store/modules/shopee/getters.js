export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getVouchers($state) {
    return Object.values($state.records).sort((a, b) => a.id - b.id);
  },
  getOrders($state) {
    return Object.values($state.records).sort((a, b) => a.id - b.id);
  },
  searchProducts($state) {
    return Object.values($state.records).sort((a, b) => a.id - b.id);
  },
};
