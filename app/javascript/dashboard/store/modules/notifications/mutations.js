import Vue from 'vue';
import types from '../../mutation-types';

export const mutations = {
  [types.SET_NOTIFICATIONS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [types.CLEAR_NOTIFICATIONS]: $state => {
    Vue.set($state, 'records', {});
  },

  [types.SET_NOTIFICATIONS_META]: ($state, data) => {
    const { count, current_page: currentPage } = data;
    Vue.set($state.meta, 'count', count);
    Vue.set($state.meta, 'currentPage', currentPage);
  },

  [types.SET_NOTIFICATIONS]: ($state, data) => {
    data.forEach(contact => {
      Vue.set($state.records, contact.id, {
        ...($state.records[contact.id] || {}),
        ...contact,
      });
    });
  },
};
