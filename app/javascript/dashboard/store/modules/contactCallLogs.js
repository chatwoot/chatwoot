import Vue from 'vue';
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
  getContactCallLogs: $state => phoneNumber => {
    return phoneNumber && $state.records[phoneNumber]
      ? $state.records[phoneNumber]
      : [];
  },
};

export const actions = {
  get: async ({ commit }, phoneNumber) => {
    commit(types.default.SET_CONTACT_CALL_LOGS_UI_FLAG, {
      isFetching: true,
    });
    try {
      const response = await ContactAPI.getCallLogs(phoneNumber);
      commit(types.default.SET_CONTACT_CALL_LOGS, {
        phoneNumber: phoneNumber,
        data: response.data.callLogs,
      });
      commit(types.default.SET_CONTACT_CALL_LOGS_UI_FLAG, {
        isFetching: false,
      });
    } catch (error) {
      commit(types.default.SET_CONTACT_CALL_LOGS_UI_FLAG, {
        isFetching: false,
      });
    }
  },
};

export const mutations = {
  [types.default.SET_CONTACT_CALL_LOGS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_CONTACT_CALL_LOGS]: ($state, { phoneNumber, data }) => {
    Vue.set($state.records, phoneNumber, data);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
