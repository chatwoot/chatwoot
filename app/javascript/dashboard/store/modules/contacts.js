/* eslint no-param-reassign: 0 */
import * as types from '../mutation-types';
import ContactAPI from '../../api/contacts';
import Vue from 'vue';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isUpdating: false,
  },
};

export const getters = {
  getContacts($state) {
    return Object.values($state.records);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getContact: $state => id => {
    const contact = $state.records[id];
    return contact || {};
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.default.SET_CONTACT_UI_FLAG, { isFetching: true });
    try {
      const response = await ContactAPI.get();
      commit(types.default.SET_CONTACTS, response.data.payload);
      commit(types.default.SET_CONTACT_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.default.SET_CONTACT_UI_FLAG, { isFetching: false });
    }
  },

  show: async ({ commit }, { id }) => {
    commit(types.default.SET_CONTACT_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await ContactAPI.show(id);
      commit(types.default.SET_CONTACT_ITEM, response.data.payload);
      commit(types.default.SET_CONTACT_UI_FLAG, { isFetchingItem: false });
    } catch (error) {
      commit(types.default.SET_CONTACT_UI_FLAG, { isFetchingItem: false });
    }
  },

  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.default.SET_CONTACT_UI_FLAG, { isUpdating: true });
    try {
      const response = await ContactAPI.update(id, updateObj);
      commit(types.default.EDIT_CONTACT, response.data.payload);
      commit(types.default.SET_CONTACT_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.default.SET_CONTACT_UI_FLAG, { isUpdating: false });
      throw new Error(error);
    }
  },

  updatePresence: ({ commit }, data) => {
    commit(types.default.UPDATE_CONTACTS_PRESENCE, data);
  },

  setContact({ commit }, data) {
    commit(types.default.SET_CONTACT_ITEM, data);
  },
};

export const mutations = {
  [types.default.SET_CONTACT_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
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

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
