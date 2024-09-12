export const getters = {
  getIntegrationsView($state) {
    return $state.sortOrder.map(integrationId => $state.records[integrationId]);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getOrder: $state => id => {
    const order = $state.records[id];
    return order || {};
  },
  getMeta: $state => {
    return $state.meta;
  },

  getAppliedOrdersFilters: _state => {
    return _state.appliedFilters;
  },

  getContactOrders($state) {
    return $state.sortOrder.map(integrationId => $state.records[integrationId]);
  },

  getAppliedOrdersFilters: _state => {
    return _state.appliedFilters;
  },
};
