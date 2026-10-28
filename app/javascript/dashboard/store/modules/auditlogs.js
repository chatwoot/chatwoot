import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import AuditLogsAPI from '../../api/auditLogs';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const state = {
  records: [],
  meta: {
    currentPage: 1,
    perPage: 25,
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

let activeFetchId = 0;

export const actions = {
  async fetch({ commit }, filters = {}) {
    activeFetchId += 1;
    const fetchId = activeFetchId;
    commit(types.default.SET_AUDIT_LOGS_UI_FLAG, { fetchingList: true });
    try {
      const response = await AuditLogsAPI.get(filters);
      if (fetchId !== activeFetchId) return null;
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
      if (fetchId !== activeFetchId) return null;
      commit(types.default.SET_AUDIT_LOGS, []);
      commit(types.default.SET_AUDIT_LOGS_META, {
        totalEntries: 0,
        perPage: 25,
        currentPage: 1,
      });
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
