import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  metrics: {
    overview: {},
    agentHistory: [],
    policyPerformance: [],
    agentUtilization: [],
    assignmentDistribution: {},
    assignmentTrends: [],
  },
  filters: {
    startDate: null,
    endDate: null,
    agentIds: [],
    policyIds: [],
    groupBy: 'day',
  },
  uiFlags: {
    isFetching: false,
    isFetchingHistory: false,
    isFetchingPerformance: false,
    isFetchingUtilization: false,
    isFetchingDistribution: false,
    isExporting: false,
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
