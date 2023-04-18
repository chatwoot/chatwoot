import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import AuditLogsAPI from '../../api/auditLogs';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const state = {
  records: [],
  meta: {
    currentPage: 1,
    perPage: 15,
    totalEntries: 0,
  },
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
  getMeta(_state) {
    return _state.meta;
  },
};

const actions = {
  async fetch({ commit }, { page } = {}) {
    commit(types.default.SET_AUDIT_LOGS_UI_FLAG, { fetchingList: true });
    try {
      const response = await AuditLogsAPI.get({ page });
      const { audit_logs: logs = [] } = response.data;
      const {
        total_entries: totalEntries,
        per_page: perPage,
        current_page: currentPage,
      } = response.data;
      commit(types.default.SET_AUDIT_LOGS, logs);
      commit(types.default.SET_AUDIT_LOGS_META, {
        totalEntries,
        perPage,
        currentPage,
      });
      commit(types.default.SET_AUDIT_LOGS_UI_FLAG, { fetchingList: false });
      return logs;
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
  [types.default.SET_AUDIT_LOGS_META](_state, data) {
    _state.meta = {
      ..._state.meta,
      ...data,
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
