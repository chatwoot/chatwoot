import Vue from 'vue';
import types from '../../mutation-types';

export const mutations = {
  [types.SET_CONTACT_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [types.CLEAR_CONTACTS]: $state => {
    Vue.set($state, 'records', {});
    Vue.set($state, 'sortOrder', []);
  },

  [types.SET_CONTACT_META]: ($state, data) => {
    const { count, current_page: currentPage } = data;
    Vue.set($state.meta, 'count', count);
    Vue.set($state.meta, 'currentPage', currentPage);
  },

  [types.SET_CONTACTS]: ($state, data) => {
    const sortOrder = data.map(contact => {
      Vue.set($state.records, contact.id, {
        ...($state.records[contact.id] || {}),
        ...contact,
      });
      return contact.id;
    });
    $state.sortOrder = sortOrder;
  },

  [types.SET_CONTACT_ITEM]: ($state, data) => {
    Vue.set($state.records, data.id, {
      ...($state.records[data.id] || {}),
      ...data,
    });

    if (!$state.sortOrder.includes(data.id)) {
      $state.sortOrder.push(data.id);
    }
  },

  [types.EDIT_CONTACT]: ($state, data) => {
    Vue.set($state.records, data.id, data);
  },

  [types.DELETE_CONTACT]: ($state, id) => {
    const index = $state.sortOrder.findIndex(item => item === id);
    Vue.delete($state.sortOrder, index);
    Vue.delete($state.records, id);
  },

  [types.UPDATE_CONTACTS_PRESENCE]: ($state, data) => {
    Object.values($state.records).forEach(element => {
      const availabilityStatus = data[element.id];
      if (availabilityStatus) {
        Vue.set(
          $state.records[element.id],
          'availability_status',
          availabilityStatus
        );
      } else {
        Vue.delete($state.records[element.id], 'availability_status');
      }
    });
  },

  [types.SET_CONTACT_FILTERS](_state, data) {
    _state.appliedFilters = data;
  },

  [types.CLEAR_CONTACT_FILTERS](_state) {
    _state.appliedFilters = [];
  },
};
