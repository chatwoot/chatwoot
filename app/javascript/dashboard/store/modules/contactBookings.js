import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import ContactAPI from '../../api/contacts';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getContactBookings: $state => id => {
    return $state.records[Number(id)] || [];
  },
};

export const actions = {
  get: async ({ commit }, contactId) => {
    commit(types.default.SET_CONTACT_BOOKINGS_UI_FLAG, {
      isFetching: true,
    });

    try {
      if (state.records[Number(contactId)]) {
        commit(types.default.SET_CONTACT_BOOKINGS, {
          id: contactId,
          data: state.records[Number(contactId)],
        });
      } else {
        const response = await ContactAPI.getContactBookings(contactId);
        commit(types.default.SET_CONTACT_BOOKINGS, {
          id: contactId,
          data: response.data,
        });
      }
    } finally {
      commit(types.default.SET_CONTACT_BOOKINGS_UI_FLAG, {
        isFetching: false,
      });
    }
  },
};

export const mutations = {
  [types.default.SET_CONTACT_BOOKINGS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_CONTACT_BOOKINGS]: ($state, { id, data }) => {
    MutationHelpers.set($state.records, id, data);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
