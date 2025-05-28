import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import SLAReportsAPI from '../../api/slaReports';
import { downloadCsvFile } from 'dashboard/helper/downloadHelper';
export const state = {
  records: [],
  metrics: {
    numberOfConversations: 0,
    numberOfSLAMisses: 0,
    hitRate: '0%',
  },
  uiFlags: {
    isFetching: false,
    isFetchingMetrics: false,
  },
  meta: {
    count: 0,
    currentPage: 1,
  },
};

export const getters = {
  getAll(_state) {
    return _state.records;
  },
  getMeta(_state) {
    return _state.meta;
  },
  getMetrics(_state) {
    return _state.metrics;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  get: async function getResponses({ commit }, params) {
    commit(types.SET_SLA_REPORTS_UI_FLAG, { isFetching: true });
    try {
      const response = await SLAReportsAPI.get(params);
      const { payload, meta } = response.data;

      commit(types.SET_SLA_REPORTS, payload);
      commit(types.SET_SLA_REPORTS_META, meta);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_SLA_REPORTS_UI_FLAG, { isFetching: false });
    }
  },
  getMetrics: async function getMetrics({ commit }, params) {
    commit(types.SET_SLA_REPORTS_UI_FLAG, { isFetchingMetrics: true });
    try {
      const response = await SLAReportsAPI.getMetrics(params);
      commit(types.SET_SLA_REPORTS_METRICS, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_SLA_REPORTS_UI_FLAG, { isFetchingMetrics: false });
    }
  },
  download(_, params) {
    return SLAReportsAPI.download(params).then(response => {
      downloadCsvFile(params.fileName, response.data);
    });
  },
};

export const mutations = {
  [types.SET_SLA_REPORTS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_SLA_REPORTS]: MutationHelpers.set,
  [types.SET_SLA_REPORTS_METRICS](
    _state,
    {
      number_of_sla_misses: numberOfSLAMisses,
      hit_rate: hitRate,
      total_applied_slas: numberOfConversations,
    }
  ) {
    _state.metrics = {
      numberOfSLAMisses,
      hitRate,
      numberOfConversations,
    };
  },
  [types.SET_SLA_REPORTS_META](_state, { count, current_page: currentPage }) {
    _state.meta = {
      count,
      currentPage,
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
