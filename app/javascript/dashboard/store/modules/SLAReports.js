import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import SLAReportsAPI from '../../api/slaReports';

export const state = {
  records: [],
  metrics: {
    numberOfSLABreaches: 0,
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
    { number_of_sla_breaches: numberOfSLABreaches, hit_rate: hitRate }
  ) {
    _state.metrics = {
      numberOfSLABreaches,
      hitRate,
    };
  },
  [types.SET_SLA_REPORTS_META](
    _state,
    { total_applied_slas: totalAppliedSLAs, current_page: currentPage }
  ) {
    _state.meta = {
      count: totalAppliedSLAs,
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
