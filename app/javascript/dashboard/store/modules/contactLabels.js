import Vue from 'vue';
import * as types from '../mutation-types';
import ContactLabelsAPI from '../../api/labels';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isUpdating: false,
    isError: false,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getContactLabels: $state => id => {
    return $state.records[Number(id)] || [];
  },
};

export const actions = {
  get: async ({ commit }, contactId) => {
    commit(types.default.SET_CONTACT_LABELS_UI_FLAG, {
      isFetching: true,
    });
    try {
      const response = await ContactLabelsAPI.getLabels(contactId);
      commit(types.default.SET_CONTACT_LABELS, {
        id: contactId,
        data: response.data.payload,
      });
      commit(types.default.SET_CONTACT_LABELS_UI_FLAG, {
        isFetching: false,
      });
    } catch (error) {
      commit(types.default.SET_CONTACT_LABELS_UI_FLAG, {
        isFetching: false,
      });
    }
  },
  update: async ({ commit }, { contactId, labels }) => {
    commit(types.default.SET_CONTACT_LABELS_UI_FLAG, {
      isUpdating: true,
    });
    try {
      const response = await ContactLabelsAPI.updateLabels(contactId, labels);
      commit(types.default.SET_CONTACT_LABELS, {
        id: contactId,
        data: response.data.payload,
      });
      commit(types.default.SET_CONTACT_LABELS_UI_FLAG, {
        isUpdating: false,
        isError: false,
      });
    } catch (error) {
      commit(types.default.SET_CONTACT_LABELS_UI_FLAG, {
        isUpdating: false,
        isError: true,
      });
    }
  },

  setContactLabel({ commit }, { id, data }) {
    commit(types.default.SET_CONTACT_LABELS, { id, data });
  },
};

export const mutations = {
  [types.default.SET_CONTACT_LABELS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_CONTACT_LABELS]: ($state, { id, data }) => {
    Vue.set($state.records, id, data);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
