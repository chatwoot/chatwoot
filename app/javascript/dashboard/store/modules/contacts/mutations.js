import Vue from 'vue';
import * as types from '../../mutation-types';

export const mutations = {
  [types.default.SET_CONTACT_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [types.default.CLEAR_CONTACTS]: $state => {
    $state.records = {};
  },

  [types.default.SET_CONTACTS]: ($state, data) => {
    data.forEach(contact => {
      Vue.set($state.records, contact.id, {
        ...($state.records[contact.id] || {}),
        ...contact,
      });
    });
  },

  [types.default.SET_CONTACT_ITEM]: ($state, data) => {
    Vue.set($state.records, data.id, {
      ...($state.records[data.id] || {}),
      ...data,
    });
  },

  [types.default.EDIT_CONTACT]: ($state, data) => {
    Vue.set($state.records, data.id, data);
  },

  [types.default.UPDATE_CONTACTS_PRESENCE]: ($state, data) => {
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
};
