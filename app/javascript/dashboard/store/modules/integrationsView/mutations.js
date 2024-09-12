import Vue from 'vue';
import types from '../../mutation-types';

export const mutations = {
  [types.SET_INTEGRATIONS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [types.CLEAR_INTEGRATIONS]: $state => {
    Vue.set($state, 'records', {});
    Vue.set($state, 'sortOrder', []);
  },

  [types.SET_INTEGRATION_ORDER_ITEM]: ($state, data) => {
    Vue.set($state.records, data.id, {
      ...($state.records[data.id] || {}),
      ...data,
    });

    if (!$state.sortOrder.includes(data.id)) {
      $state.sortOrder.push(data.id);
    }
  },

  [types.SET_CONTACT_ORDERS]: ($state, data) => {
    const sortOrder = data.map(order => {
      Vue.set($state.records, order.id, {
        ...($state.records[order.id] || {}),
        ...order,
      });
      return order.id;
    });
    $state.sortOrder = sortOrder;
  },

  [types.SET_INTEGRATIONS_META]: ($state, data) => {
    const { count, current_page: currentPage } = data;
    Vue.set($state.meta, 'count', count);
    Vue.set($state.meta, 'currentPage', currentPage || 1);
  },

  [types.SET_INTEGRATIONS]: ($state, data) => {
    const sortOrder = data.map(order => {
      Vue.set($state.records, order.id, {
        ...($state.records[order.id] || {}),
        ...order,
      });
      return order.id;
    });
    $state.sortOrder = sortOrder;
  },

  [types.SET_ORDERS_FILTERS](_state, data) {
    _state.appliedFilters = data;
  },

  [types.CLEAR_ORDERS_FILTERS](_state) {
    _state.appliedFilters = [];
  },
};
