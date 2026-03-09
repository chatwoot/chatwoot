import types from '../mutation-types';
import ContactAPI from '../../api/contacts';

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
    commit(types.SET_CONTACT_LABELS_UI_FLAG, {
      isFetching: true,
    });
    try {
      const response = await ContactAPI.getContactLabels(contactId);
      commit(types.SET_CONTACT_LABELS, {
        id: contactId,
        data: response.data.payload,
      });
      commit(types.SET_CONTACT_LABELS_UI_FLAG, {
        isFetching: false,
      });
    } catch (error) {
      commit(types.SET_CONTACT_LABELS_UI_FLAG, {
        isFetching: false,
      });
    }
  },
  update: async ({ commit }, { contactId, labels }) => {
    commit(types.SET_CONTACT_LABELS_UI_FLAG, {
      isUpdating: true,
    });
    try {
      const response = await ContactAPI.updateContactLabels(contactId, labels);
      commit(types.SET_CONTACT_LABELS, {
        id: contactId,
        data: response.data.payload,
      });
      commit(types.SET_CONTACT_LABELS_UI_FLAG, {
        isUpdating: false,
        isError: false,
      });
    } catch (error) {
      commit(types.SET_CONTACT_LABELS_UI_FLAG, {
        isUpdating: false,
        isError: true,
      });
      throw new Error(error);
    }
  },
  setContactLabel({ commit }, { id, data }) {
    commit(types.SET_CONTACT_LABELS, { id, data });
  },
};

export const mutations = {
  [types.SET_CONTACT_LABELS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.SET_CONTACT_LABELS]: ($state, { id, data }) => {
    $state.records = {
      ...$state.records,
      [id]: data,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
