import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import AuditLogsAPI from '../../api/auditLogs';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const state = {
  records: [],
  uiFlags: {
    fetchingList: false,
  },
};

const getters = {
  getAuditLogs(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

const actions = {
  getAuditLog: async function getAuditLog({ commit }, { page } = {}) {
    commit(types.default.SET_AUDIT_LOGS_UI_FLAG, { fetchingList: true });
    try {
      const response = await AuditLogsAPI.get({ page });
      commit(types.default.SET_AUDIT_LOGS, response.data);
      commit(types.default.SET_AUDIT_LOGS_UI_FLAG, { fetchingList: false });
      return response.data;
    } catch (error) {
      commit(types.default.SET_AUDIT_LOGS_UI_FLAG, { fetchingList: false });
      return throwErrorMessage(error);
    }
  },
};

const mutations = {
  [types.default.SET_AUDIT_LOGS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.default.SET_AUDIT_LOGS]: MutationHelpers.set,
};

export default {
  state,
  getters,
  actions,
  mutations,
};
